import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// True when a file exists at [path] on this device.
bool localFileExists(String? path) {
  if (path == null || path.isEmpty) return false;
  return File(path).existsSync();
}

/// Opens [path] with the default app, reporting problems in a snackbar.
Future<void> openLocalFile(BuildContext context, String? path) async {
  final messenger = ScaffoldMessenger.of(context);
  if (!localFileExists(path)) {
    messenger.showSnackBar(
      const SnackBar(content: Text('File no longer on this device')),
    );
    return;
  }

  try {
    final opened = await _openWithDefaultApp(path!);
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No app found to open this file')),
      );
    }
  } on Object catch (error) {
    debugPrint('Open file failed: $error');
    messenger.showSnackBar(
      const SnackBar(content: Text('Could not open this file')),
    );
  }
}

/// open_filex supports only Android and iOS; on desktop the OS shell opens
/// the file.
Future<bool> _openWithDefaultApp(String path) async {
  if (Platform.isWindows || Platform.isMacOS) {
    return launchUrl(Uri.file(path, windows: Platform.isWindows));
  }
  final result = await OpenFilex.open(path);
  return result.type == ResultType.done;
}

/// Shares [path] through the system share sheet.
Future<void> shareLocalFile(
  BuildContext context,
  String? path, {
  String? name,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  if (!localFileExists(path)) {
    messenger.showSnackBar(
      const SnackBar(content: Text('File no longer on this device')),
    );
    return;
  }

  try {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(path!, name: name)]),
    );
  } on Object catch (error) {
    debugPrint('Share failed: $error');
    messenger.showSnackBar(
      const SnackBar(content: Text('Could not share this file')),
    );
  }
}
