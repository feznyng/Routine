// Native messaging host name
const hostName = "com.routine.native_messaging";
let port = null;

// List of blocked sites
let blockedSites = [];
let allowList = false;

// Connect to native messaging host
function connectToNative() {
  port = chrome.runtime.connectNative(hostName);
  
  console.log("Connected to native host", port);

  port.onMessage.addListener((message) => {
    console.log("Received message from native host:", message);
    
    if (message.action === "updateBlockedSites" && Array.isArray(message.data.sites)) {
      // Update blocked sites list
      blockedSites = message.data.sites;
      allowList = message.data.allowList;
      
      // Re-register web request listener with new patterns
      registerBlockingRules();
      
      console.log("Updated blocked sites:", blockedSites, allowList);
    }
  });
  
  port.onDisconnect.addListener(() => {
    console.log("Disconnected from native host");
    port = null;
  });
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
  const url = new URL(details.url);
  const hostname = url.hostname;

  if (allowList) {
    // In allowList mode, allow only sites in the list
    const isAllowed = matchesDomain(hostname, blockedSites);
    if (!isAllowed) {
      console.log("Blocking non-allowed site:", hostname);
      return { redirectUrl: chrome.runtime.getURL('blocked.html') };
    }
  } else {
    // In blocklist mode, block only sites in the list
    if (matchesDomain(hostname, blockedSites)) {
      console.log("Blocking blocked site:", hostname);
      return { redirectUrl: chrome.runtime.getURL('blocked.html') };
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
  
  if (allowList || blockedSites.length > 0) {
    // Register for all URLs since we need to check each request
    console.log(`Registering ${allowList ? 'allowList' : 'blocklist'} mode with ${allowList ? 'allowed' : 'blocked'} sites:`, blockedSites);
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

// Set up initial blocking rules
registerBlockingRules();