enum Browser {
  firefox,
  chrome,
  edge,
  safari,
  opera,
  brave
}

class BrowserData {
  final String appName;
  final String extensionUrl;
  final String macosNmhDir;
  final bool macosControllable;
  final String macosPackage;
  final List<String> windowsPaths;
  final String windowsCommand;
  final String windowsRegistryPath;

  BrowserData({required this.windowsPaths, required this.appName, required this.windowsCommand, required this.extensionUrl, required this.macosNmhDir, required this.windowsRegistryPath, required this.macosControllable, required this.macosPackage});
}

final Map<Browser, BrowserData> browserData = {
    Browser.firefox: BrowserData(
      windowsPaths: ['C:\\Program Files\\Mozilla Firefox', 'C:\\Program Files (x86)\\Mozilla Firefox'],
      windowsCommand: 'firefox',
      appName: 'Firefox',
      extensionUrl: 'https://addons.mozilla.org/firefox/addon/routineblocker/',
      macosNmhDir: 'Library/Application Support/Mozilla/NativeMessagingHosts/',
      windowsRegistryPath: 'SOFTWARE\\Mozilla\\NativeMessagingHosts',
      macosControllable: false,
      macosPackage: 'org.mozilla.firefox'
    ),
    Browser.chrome: BrowserData(
      windowsPaths: ['C:\\Program Files\\Google\\Chrome\\Application', 'C:\\Program Files (x86)\\Google\\Chrome\\Application'],
      windowsCommand: 'chrome',
      appName: 'Google Chrome',
      extensionUrl: 'https://chrome.google.com/webstore/detail/routineblocker/id',
      macosNmhDir: 'Library/Application Support/Google/Chrome/NativeMessagingHosts/',
      windowsRegistryPath: 'SOFTWARE\\Google\\Chrome\\NativeMessagingHosts',
      macosControllable: true,
      macosPackage: 'com.google.Chrome'
    ),
    Browser.edge: BrowserData(
      windowsPaths: ['C:\\Program Files (x86)\\Microsoft\\Edge\\Application', 'C:\\Program Files\\Microsoft\\Edge\\Application'],
      windowsCommand: 'msedge',
      appName: 'Microsoft Edge',
      extensionUrl: 'https://microsoftedge.microsoft.com/addons/detail/routineblocker/id',
      macosNmhDir: 'Library/Application Support/Microsoft Edge/NativeMessagingHosts/',
      windowsRegistryPath: 'SOFTWARE\\Microsoft\\Edge\\NativeMessagingHosts',
      macosControllable: true,
      macosPackage: 'com.microsoft.edgemac'
    ),
    Browser.safari: BrowserData(
      windowsPaths: [],  // Safari is not available on Windows
      windowsCommand: '',
      appName: 'Safari',
      extensionUrl: 'https://apps.apple.com/app/routineblocker/id',
      macosNmhDir: 'Library/Safari/NativeMessagingHosts/',
      windowsRegistryPath: '',
      macosControllable: true,
      macosPackage: 'com.apple.Safari'
    ),
    Browser.opera: BrowserData(
      windowsPaths: ['C:\\Program Files\\Opera', 'C:\\Program Files (x86)\\Opera'],
      windowsCommand: 'opera',
      appName: 'Opera',
      extensionUrl: 'https://addons.opera.com/extensions/details/routineblocker/',
      macosNmhDir: 'Library/Application Support/com.operasoftware.Opera/NativeMessagingHosts/',
      windowsRegistryPath: 'SOFTWARE\\Opera Software\\Opera Stable\\NativeMessagingHosts',
      macosControllable: true,
      macosPackage: 'com.operasoftware.Opera'
    ),
    Browser.brave: BrowserData(
      windowsPaths: ['C:\\Program Files\\BraveSoftware\\Brave-Browser\\Application', 'C:\\Program Files (x86)\\BraveSoftware\\Brave-Browser\\Application'],
      windowsCommand: 'brave',
      appName: 'Brave',
      extensionUrl: 'https://chrome.google.com/webstore/detail/routineblocker/id',  // Uses Chrome Web Store
      macosNmhDir: 'Library/Application Support/BraveSoftware/Brave-Browser/NativeMessagingHosts/',
      windowsRegistryPath: 'SOFTWARE\\BraveSoftware\\Brave-Browser\\NativeMessagingHosts',
      macosControllable: true,
      macosPackage: 'com.brave.Browser'
    )
  };