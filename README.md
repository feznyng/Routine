# Routine

App/site blocker for iOS, Android, macOS, and Windows.

## Features

- **Cross-platform:** Works across (almost) all your devices and can automatically sync changes you make to your routines. 
- **Conditions**: Allows you to define special conditions on lists like needing to visit a location or scan an NFC tag/QR Code before unlocking your apps, allowing you to incentivize good habits like going to the gym.
- **Local-First**: Runs offline-first with optional remote sync. Specifically blocked apps/sites never leave your device.
- **Flexible**: Supports both block and allow lists and multiple active lists at the same time. 
- **Strict**: Provides options to add friction to modifying routines and common bypass methods like the task manager or settings changes. 

## Support

### Platforms

| Platform | Supported | Minimum Version | Tested 
| -------- | ------- | --------------- | ----- 
| macOS    | ✅      | 13.5           | 14.6.1      
| iOS      | ✅      | 16             | 18.4.1      
| Windows  | ✅      | 10             | 11 Version 24H2      
| Android  | ✅      | 8              | 16 (Emulator)
| Linux    | 🚧      |                |       

### Browsers

| Browser | macOS | Windows | Android | iOS |
| ------- | ----- | ------- | ------- | --- |
| Firefox | ✅ | ✅ | ✅ | ✅ |
| Google Chrome | ✅ | ✅ | ✅ | ✅ |
| Microsoft Edge | ✅ | ✅ | ✅ | ✅ |
| Safari | ✅ | ➖ | ➖ | ✅ |
| Opera | ✅ | ✅ | ✅ | ✅ |
| Brave | ✅ | ✅ | ✅ | ✅ |
| Samsung Internet | ➖ | ➖ | ✅ | ➖ |
| DuckDuckGo | ➖ | ➖ | ✅ | ✅ |
| UC Browser | ➖ | ➖ | ✅ | ➖ |
| Vivaldi | ➖ | ➖ | ✅ | ➖ |

## Development

Docs are WIP - please open an issue if you think something needs further explanation. 

Routine is a Flutter application. Business logic and UI is written in Dart with platform-specific blocking logic written in Swift (MacOS, iOS), Kotlin (Android), C++ (Windows). 

To get started with Routine development, follow [Flutter Get Started](https://docs.flutter.dev/get-started/install) for the platform(s) you'd like to develop for. After you have that set up, you can use the standard commands to run/build/develop Routine. The following sections describe platform-specific considerations.

### iOS and MacOS
iOS and MacOS development will require an [Apple Developer account](https://developer.apple.com/programs/enroll/) due to required entitlements (Family Controls, etc.). 

### Windows
Unfortunately, builds fail on Windows when firebase_core is included. You can temporarily comment out any firebase-related code by running `clean_windows.ps1`. When you're ready to commit, run `clean_windows.ps1 -Uncomment` to uncomment.

### Supabase
Cross-device sync is performed via Supabase. Credentials for this are provided via a .env file in the root directory, refer to .env.example. If you don't have a Supabase project setup, you can simply duplicate and rename .env.example to .env. Empty values are fine.

Sync backend can be found in `./supabase` including an sql setup script and edge function source. It's multi-tenant but will work fine with a single user (you). 

### Firebase
Mobile notifications and background sync requests are sent through Firebase Cloud Messaging (FCM). If you don't have a Firebase project, you can duplicate and rename the firebase_options.example.dart file to firebase_options.dart for local development.

### Browser Extension
Routine performs site blocking on desktop through a browser extension (`./browser/extension`). Communication with the extension is performed via TCP socket using a [native messaging host (NMH)](https://developer.chrome.com/docs/extensions/develop/concepts/native-messaging) (`./browser/native`). This requires a working Dart toolchain which you should have from the Flutter setup. 