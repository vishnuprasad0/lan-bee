import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// A valid 1x1 PNG.
final List<int> tinyPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA'
  '60e6kgAAAABJRU5ErkJggg==',
);

/// Writes [bytes] to [name] in a fresh temp directory removed after the test.
Future<String> writeTempFile(String name, List<int> bytes) async {
  final dir = Directory.systemTemp.createTempSync('beebeep_preview_');
  addTearDown(() => dir.deleteSync(recursive: true));
  final file = File('${dir.path}/$name');
  file.writeAsBytesSync(bytes);
  return file.path;
}
