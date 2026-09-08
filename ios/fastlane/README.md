fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios next_build_number

```sh
[bundle exec] fastlane ios next_build_number
```

Write the next unused TestFlight build number to $BUILD_NUMBER_OUT

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Push a new beta build to TestFlight (local, interactive)

### ios ci_beta

```sh
[bundle exec] fastlane ios ci_beta
```

Build and upload to TestFlight from CI

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
