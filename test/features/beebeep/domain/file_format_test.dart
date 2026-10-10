import 'package:flutter_test/flutter_test.dart';

import 'package:beebeep/features/beebeep/domain/services/file_format.dart';

void main() {
  test('fileKindOf maps extensions case-insensitively', () {
    expect(fileKindOf('a.PDF'), FileKind.pdf);
    expect(fileKindOf('photo.jpeg'), FileKind.image);
    expect(fileKindOf('song.mp3'), FileKind.audio);
    expect(fileKindOf('bundle.tar'), FileKind.archive);
    expect(fileKindOf('notes.txt'), FileKind.generic);
    expect(fileKindOf('noextension'), FileKind.generic);
    expect(fileKindOf('trailingdot.'), FileKind.generic);
    expect(fileKindOf(null), FileKind.generic);
  });

  test('formatFileSize', () {
    expect(formatFileSize(512), '512 B');
    expect(formatFileSize(1536), '1.5 KB');
    expect(formatFileSize(2 * 1024 * 1024), '2.0 MB');
    expect(formatFileSize(3 * 1024 * 1024 * 1024), '3.0 GB');
  });

  test('formatDuration', () {
    expect(formatDuration(const Duration(seconds: 7)), '0:07');
    expect(formatDuration(const Duration(minutes: 2, seconds: 5)), '2:05');
  });
}
