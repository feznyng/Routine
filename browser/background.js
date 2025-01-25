// List of blocked sites
const blockedSites = [
  '*://*.discord.com/*',
  '*://discord.com/*'
];

// Listener for web requests
function blockRequest(details) {
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
