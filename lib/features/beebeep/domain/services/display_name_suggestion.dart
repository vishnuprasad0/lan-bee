/// Name every install used before names were suggested. A saved name equal to
/// this was never picked by the user, so it is replaced like an empty one.
const String legacyDefaultDisplayName = 'BeeBEEP Dart';

/// Account names that say nothing about the person.
const Set<String> _genericUserNames = {
  'root',
  'admin',
  'administrator',
  'user',
  'guest',
  'mobile',
  'default',
};

/// Host names that say nothing about the device.
const Set<String> _genericHostNames = {
  'localhost',
  'iphone',
  'ipad',
  'android',
  'computer',
  'mac',
  'macbook',
};

/// Windows default computer names, such as `DESKTOP-4F2K9QH`.
final RegExp _windowsDefaultHost = RegExp(
  r'^(desktop|laptop|win|pc)-[a-z0-9]{5,}$',
);

/// Name shown to others until the user picks one. The account name comes
/// first (BeeBEEP desktop also defaults to it), then the computer name.
/// Null when neither is usable, so the app asks instead.
String? suggestDisplayName({String? userName, String? hostName}) =>
    displayNameFromUser(userName) ?? displayNameFromHost(hostName);

/// `vishnu.prasad` becomes `Vishnu Prasad`; generic accounts give null.
String? displayNameFromUser(String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return null;
  if (_genericUserNames.contains(value.toLowerCase())) return null;
  return _titleCase(value.split(RegExp(r'[._\s]+')));
}

/// `Vishnus-MacBook-Pro.local` becomes `Vishnus MacBook Pro`; generic and
/// Windows default names give null.
String? displayNameFromHost(String? raw) {
  var value = raw?.trim() ?? '';
  final dot = value.indexOf('.');
  if (dot >= 0) value = value.substring(0, dot);
  if (value.isEmpty) return null;
  final lower = value.toLowerCase();
  if (_genericHostNames.contains(lower)) return null;
  if (lower.startsWith('android')) return null;
  if (_windowsDefaultHost.hasMatch(lower)) return null;
  return _titleCase(value.split(RegExp(r'[-_\s]+')));
}

/// Capitalises the first letter of each word and keeps the rest, so
/// `MacBook` stays `MacBook`.
String? _titleCase(List<String> words) {
  final parts = [
    for (final w in words)
      if (w.isNotEmpty) w[0].toUpperCase() + w.substring(1),
  ];
  return parts.isEmpty ? null : parts.join(' ');
}
