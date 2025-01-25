# Site Blocker Extension

A simple cross-platform browser extension that blocks access to specified websites.

## Installation

### Chrome/Edge
1. Open Chrome/Edge and go to extensions page (chrome://extensions or edge://extensions)
2. Enable "Developer mode" in the top right
3. Click "Load unpacked" and select this directory

### Firefox
1. Open Firefox and go to about:debugging
2. Click "This Firefox" on the left
3. Click "Load Temporary Add-on"
4. Select the manifest.json file from this directory

## Configuration
To modify the list of blocked sites, edit the `blockedSites` array in `background.js`.