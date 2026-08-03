// Native messaging host name
const hostName = "com.solidsoft.routine";

// Debug instrumentation. The worker is torn down and restarted constantly, so
// every line carries a wall-clock time and the worker's own age - that is the
// only way to tell one worker's lifetime from the next in the console.
const WORKER_STARTED_AT = Date.now();
function log(...args) {
  const age = ((Date.now() - WORKER_STARTED_AT) / 1000).toFixed(1);
  console.log(`[${new Date().toISOString()}] (+${age}s)`, ...args);
}
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

// Identify the host browser. This name is what the app keys its connection map
// on, so getting it wrong makes two browsers collide on one slot and silently
// starves whichever connected first.
//
// Do NOT sniff `typeof browser` - Chrome defines that global too, so it
// reported every Chrome install as Firefox.
async function getBrowserType() {
  const ua = navigator.userAgent.toLowerCase();
  log(`DETECT userAgent=${navigator.userAgent}`);

  if (ua.includes('firefox')) return 'firefox';
  if (ua.includes('edg/')) return 'edge';
  if (ua.includes('opr/')) return 'opera';

  // Brave's user agent is deliberately identical to Chrome's - the only
  // reliable signal is the navigator.brave probe it injects.
  try {
    if (navigator.brave && await navigator.brave.isBrave()) return 'brave';
  } catch (e) {
    log('DETECT brave probe failed:', e && e.message ? e.message : e);
  }

  if (ua.includes('safari') && !ua.includes('chrome')) return 'safari';
  if (ua.includes('chrome')) return 'chrome';
  return 'unknown';
}

// Connect to native messaging host
async function connectToNative() {
  try {
    // Get browser type for logging
    const browserType = await getBrowserType();
    log(`DETECT browser type: ${browserType}`);
    
    // Send browser type as first message after connecting
    port = chrome.runtime.connectNative(hostName);
    port.postMessage({ action: 'browser_info', data: { browser: browserType } });
    log(`CONN connectNative(${hostName}) issued, reported browser=${browserType}`);

    port.onMessage.addListener((message) => {
      log("MSG received from native host:", JSON.stringify(message));

      if (message.action === "updateBlockedSites" && Array.isArray(message.data.sites)) {
        isAppConnected = true;
        // Update blocked sites list
        sites = message.data.sites;
        allowList = message.data.allowList;
        
        // Re-register blocking rules with new patterns
        registerBlockingRules();
        
        // Check and redirect any currently open tabs that are now blocked
        checkAndRedirectBlockedTabs();
        
        log("MSG applied updateBlockedSites:", JSON.stringify(sites), "allowList=", allowList);
      }
    });

    port.onDisconnect.addListener(() => {
      const error = chrome.runtime.lastError;
      log("CONN disconnected from native host:", error ? error.message : "(no error)");
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
    log("CONN connectNative threw:", error && error.message ? error.message : error);
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

// Check if a URL matches any blocked sites
function isUrlBlocked(url) {
  try {
    const urlObj = new URL(url);
    const hostname = urlObj.hostname;
    
    if (allowList) {
      // In allowlist mode, site is blocked if it's not in the sites list
      return !sites.some(site => hostname.endsWith(site));
    } else {
      // In blocklist mode, site is blocked if it's in the sites list
      return sites.some(site => hostname.endsWith(site));
    }
  } catch (e) {
    console.error('Error parsing URL:', e);
    return false;
  }
}

// Check all open tabs and redirect blocked ones
async function checkOpenTabs() {
  if (!isAppConnected) return;
  
  try {
    const tabs = await chrome.tabs.query({ url: ['http://*/*', 'https://*/*'] });
    for (const tab of tabs) {
      if (isUrlBlocked(tab.url)) {
        console.log(`Redirecting already-open blocked tab: ${tab.url}`);
        chrome.tabs.update(tab.id, {
          url: 'https://www.routineblocker.com/blocked.html'
        });
      }
    }
  } catch (error) {
    console.error('Error checking open tabs:', error);
  }
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
      log('RULES cleared - app not connected (isAppConnected=false)');
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

    log(`RULES applied: ${rules.length} rules, mode=${allowList ? 'allowlist' : 'blocklist'}, sites=${JSON.stringify(sites)}`);
    
    // After updating rules, check all open tabs
    await checkOpenTabs();
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
  log("LIFECYCLE onInstalled");
  connectToNative();
});

chrome.runtime.onStartup.addListener(() => {
  log("LIFECYCLE onStartup");
  connectToNative();
});

chrome.alarms.create("keepAlive", { periodInMinutes: 1 });

chrome.alarms.onAlarm.addListener((alarm) => {
  if (alarm.name === "keepAlive") {
    log(`ALARM keepAlive fired, port=${port ? 'open' : 'null'}, isAppConnected=${isAppConnected}`);
    if (!port) {
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

// Top-level: runs on every worker start, including every wake from idle.
log("LIFECYCLE worker started");
chrome.declarativeNetRequest.getDynamicRules().then((r) => {
  log(`LIFECYCLE rules present at worker start: ${r.length}`);
});

connectToNative();

registerBlockingRules();