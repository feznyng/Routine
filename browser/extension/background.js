// Native messaging host name
const hostName = "com.solidsoft.routine";
let port = null;
let isAppConnected = false;  // Track Flutter app connection state
let reconnectTimer = null;
const RECONNECT_INTERVAL = 5000; // Attempt reconnection every 2 seconds to match onboarding dialog behavior

// block config
let sites = [];
let allowList = false;

// Lock mechanism for rule updates
let isUpdatingRules = false;
let pendingRuleUpdate = false;

function getBrowserType() {
  if (typeof browser !== 'undefined') return 'firefox';
  const userAgent = navigator.userAgent.toLowerCase();
  if (userAgent.includes('edg/')) return 'edge';
  if (userAgent.includes('opr/')) return 'opera';
  if (userAgent.includes('brave')) return 'brave';
  if (userAgent.includes('safari') && !userAgent.includes('chrome')) return 'safari';
  if (userAgent.includes('chrome')) return 'chrome';
  return 'unknown';
}

// Connect to native messaging host
async function connectToNative() {
  try {
    // Get browser type for logging
    const browserType = getBrowserType();
    console.log(`Detected browser type: ${browserType}`);
    
    // Send browser type as first message after connecting
    port = chrome.runtime.connectNative(hostName);
    port.postMessage({ action: 'browser_info', data: { browser: browserType } });
    console.log(`Connected to native messaging host for ${browserType}`);

    port.onMessage.addListener((message) => {
      console.log("Received message from native host:", message);
      
      if (message.action === "updateBlockedSites" && Array.isArray(message.data.sites)) {
        isAppConnected = true;
        // Update blocked sites list
        sites = message.data.sites;
        allowList = message.data.allowList;
        
        // Re-register blocking rules with new patterns
        registerBlockingRules();
        
        // Check and redirect any currently open tabs that are now blocked
        checkAndRedirectBlockedTabs();
        
        console.log("Updated blocked sites:", sites, allowList);
      }
    });
    
    port.onDisconnect.addListener(() => {
      const error = chrome.runtime.lastError;
      console.log("Disconnected from native host", error ? error.message : "", hostName);
      port = null;
      isAppConnected = false;  // Reset app connection state
      registerBlockingRules();  // Re-register rules with new connection state
      
      // Start reconnection attempts
      scheduleReconnect();
    });

    // Clear reconnection timer on successful connection
    if (reconnectTimer) {
      clearTimeout(reconnectTimer);
      reconnectTimer = null;
    }
  } catch (error) {
    console.log("Failed to connect to native host:", error);
    scheduleReconnect();
  }
}

// Schedule reconnection at fixed interval
function scheduleReconnect() {
  if (reconnectTimer) {
    return; // Already trying to reconnect
  }

  console.log(`Scheduling reconnection attempt in ${RECONNECT_INTERVAL}ms`);
  reconnectTimer = setTimeout(() => {
    reconnectTimer = null;
    connectToNative();
  }, RECONNECT_INTERVAL);
}

