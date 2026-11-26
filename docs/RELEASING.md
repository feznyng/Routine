# Releasing

`git tag v1.2.3 && git push origin v1.2.3` builds all four platforms, uploads iOS
to TestFlight and Android to the Play internal track, and opens a **draft** GitHub
release with the APK, DMG and Windows installer attached.
The draft's body is the install section from `scripts/release/notes.sh`,
followed by GitHub's generated **What's Changed** list of PRs merged since the
previous tag. Edit it before publishing.

`workflow_dispatch` from the Actions tab builds artifacts without publishing.
Pick a single **platform** there to run one job instead of all four — useful
while bringing a platform up, so you aren't reading three unrelated failures.
A tag push always runs everything.

A build-only run (dispatch with **publish** off) skips every credential-dependent
step, so it runs green before any secrets exist. A publishing run (a tag push,
or dispatch with **publish** on) fails early if a platform's secrets or real
configs are missing, rather than going green without shipping anything.

## Run it locally

All logic lives in `scripts/release/`; the workflow only wires up toolchains,
secrets and artifacts. Every script reads plain env vars and degrades gracefully
when credentials are missing, so you can debug without pushing a tag.

```sh
just release ios            # build + archive + upload to TestFlight
just release macos          # build + sign + DMG  → dist/
just release android        # build AAB + APK     → dist/
just release windows        # build + installer   → dist/   (on Windows)
just release-notes          # preview the notes for whatever is in dist/
```

`just release ios` produces no file in `dist/` — the deliverable is a build on App
Store Connect. It needs a Ruby newer than the macOS system 2.6, which `bundle`
resolves to by default:

```sh
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"   # or rbenv/mise
cd ios && bundle install
```

The version defaults to `pubspec.yaml`; override with `VERSION_NAME=1.4.0
BUILD_NUMBER=42 just release macos`. CI passes them explicitly from the tag.

iOS is the exception on build numbers. Apple requires them to be unique per
version string, and pubspec's `+N` goes stale the moment you ship, so with
credentials set `ios.sh` asks App Store Connect what it has already accepted and
takes the next one. CI does the same, so the iOS job is not given the run
number that the other platforms use, and local and CI uploads never collide.
Setting `BUILD_NUMBER` still wins, for pinning a specific number by hand.

The scripts are also runnable directly (`./scripts/release/macos.sh`) — `just
release` is a thin wrapper so there is one entry point on every platform.

### Credentials on your laptop

The App Store Connect key uses fastlane's own variable names, so fastlane picks
them up with no mapping. CI passes `APP_STORE_CONNECT_API_KEY_KEY` (the `.p8`
contents) because a GitHub secret is a string. Locally, point at the file
instead and the key stays out of your shell's environment:

```zsh
export APP_STORE_CONNECT_API_KEY_KEY_ID=XXXXXXXXXX
export APP_STORE_CONNECT_API_KEY_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
export APP_STORE_CONNECT_API_KEY_KEY_FILEPATH=~/Keys/app-store-connect-routine-key.p8
```

`load_app_store_connect_key` in `lib.sh` turns either form into a file path,
since that's what `notarytool` needs, and then unsets `_KEY`. Don't skip that
unset: with both set, fastlane silently uses `_KEY` and ignores the file, so iOS
and macOS could sign in with different keys. Never put these in `.env` —
`pubspec.yaml` declares it as a Flutter asset, so it ships inside the app.

See [SECRETS.md](SECRETS.md) for every variable, grouped by platform.

`macos.sh` uses whatever is in your login keychain when `MACOS_SIGNING_IDENTITY`
is set; the p12 import path is CI-only. Windows tooling is PowerShell
(`windows.ps1`), matching `build_windows.ps1` and `clean_windows.ps1` — the
Justfile deliberately assumes no bash on Windows.

### Layering

```
just release <platform>     scripts/release/*  — credentials, signing, packaging
  └─ just build <plat>      Justfile           — NMH + firebase-strip + flutter build
       └─ just build-nmh    browser/build_*    — native messaging host
```

### Desktop builds go through `just`, never `flutter build`

`macos.sh` and `windows.sh` call `just build <platform>`, which is the existing
orchestrator. Calling Flutter directly breaks two things:

- **The native messaging host is missing.** `just build` runs `build-nmh` first,
  producing `assets/extension/native_*`. The Xcode copy phase and the CMake
  `install()` steps only emit a *warning* when it's absent — so a direct build
  goes green and ships with browser blocking silently dead.
- **Windows won't build at all.** `firebase_core`'s CMake step downloads the C++
  SDK and fails on Windows; `just build windows` wraps the build in
  `firebase-strip` / `firebase-restore`.

The `release` recipe is variadic, so version flags pass through:
`just build macos --build-name=1.2.3 --build-number=42`.

On macOS the Developer ID certificate must be in the keychain **before** the
build, because `browser/build_native_macos.sh` signs the host with its own
entitlements (`app-sandbox=false`). `macos.sh` imports the cert first for this
reason. Without an identity that script falls back to an ad-hoc signature, which
keeps `just build macos` working for contributors with no Apple Developer
account — fine locally, not for anything you ship.

### The browser extension is dispatch-only

`just build-ext` runs `scripts/release/extension.sh`, which builds the Firefox
and Chrome zips, publishes to the CWS and signs on AMO. There is an `extension`
job in the workflow, but it is deliberately **not** part of `all` and never runs
on a tag push — the extension versions independently of the app
(`browser/extension/manifest.json` is at 2.1 while the app is at 1.0.0), and AMO
rejects re-signing a version that already exists, so tying it to app tags would
fail every release that didn't also bump the manifest.

