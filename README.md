# Routine

App/site blocker for Windows, MacOS, and iOS.

## Features

- **Cross-platform:** Works across (almost) all your devices and can automatically sync changes you make to your routines. 
- **Conditions**: Allows you to define special conditions on lists like needing to visit a location or scan an NFC tag/QR Code before unlocking your apps, allowing you to incentivize good habits like going to the gym.
- **Local-First**: Routine can run entirely offline on your device with optional remote sync. Specifically blocked apps/sites never leave your device.
- **Flexible**: Supports both block and allow lists and multiple active lists at the same time. 
- **Strict**: Provides strict mode settings to add friction to modifying routines and can block common bypass methods like the task manager or settings changes. 

| Platform | Support 
| -------- | ------- 
| MacOS    | ✅         
| iOS      | ✅        
| Windows  | ✅        
| Android  | 🚧        
| Linux    | 🚧     

## Development

Docs are WIP - please open an issue if you think something needs further explanation. 

Routine is a Flutter application. Business logic and UI is written in Dart with platform-specific blocking logic written in Swift (MacOS, iOS) and C++ (Windows). 

To get started with Routine development, follow [Flutter Get Started](https://docs.flutter.dev/get-started/install) for the platform(s) you'd like to develop for. After you have that set up, you can use the standard commands to run/build/develop Routine.

### iOS and MacOS
iOS and MacOS development will require an [Apple Developer account](https://developer.apple.com/programs/enroll/) due to required entitlements (Family Controls, etc.). 

### Windows
Unfortunately, builds fail on Windows when firebase_core is included, you can use the feat/no-firebase branch to bypass this issue.

### Supabase
Cross-device sync is performed via Supabase. Credentials for this are provided via a .env file in the root directory, refer to .env.example. If you don't have a Supabase project setup, you can simply duplicate and rename .env.example to .env. Empty values are fine.

Sync backend can be found in `./supabase` including an sql setup script and edge function source. It's multi-tenant but will work fine with a single user (you). 

### Firebase
Mobile notifications and background sync requests are sent through Firebase Cloud Messaging (FCM). If you don't have a Firebase project, you can duplicate and rename the firebase_options.example.dart file to firebase_options.dart for local development.

### Browser Extension
Routine performs site blocking on desktop through a browser extension (`./browser/extension`). Communication with the extension is performed via TCP socket using a [native messaging host (NMH)](https://developer.chrome.com/docs/extensions/develop/concepts/native-messaging) (`./browser/native`). You'll need to [install Rust](https://www.rust-lang.org/tools/install) in order to build the NMH.