// Native messaging host name
const hostName = "com.routine.native_messaging";
let port = null;

// Connect to native messaging host
function connectToNative() {
  port = chrome.runtime.connectNative(hostName);

  console.log("Connected to native app", port);
  
  port.onMessage.addListener((message) => {
    console.log("Received from native app:", message);
    // Handle messages from native app here
  });

  port.onDisconnect.addListener(() => {
    console.log("Disconnected from native app");
    port = null;
    // Attempt to reconnect after a delay
    setTimeout(connectToNative, 5000);
  });
}

// Initialize connection
connectToNative();

// List of blocked sites
const blockedSites = [
  '*://*.discord.com/*',
  '*://discord.com/*'
];

// Listener for web requests
function blockRequest(details) {
  // Notify native app about blocked request
  if (port) {
    port.postMessage({
      action: "site_blocked",
      data: {
        url: details.url,
        timestamp: Date.now()
      }
    });
  }
  
  return {
    redirectUrl: chrome.runtime.getURL('blocked.html')
  };
}

// Add the listener to block requests to specified sites
chrome.webRequest.onBeforeRequest.addListener(
  blockRequest,
  { urls: blockedSites },
  ['blocking']
);

// Function to send message to native app
function sendToNative(message) {
  if (port) {
    port.postMessage(message);
  } else {
    console.error("Native messaging port not connected");
    connectToNative();
  }
}

// Example: Send ping every 30 seconds to keep connection alive
setInterval(() => {
  console.log("Sending ping");
  sendToNative({
    action: "ping",
    data: { timestamp: Date.now() }
  });
}, 1000);
