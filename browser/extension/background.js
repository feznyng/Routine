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

// Listener for web requests
function blockRequest(details) {
  console.log("Blocking request:", details.url);
  
  return {
    redirectUrl: chrome.runtime.getURL('blocked.html')
  };
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
  
  // Only add listener if we have patterns to match
  if (blockedSites.length > 0) {
    console.log("Registering blocking rules for patterns:", blockedSites);
    chrome.webRequest.onBeforeRequest.addListener(
      blockRequest,
      { urls: blockedSites },
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