// Register blocking rules using declarativeNetRequest
async function registerBlockingRules() {
  // If already updating rules, schedule a follow-up update
  if (isUpdatingRules) {
    console.log('Rule update already in progress, scheduling follow-up update');
    pendingRuleUpdate = true;
    return;
  }

  isUpdatingRules = true;

  try {
    // Remove all existing dynamic rules first
    await chrome.declarativeNetRequest.updateDynamicRules({
      removeRuleIds: await chrome.declarativeNetRequest.getDynamicRules().then(rules => rules.map(r => r.id))
    });

    // If app is not connected, don't apply any blocking rules
    if (!isAppConnected) {
      console.log('App not connected, clearing all blocking rules');
      return;
    }
    
    const rules = [];
    let ruleId = 1;

    if (allowList) {
      // Allowlist mode: Block everything except specified sites
      
      // First add rules for allowed sites (priority 1)
      for (const site of sites) {
        rules.push({
          id: ruleId++,
          priority: 1,
          action: { type: 'allow' },
          condition: {
            urlFilter: `||${site}`,
            resourceTypes: ['main_frame', 'sub_frame', 'stylesheet', 'script', 'image', 'font', 'object', 'xmlhttprequest', 'ping', 'media', 'websocket', 'other']
          }
        });
      }

      // Then add catch-all redirect rule with lower priority (0)
      rules.push({
        id: ruleId++,
        priority: 0,
        action: { 
          type: 'redirect',
          redirect: { url: 'https://www.routineblocker.com/blocked.html' }
        },
        condition: {
          urlFilter: '*',
          resourceTypes: ['main_frame']
        }
      });
    } else {
      // Blocklist mode: Only block specified sites
      for (const site of sites) {
        rules.push({
          id: ruleId++,
          priority: 1,
          action: { 
            type: 'redirect',
            redirect: { url: 'https://www.routineblocker.com/blocked.html' }
          },
          condition: {
            urlFilter: `||${site}`,
            resourceTypes: ['main_frame']
          }
        });
      }
    }

    // Update the dynamic rules
    await chrome.declarativeNetRequest.updateDynamicRules({
      addRules: rules
    });

    console.log(`Updated blocking rules: ${rules.length} rules added, mode: ${allowList ? 'allowlist' : 'blocklist'}`);
  } catch (error) {
    console.error('Error updating blocking rules:', error);
  } finally {
    isUpdatingRules = false;

    // If there's a pending update, process it
    if (pendingRuleUpdate) {
      pendingRuleUpdate = false;
      console.log('Processing pending rule update');
      // Use setTimeout to prevent stack overflow with recursive async calls
      setTimeout(() => registerBlockingRules(), 0);
    }
  }
}

chrome.runtime.onInstalled.addListener(() => {
  console.log("Extension installed");
  connectToNative();
});

chrome.runtime.onStartup.addListener(() => {
  console.log("Extension starting up");
  connectToNative();
});

chrome.alarms.create("keepAlive", { periodInMinutes: 1 });

chrome.alarms.onAlarm.addListener((alarm) => {
  if (alarm.name === "keepAlive") {
    if (!port) {
      console.log("Keep-alive alarm triggered reconnection");
      connectToNative();
    }
  }
});

// Function to check if a URL should be blocked
function shouldBlockUrl(url) {
  if (!isAppConnected || sites.length === 0) {
    return false;
  }
  
  try {
    const urlObj = new URL(url);
    const hostname = urlObj.hostname;
    
    if (allowList) {
      // Allowlist mode: block if not in the allowed sites
      return !sites.some(site => hostname === site || hostname.endsWith('.' + site));
    } else {
      // Blocklist mode: block if in the blocked sites
      return sites.some(site => hostname === site || hostname.endsWith('.' + site));
    }
  } catch (error) {
    console.error('Error parsing URL:', url, error);
    return false;
  }
}

// Function to check and redirect currently open tabs that are now blocked
async function checkAndRedirectBlockedTabs() {
  if (!isAppConnected) {
    return;
  }
  
  try {
    const tabs = await chrome.tabs.query({});
    
    for (const tab of tabs) {
      // Skip special pages (chrome://, moz-extension://, etc.)
      if (!tab.url || tab.url.startsWith('chrome://') || tab.url.startsWith('moz-extension://') || 
          tab.url.startsWith('chrome-extension://') || tab.url.startsWith('about:') ||
          tab.url.includes('routineblocker.com/blocked.html')) {
        continue;
      }
      
      if (shouldBlockUrl(tab.url)) {
        console.log(`Redirecting tab ${tab.id} from blocked URL: ${tab.url}`);
        try {
          await chrome.tabs.update(tab.id, {
            url: 'https://www.routineblocker.com/blocked.html'
          });
        } catch (error) {
          console.error(`Failed to redirect tab ${tab.id}:`, error);
        }
      }
    }
  } catch (error) {
    console.error('Error checking blocked tabs:', error);
  }
}

// Listen for tab updates to block navigation to blocked sites
chrome.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
  // Only check when the URL changes and is loading
  if (changeInfo.status === 'loading' && changeInfo.url && shouldBlockUrl(changeInfo.url)) {
    console.log(`Blocking navigation to: ${changeInfo.url}`);
    chrome.tabs.update(tabId, {
      url: 'https://www.routineblocker.com/blocked.html'
    }).catch(error => {
      console.error(`Failed to block navigation in tab ${tabId}:`, error);
    });
  }
});

connectToNative();

registerBlockingRules();