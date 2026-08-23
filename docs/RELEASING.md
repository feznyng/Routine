# Releasing

`git tag v1.2.3 && git push origin v1.2.3` builds all four platforms, uploads iOS
to TestFlight and Android to the Play internal track, and opens a **draft** GitHub
release with the APK, DMG and Windows installer attached.

`workflow_dispatch` from the Actions tab builds artifacts without publishing.

Every credential-dependent step is guarded on its secret, so the workflow runs
green before any secrets exist. Provision them platform by platform.

## Run it locally

All logic lives in `scripts/release/`; the workflow only wires up toolchains,
secrets and artifacts. Every script reads plain env vars and degrades gracefully
when credentials are missing, so you can debug without pushing a tag.

```sh
just dist macos          # build + sign + DMG  → dist/
just dist android        # build AAB + APK     → dist/
just dist windows        # build + installer   → dist/   (on Windows)
just release-notes       # preview the notes for whatever is in dist/
```

The version defaults to `pubspec.yaml`; override with `VERSION_NAME=1.4.0
BUILD_NUMBER=42 just dist macos`. CI passes them explicitly from the tag.

The scripts are also runnable directly (`./scripts/release/macos.sh`) — `just
dist` is a thin wrapper so there is one entry point on every platform.

`macos.sh` uses whatever is in your login keychain when `MACOS_SIGNING_IDENTITY`
is set; the p12 import path is CI-only. Windows tooling is PowerShell
(`windows.ps1`), matching `build_windows.ps1` and `clean_windows.ps1` — the
Justfile deliberately assumes no bash on Windows.

### Layering

```
just dist <platform>        scripts/release/*  — credentials, signing, packaging
  └─ just release <plat>    Justfile           — NMH + firebase-strip + flutter build
       └─ just build-nmh    browser/build_*    — native messaging host
```

### Desktop builds go through `just`, never `flutter build`

`macos.sh` and `windows.sh` call `just release <platform>`, which is the existing
orchestrator. Calling Flutter directly breaks two things:

- **The native messaging host is missing.** `just release` runs `build-nmh` first,
  producing `assets/extension/native_*`. The Xcode copy phase and the CMake
  `install()` steps only emit a *warning* when it's absent — so a direct build
  goes green and ships with browser blocking silently dead.
- **Windows won't build at all.** `firebase_core`'s CMake step downloads the C++
  SDK and fails on Windows; `just release windows` wraps the build in
  `firebase-strip` / `firebase-restore`.

The `release` recipe is variadic, so version flags pass through:
`just release macos --build-name=1.2.3 --build-number=42`.

On macOS the Developer ID certificate must be in the keychain **before** the
build, because `browser/build_native_macos.sh` signs the host with its own
entitlements (`app-sandbox=false`). `macos.sh` imports the cert first for this
reason. Without an identity that script falls back to an ad-hoc signature, which
keeps `just release macos` working for contributors with no Apple Developer
account — fine locally, not for anything you ship.

### Not wired up: the browser extension

`just build-ext` builds the Firefox and Chrome zips, signs on AMO and publishes
to the CWS. It is deliberately **not** part of this workflow — the extension
versions independently of the app (`browser/extension/manifest.json` is at 2.1
while the app is at 1.0.0), and AMO rejects re-signing a version that already
exists, so tying it to app tags would fail every release that didn't also bump
the manifest. Run it by hand, or give it its own workflow on an `ext-v*` tag.

Linux is also unwired: `linux/CMakeLists.txt` and `build_native_linux.sh` exist
and `just release linux` works, but there is no Linux job in the workflow yet.

For iOS, fastlane is already the extracted layer: `cd ios && bundle exec fastlane
ci_beta` with the same env the workflow passes.

## Config bootstrap

`scripts/release/bootstrap.sh` runs first in every platform job and writes the
gitignored config a build needs. For each file it uses the secret when set,
otherwise the checked-in `.example`:

| File | Secret | Example fallback |
|---|---|---|
| `.env` | `DOTENV` | `.env.example` |
| `lib/firebase_options.dart` | `FIREBASE_OPTIONS_DART` | `firebase_options.example.dart` |
| `android/app/google-services.json` | `GOOGLE_SERVICES_JSON` | `google-services.example.json` |
| `ios/Runner/GoogleService-Info.plist` | `GOOGLE_SERVICE_INFO_PLIST` | `GoogleService-Info.example.plist` |

The examples exist so the workflow compiles without credentials — useful for
smoke-testing CI and for forks. **A build made from examples is not
distributable**: Firebase and Supabase are unreachable. The script prints a loud
warning when any placeholder is used, and is idempotent, so it leaves real files
alone when run locally.

`.env` must never regain `RESEND_KEY` or anything else genuinely secret: it is a
pubspec asset, so it ships inside `flutter_assets/` in every APK, DMG and
installer, where anyone can read it. Only values safe to publish belong there —
the Supabase anon key and Sentry DSN are designed to be public; a mail-provider
API key is not.

## Secrets

Not everything below is equally sensitive. Compromise of the first group lets
someone ship software as you; the second group are identifiers that are useless
on their own.

**Real credentials — protect these:**

