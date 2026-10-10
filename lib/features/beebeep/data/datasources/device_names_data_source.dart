import 'dart:io';

/// Account and computer names the OS exposes without permissions. Phones
/// usually have neither (Android has no account name, iOS reports `mobile`).
class DeviceNamesDataSource {
  const DeviceNamesDataSource();

  /// `USERNAME` on Windows, `USER` or `LOGNAME` on macOS and Linux.
  String? userName() {
    final env = Platform.environment;
    return env['USERNAME'] ?? env['USER'] ?? env['LOGNAME'];
  }

  String? hostName() {
    try {
      return Platform.localHostname;
    } on Object {
      return null;
    }
  }
}
