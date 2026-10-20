/// The version this build was made as. Release builds pass it with
/// `--dart-define=APP_VERSION=<version>` (the same as `--build-name`).
const appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '0.1.0');