| Secret | Used by | Where it comes from |
|---|---|---|
| `ANDROID_KEYSTORE_B64` | Android | `base64 -i upload-keystore.jks` |
| `ANDROID_STORE_PASSWORD` | Android | keystore creation |
| `ANDROID_KEY_PASSWORD` | Android | keystore creation |
| `PLAY_SERVICE_ACCOUNT_JSON` | Android | GCP service account, granted access in Play Console |
| `ASC_PRIVATE_KEY` | iOS, macOS | the downloaded `.p8`, contents verbatim |
| `MATCH_PASSWORD` | iOS | passphrase you choose on `match init` |
| `MATCH_GIT_BASIC_AUTHORIZATION` | iOS | `base64` of `user:personal_access_token` |
| `MACOS_CERT_P12_B64` | macOS | Developer ID Application cert exported from Keychain |
| `MACOS_CERT_PASSWORD` | macOS | the export passphrase |
| `DOTENV` | all | contents of your real `.env` |
| `FIREBASE_OPTIONS_DART` | all | contents of `lib/firebase_options.dart` |
| `GOOGLE_SERVICES_JSON` | Android | contents of `android/app/google-services.json` |
| `GOOGLE_SERVICE_INFO_PLIST` | iOS | contents of `ios/Runner/GoogleService-Info.plist` |

The Android keystore is the one that cannot be rotated: lose or leak it and
users can never upgrade in place again. Back it up somewhere durable.

**Identifiers — secrets by convention, not by need:**

| Secret | Used by | Note |
|---|---|---|
| `ANDROID_KEY_ALIAS` | Android | just a name inside the keystore |
| `ASC_KEY_ID` | iOS, macOS | useless without the `.p8` |
| `ASC_ISSUER_ID` | iOS, macOS | per-team identifier |
| `MATCH_GIT_URL` | iOS | a repo URL |
| `MACOS_SIGNING_IDENTITY` | macOS | e.g. `Developer ID Application: SolidSoft LLC (5P7GGUGK9M)` |

`MACOS_SIGNING_IDENTITY` is worth moving to a repository **variable**: the value
is embedded in every binary you sign, so it is not secret, and keeping it as a
secret makes GitHub mask your company name as `***` throughout `codesign` output,
which makes signing failures harder to read. The rest cost nothing to leave as
secrets.

## Variables

Repository **variables** (not secrets), used only in the release notes template:

| Variable | Value |
|---|---|
| `TESTFLIGHT_URL` | Public TestFlight link |
| `PLAY_TESTING_URL` | Play open-testing opt-in link |

Both are stable — set them once and every release reuses them.

## Before the first release

### Blocking: Family Controls distribution entitlement

`Runner.entitlements` and `ActivityMonitor.entitlements` both declare
`com.apple.developer.family-controls`. Development builds work with the default
entitlement, but **App Store and TestFlight distribution require Apple to approve
the capability for your team.** Request it at
<https://developer.apple.com/contact/request/family-controls-distribution>.

Until it is granted, `match appstore` cannot mint profiles carrying the
entitlement and the iOS job will fail at signing. Request it early; turnaround is
not instant.

The app group `group.routineblocker` must also be registered in the Developer
portal and included in both App IDs.

### Android

1. Create the upload keystore, then **back it up somewhere durable**:
   ```
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA \
     -keysize 2048 -validity 10000 -alias upload
   ```
   Losing it means sideload users can never upgrade in place.
2. Grant the GCP service account access under Play Console → Users and permissions.
3. The first upload to a track must be done manually through the Console; the
   API can only add to an existing track.

### iOS

Run `bundle exec fastlane match appstore` from your laptop once to populate the
match repo. CI is `readonly: true` and will never create certificates itself.

### macOS

Export the **Developer ID Application** certificate (not Apple Distribution) as a
`.p12` with a passphrase. The workflow signs the app, builds the DMG, signs the
DMG, notarizes it and staples the ticket.

### Windows

Nothing to do — the installer builds unsigned. Users get SmartScreen's "Windows
protected your PC" and click **More info → Run anyway**, which the release notes
explain.

To turn signing on later, uncomment the `azure/trusted-signing-action` block in
`.github/workflows/release.yml` and add `AZURE_TENANT_ID`, `AZURE_CLIENT_ID`,
`AZURE_CLIENT_SECRET`, `AZURE_SIGNING_ACCOUNT`, `AZURE_CERT_PROFILE`. Note that
Azure Artifact Signing's organization validation requires roughly three years of
verifiable operating history — see the notes in the workflow.

## Known landmines

- **`android/` has both Groovy and Kotlin DSL Gradle files.** Gradle uses
  `build.gradle` and silently ignores `build.gradle.kts`. The stale `.kts` files
  carry a *different* `applicationId` (`com.solidsoft.routine_blocker`). Deleting
  `android/app/build.gradle.kts`, `android/build.gradle.kts` and
  `android/settings.gradle.kts` would remove the trap.
- **`android/fastlane/Appfile` hardcodes an absolute path** to a service account
  JSON on your laptop. Fine locally; CI uses the upload action instead.
- **Build numbers come from `github.run_number`.** App Store Connect and Play
  both require strictly increasing values, so never reset it.

## Download links on the site

Release assets are deliberately **version-less** (`Routine-setup.exe`,
`Routine.dmg`, `Routine.apk`, `Routine.aab`) so that GitHub's permanent
redirect works:

```
https://github.com/feznyng/Routine/releases/latest/download/Routine.dmg
```

That always resolves to the newest **published** release, so the site never
needs updating per release. Don't reintroduce the version into asset filenames —
it breaks these links, and renaming later breaks any link people have shared.

`site/app/download/page.tsx` has a `DIRECT_DOWNLOADS` flag, currently `false`.
The redirect 404s while every release is a draft, so the desktop buttons point
at the releases page until then. **Flip it to `true` after publishing the first
non-draft release.** `TESTFLIGHT_URL` and `PLAY_TESTING_URL` in the same file
are empty strings until those channels exist; iOS shows a disabled "Coming soon"
button until `TESTFLIGHT_URL` is set.
