import 'package:flutter_test/flutter_test.dart';
import 'package:beebeep/features/beebeep/domain/services/preview_kind.dart';

void main() {
  group('previewKindFor', () {
    test('maps every extension of each kind', () {
      const table = <PreviewKind, List<String>>{
        PreviewKind.image: ['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp'],
        PreviewKind.svg: ['svg'],
        PreviewKind.text: [
          'txt', 'md', 'log', 'csv', 'json', 'xml', 'yaml', 'yml', 'ini', //
          'conf', 'html', 'htm', 'css', 'js', 'ts', 'dart', 'java', 'kt',
          'swift', 'c', 'h', 'cpp', 'py', 'sh', 'sql', 'properties',
        ],
        PreviewKind.audio: ['mp3', 'm4a', 'aac', 'wav', 'ogg', 'opus', 'flac'],
        PreviewKind.video: ['mp4', 'mov', 'm4v', 'webm', '3gp', 'mkv'],
      };
      table.forEach((kind, extensions) {
        for (final ext in extensions) {
          expect(previewKindFor('file.$ext'), kind, reason: ext);
        }
      });
    });
    test('is case-insensitive', () {
      expect(previewKindFor('PHOTO.JPG'), PreviewKind.image);
      expect(previewKindFor('Logo.SvG'), PreviewKind.svg);
      expect(previewKindFor('Notes.TXT'), PreviewKind.text);
      expect(previewKindFor('Doc.Pdf'), PreviewKind.none);
    });
    test('uses the last extension of a dotted name', () {
      expect(previewKindFor('archive.tar.txt'), PreviewKind.text);
      expect(previewKindFor('a.png.zip'), PreviewKind.none);
    });
    test('unknown, missing, or empty extension is none', () {
      expect(previewKindFor('setup.exe'), PreviewKind.none);
      expect(previewKindFor('README'), PreviewKind.none);
      expect(previewKindFor('trailing.'), PreviewKind.none);
      expect(previewKindFor(null), PreviewKind.none);
      expect(previewKindFor(''), PreviewKind.none);
    });
    test('hasThumbnail covers image and svg only', () {
      expect(hasThumbnail(PreviewKind.image), isTrue);
      expect(hasThumbnail(PreviewKind.svg), isTrue);
    });
  });
}
