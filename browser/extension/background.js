// Native messaging host name
const hostName = "com.solidsoft.routine.NativeMessagingHost";
let port = null;
let isAppConnected = false;  // Track Flutter app connection state
let reconnectTimer = null;
const RECONNECT_INTERVAL = 2000; // Attempt reconnection every 2 seconds to match onboarding dialog behavior

// List of blocked sites
let blockedSites = [];
let allowList = false;

// Connect to native messaging host
function connectToNative() {
  try {
    port = chrome.runtime.connectNative(hostName);
    console.log("Attempting to connect to native host");

  port.onMessage.addListener((message) => {
    console.log("Received message from native host:", message);
    
    if (message.action === "updateBlockedSites" && Array.isArray(message.data.sites)) {
      // Update blocked sites list
      blockedSites = message.data.sites;
      allowList = message.data.allowList;
      
      // Re-register web request listener with new patterns
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
    console.log("Disconnected from native host", error ? error.message : "");
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
  }, delay);
}

// Initialize connection
connectToNative();

// Check if hostname matches any domain in the list (including subdomains)
function matchesDomain(hostname, domainList) {
  return domainList.some(domain => {
    // Exact match
    if (hostname === domain) return true;
    // Subdomain match (ensure it ends with .domain)
    return hostname.endsWith('.' + domain);
  });
}

// Listener for web requests
function blockRequest(details) {
  // If app is not connected, allow all requests
  if (!isAppConnected) {
    console.log("App not connected, allowing request");
    return;
  }

  const url = new URL(details.url);
  const hostname = url.hostname;

  if (allowList) {
    // In allowList mode, allow only sites in the list
    const isAllowed = matchesDomain(hostname, blockedSites);
    if (!url.contains('routineblocker.com') && !isAllowed) {
      console.log("Blocking non-allowed site:", hostname);
      return { redirectUrl: 'https://www.routineblocker.com/blocked' };
    }
  } else {
    // In blockgroup mode, block only sites in the list
    if (matchesDomain(hostname, blockedSites)) {
      console.log("Blocking blocked site:", hostname);
      return { redirectUrl: 'https://www.routineblocker.com/blocked' };
    }
  }
}

// Register blocking rules
function registerBlockingRules() {
  // First remove existing listener
  try {
    chrome.webRequest.onBeforeRequest.removeListener(blockRequest);
  } catch (e) {
    // Listener might not exist yet
    console.log("No existing listener to remove");
  }
  
  // Only register blocking if app is connected and have sites to block
  if (isAppConnected && (allowList || blockedSites.length > 0)) {
    console.log(`Registering ${allowList ? 'allowList' : 'blockgroup'} mode with ${allowList ? 'allowed' : 'blocked'} sites:`, blockedSites);
    chrome.webRequest.onBeforeRequest.addListener(
      blockRequest,
      {
        urls: ["<all_urls>"],
        types: [
          "main_frame",        // New page loads
          "sub_frame",         // iframes
          "xmlhttprequest",    // Ajax requests
          "websocket"          // WebSocket connections
        ]
      },
      ["blocking"]
    );
  } else {
    console.log(isAppConnected ? "No sites to block" : "App not connected, blocking disabled");
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

// Set up initial blocking rules
registerBlockingRules();