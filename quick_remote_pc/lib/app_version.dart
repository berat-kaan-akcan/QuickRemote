/// The version this build was made as. Release builds pass it with
/// `--dart-define=APP_VERSION=<version>` (the same as `--build-name`).
const appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '0.1.0');

/// Whether the app may ask GitHub for a newer release. Packages that update
/// themselves (AUR, Store, winget) build with `--dart-define=UPDATE_CHECK=false`.
const updateCheckEnabled = bool.fromEnvironment(
  'UPDATE_CHECK',
  defaultValue: true,
);
