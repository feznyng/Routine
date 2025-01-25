// Native messaging host name
const hostName = "com.routine.native_messaging";
let port = null;

// List of blocked sites
let blockedSites = [];
let webRequestListener = null;

// Connect to native messaging host
function connectToNative() {
  port = chrome.runtime.connectNative(hostName);
  
  console.log("Connected to native host", port);

  port.onMessage.addListener((message) => {
    console.log("Received message from native host:", message);
    
    if (message.action === "updateBlockedSites" && Array.isArray(message.data.sites)) {
      // Update blocked sites list
      blockedSites = message.data.sites;
      
      // Re-register web request listener with new patterns
      updateWebRequestListener();
      
      console.log("Updated blocked sites:", blockedSites);
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
  // Notify native app about blocked request
  if (port) {
    sendToNative({
      action: "blocked",
      data: {
        url: details.url,
        timestamp: Date.now()
      }
    });
  }
  
  return { cancel: true };
}

// Update web request listener with current patterns
function updateWebRequestListener() {
  // Remove existing listener if any
  if (webRequestListener) {
    chrome.webRequest.onBeforeRequest.removeListener(webRequestListener);
  }
  
  // Only add listener if we have patterns to match
  if (blockedSites.length > 0) {
    webRequestListener = chrome.webRequest.onBeforeRequest.addListener(
      blockRequest,
      { urls: blockedSites },
      ["blocking"]
    );
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