To ship one, run the workflow from the Actions tab with **platform: extension**
and **publish** ticked. With publish off the store credentials are blanked and
the job degrades to "do the zips still build", which is also what a local run
with no credentials does.

Linux is still unwired: `linux/CMakeLists.txt` and `build_native_linux.sh` exist
and `just build linux` works, but there is no Linux job in the workflow yet.

For iOS, `scripts/release/ios.sh` runs the Flutter build and then hands off to
fastlane, which is already the extracted layer: `cd ios && bundle exec fastlane
ci_beta` with the same env the workflow passes. The script exists so the key is
normalised to a file before fastlane sees it, and so the Flutter build never
gets skipped — `build_app`
archives whatever Xcode can see, and `CFBundleVersion` comes from
`$(FLUTTER_BUILD_NUMBER)` in `Generated.xcconfig`, which only `flutter build`
writes.

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
| `APP_STORE_CONNECT_API_KEY_KEY` | iOS, macOS | the downloaded `.p8`, contents verbatim |
| `IOS_CERT_P12_B64` | iOS | Apple Distribution cert exported from Keychain |
| `IOS_CERT_PASSWORD` | iOS | the export passphrase |
| `MACOS_CERT_P12_B64` | macOS | Developer ID Application cert exported from Keychain |
| `MACOS_CERT_PASSWORD` | macOS | the export passphrase |
| `DOTENV` | all | contents of your real `.env` |
| `FIREBASE_OPTIONS_DART` | all | contents of `lib/firebase_options.dart` |
| `GOOGLE_SERVICES_JSON` | Android | contents of `android/app/google-services.json` |
| `GOOGLE_SERVICE_INFO_PLIST` | iOS | contents of `ios/Runner/GoogleService-Info.plist` |
| `AMO_JWT_SECRET` | Extension | addons.mozilla.org → Developer Hub → API keys |
| `CWS_CLIENT_SECRET` | Extension | GCP OAuth client for the Chrome Web Store API |
| `CWS_REFRESH_TOKEN` | Extension | one-time OAuth consent against that client |

The Android keystore is the one that cannot be rotated: lose or leak it and
users can never upgrade in place again. Back it up somewhere durable.

**Identifiers — secrets by convention, not by need:**

| Secret | Used by | Note |
|---|---|---|
| `ANDROID_KEY_ALIAS` | Android | just a name inside the keystore |
| `APP_STORE_CONNECT_API_KEY_KEY_ID` | iOS, macOS | useless without the `.p8` |
| `APP_STORE_CONNECT_API_KEY_ISSUER_ID` | iOS, macOS | per-team identifier |
| `MACOS_SIGNING_IDENTITY` | macOS | e.g. `Developer ID Application: SolidSoft LLC (5P7GGUGK9M)` |
| `AMO_JWT_ISSUER` | Extension | issued alongside `AMO_JWT_SECRET` |
| `CWS_CLIENT_ID` | Extension | useless without the client secret |
| `CWS_EXTENSION_ID` | Extension | the public Chrome Web Store item id |

`MACOS_SIGNING_IDENTITY` is worth moving to a repository **variable**: the value
is embedded in every binary you sign, so it is not secret, and keeping it as a
secret makes GitHub mask your company name as `***` throughout `codesign` output,
which makes signing failures harder to read. The rest cost nothing to leave as
secrets.

## Variables

Repository **variables** (not secrets), used only in the release notes template:

| Variable | Value |
|---|---|
| `TESTFLIGHT_URL` | Public TestFlight link — **defaults** to `https://testflight.apple.com/join/MQS1bU25` in `notes.sh` |
| `PLAY_TESTING_URL` | Play open-testing opt-in link |

Both are stable — set them once and every release reuses them.

`TESTFLIGHT_URL` is baked into `scripts/release/notes.sh` as a default so `just
release-notes` renders the real link locally with no env setup. Setting the repo
variable still overrides it; do that rather than editing the script if the beta
link ever changes, or change both together.

## Before the first release

### Blocking: Family Controls distribution entitlement

`Runner.entitlements` and `ActivityMonitor.entitlements` both declare
`com.apple.developer.family-controls`. Development builds work with the default
entitlement, but **App Store and TestFlight distribution require Apple to approve
the capability for your team.** Request it at
<https://developer.apple.com/contact/request/family-controls-distribution>.

Until it is granted, App Store profiles carrying the entitlement cannot be
minted at all and the iOS job will fail at signing. Request it early; turnaround
is not instant. If Apple attaches a provisioning profile *template* to the
approval rather than enabling the capability on the App IDs directly, pass its
name to `get_provisioning_profile(template_name:)` in `ios/fastlane/Fastfile`.

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

Export the **Apple Distribution** certificate (not Developer ID) as a `.p12` with
a passphrase — same shape as macOS below, and the same reason: an ephemeral
runner has no keychain to reuse, so the certificate is shipped in rather than
created per run. Apple caps a team at a handful of distribution certificates, and
anything that mints them on demand exhausts that cap one release at a time.

Provisioning profiles are not pre-created. `ci_beta` fetches them from App Store
Connect with the same API key, reusing a valid profile and minting a new one
only when it is missing or expired — profiles, unlike certificates, are free and
disposable. Both App IDs need to exist in the Developer portal first, with the
Family Controls capability and the `group.routineblocker` app group enabled.

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
  both require strictly increasing values, so never reset it. It is passed
  explicitly, which also suppresses the App Store Connect lookup `ios.sh` does
  for local runs.

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
