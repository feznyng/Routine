// Native messaging host name
const hostName = "com.solidsoft.routine";
let port = null;
let isAppConnected = false;  // Track Flutter app connection state
let reconnectTimer = null;
const RECONNECT_INTERVAL = 2000; // Attempt reconnection every 2 seconds to match onboarding dialog behavior

// List of blocked sites
let blockedSites = [];
let allowList = false;

// Rule IDs for declarativeNetRequest
const BLOCK_RULE_ID = 1;
const ALLOW_RULE_ID = 2;

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
        // Update blocked sites list
        blockedSites = message.data.sites;
        allowList = message.data.allowList;
        
        // Re-register blocking rules with new patterns
        registerBlockingRules();
        
        console.log("Updated blocked sites:", blockedSites, allowList);
      } else if (message.action === "appConnectionState") {
        // Update app connection state
        isAppConnected = message.data.connected;
        console.log("App connection state changed:", isAppConnected ? "connected" : "disconnected", 
                   "active connections:", message.data.connections);
        
        // Re-register blocking rules with new connection state
        registerBlockingRules();
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

// Check if hostname matches any domain in the list (including subdomains)
function matchesDomain(hostname, domainList) {
  return domainList.some(domain => {
    // Exact match
    if (hostname === domain) return true;
    // Subdomain match (ensure it ends with .domain)
    return hostname.endsWith('.' + domain);
  });
}

// Create domain condition patterns for declarativeNetRequest
function createDomainConditions(domains) {
  return domains.map(domain => {
    // Handle both exact domains and subdomains
    return {
      urlFilter: `*://*.${domain}/*`,
      resourceTypes: [
        "main_frame",
        "sub_frame",
        "xmlhttprequest",
        "websocket"
      ]
    };
  });
}

// Register blocking rules using declarativeNetRequest
async function registerBlockingRules() {
  // First remove all existing rules
  await chrome.declarativeNetRequest.updateDynamicRules({
    removeRuleIds: [BLOCK_RULE_ID, ALLOW_RULE_ID]
  });
  
  // Only register blocking if app is connected and have sites to block
  if (!isAppConnected) {
    console.log("App not connected, blocking disabled");
    return;
  }
  
  if (allowList && blockedSites.length > 0) {
    // In allowList mode, block all sites except those in the list and routineblocker.com
    console.log(`Registering allowList mode with allowed sites:`, blockedSites);
    
    // Rule 1: Block all sites
    const blockAllRule = {
      id: BLOCK_RULE_ID,
      priority: 1,
      action: {
        type: "redirect",
        redirect: { url: "https://www.routineblocker.com/blocked.html" }
      },
      condition: {
        urlFilter: "*://*/*",
        resourceTypes: [
          "main_frame",
          "sub_frame",
          "xmlhttprequest",
          "websocket"
        ]
      }
    };
    
    // Rule 2: Allow specific sites (higher priority)
    const allowedConditions = createDomainConditions(blockedSites);
    // Add routineblocker.com to allowed sites
    allowedConditions.push({
      urlFilter: "*://*.routineblocker.com/*",
      resourceTypes: [
        "main_frame",
        "sub_frame",
        "xmlhttprequest",
        "websocket"
      ]
    });
    
    const allowRule = {
      id: ALLOW_RULE_ID,
      priority: 2, // Higher priority than block rule
      action: { type: "allow" },
      condition: { 
        urlFilter: "*://*/*",
        resourceTypes: [
          "main_frame",
          "sub_frame",
          "xmlhttprequest",
          "websocket"
        ],
        // In MV3, we need to use requestDomains instead of urlFilter for complex patterns
        requestDomains: [...blockedSites, "routineblocker.com"]
      }
    };
    
    await chrome.declarativeNetRequest.updateDynamicRules({
      addRules: [blockAllRule, allowRule]
    });
  } else if (!allowList && blockedSites.length > 0) {
    // In blockgroup mode, block only sites in the list
    console.log(`Registering blockgroup mode with blocked sites:`, blockedSites);
    
    const blockRule = {
      id: BLOCK_RULE_ID,
      priority: 1,
      action: {
        type: "redirect",
        redirect: { url: "https://www.routineblocker.com/blocked.html" }
      },
      condition: {
        urlFilter: "*://*/*",
        resourceTypes: [
          "main_frame",
          "sub_frame",
          "xmlhttprequest",
          "websocket"
        ],
        requestDomains: blockedSites
      }
    };
    
    await chrome.declarativeNetRequest.updateDynamicRules({
      addRules: [blockRule]
    });
  } else {
    console.log("No sites to block");
  }
}

// Send message to native host
function sendToNative(message) {
  if (port) {
    port.postMessage(message);
  } else {
    console.error("Native messaging port not connected");
    connectToNative();
  }
}

// Service worker event listeners
chrome.runtime.onInstalled.addListener(() => {
  console.log("Extension installed");
  connectToNative();
});

// Handle service worker activation
chrome.runtime.onStartup.addListener(() => {
  console.log("Extension starting up");
  connectToNative();
});

// Keep the service worker alive with periodic alarms
chrome.alarms.create("keepAlive", { periodInMinutes: 1 });

chrome.alarms.onAlarm.addListener((alarm) => {
  if (alarm.name === "keepAlive") {
    // Check connection and reconnect if needed
    if (!port) {
      console.log("Keep-alive alarm triggered reconnection");
      connectToNative();
    }
  }
});

// Initialize connection
connectToNative();

// Set up initial blocking rules
registerBlockingRules();