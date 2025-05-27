enum Browser {
  firefox,
  chrome,
  edge,
  safari,
  opera,
  brave
}

class BrowserData {
  final int port;
  final List<String> windowsPaths;
  final String appName;
  final String windowsCommand;
  final String extensionUrl;
  final String macosNmhDir;
  final String registryPath;

  BrowserData({required this.port, required this.windowsPaths, required this.appName, required this.windowsCommand, required this.extensionUrl, required this.macosNmhDir, required this.registryPath});
}

final Map<Browser, BrowserData> browserData = {
    Browser.firefox: BrowserData(
      port: 54322,
      windowsPaths: ['C:\\Program Files\\Mozilla Firefox', 'C:\\Program Files (x86)\\Mozilla Firefox'],
      windowsCommand: 'firefox',
      appName: 'Firefox',
      extensionUrl: 'https://addons.mozilla.org/firefox/addon/routineblocker/',
      macosNmhDir: 'Library/Application Support/Mozilla/NativeMessagingHosts/',
      registryPath: 'SOFTWARE\\Mozilla\\NativeMessagingHosts'
    ),
    Browser.chrome: BrowserData(
      port: 54323,
      windowsPaths: ['C:\\Program Files\\Google\\Chrome\\Application', 'C:\\Program Files (x86)\\Google\\Chrome\\Application'],
      windowsCommand: 'chrome',
      appName: 'Google Chrome',
      extensionUrl: 'https://chrome.google.com/webstore/detail/routineblocker/id',
      macosNmhDir: 'Library/Application Support/Google/Chrome/NativeMessagingHosts/',
      registryPath: 'SOFTWARE\\Google\\Chrome\\NativeMessagingHosts'
    ),
    Browser.edge: BrowserData(
      port: 54324,
      windowsPaths: ['C:\\Program Files (x86)\\Microsoft\\Edge\\Application', 'C:\\Program Files\\Microsoft\\Edge\\Application'],
      windowsCommand: 'msedge',
      appName: 'Microsoft Edge',
      extensionUrl: 'https://microsoftedge.microsoft.com/addons/detail/routineblocker/id',
      macosNmhDir: 'Library/Application Support/Microsoft Edge/NativeMessagingHosts/',
      registryPath: 'SOFTWARE\\Microsoft\\Edge\\NativeMessagingHosts'
    ),
    Browser.safari: BrowserData(
      port: 54325,
      windowsPaths: [],  // Safari is not available on Windows
      windowsCommand: '',
      appName: 'Safari',
      extensionUrl: 'https://apps.apple.com/app/routineblocker/id',
      macosNmhDir: 'Library/Safari/NativeMessagingHosts/',
      registryPath: ''
    ),
    Browser.opera: BrowserData(
      port: 54326,
      windowsPaths: ['C:\\Program Files\\Opera', 'C:\\Program Files (x86)\\Opera'],
      windowsCommand: 'opera',
      appName: 'Opera',
      extensionUrl: 'https://addons.opera.com/extensions/details/routineblocker/',
      macosNmhDir: 'Library/Application Support/com.operasoftware.Opera/NativeMessagingHosts/',
      registryPath: 'SOFTWARE\\Opera Software\\Opera Stable\\NativeMessagingHosts'
    ),
    Browser.brave: BrowserData(
      port: 54327,
      windowsPaths: ['C:\\Program Files\\BraveSoftware\\Brave-Browser\\Application', 'C:\\Program Files (x86)\\BraveSoftware\\Brave-Browser\\Application'],
      windowsCommand: 'brave',
      appName: 'Brave',
      extensionUrl: 'https://chrome.google.com/webstore/detail/routineblocker/id',  // Uses Chrome Web Store
      macosNmhDir: 'Library/Application Support/BraveSoftware/Brave-Browser/NativeMessagingHosts/',
      registryPath: 'SOFTWARE\\BraveSoftware\\Brave-Browser\\NativeMessagingHosts'
    )
  };