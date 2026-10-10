/// How a file can be previewed inside the app.
/// PDF has no in-app viewer (a PDF engine adds ~5 MB per device); it opens
/// in another app like any other [PreviewKind.none] file.
enum PreviewKind { image, svg, text, audio, video, none }

const Set<String> _imageExtensions = {
  'png',
  'jpg',
  'jpeg',
  'gif',
  'webp',
  'bmp',
};
const Set<String> _textExtensions = {
  'txt',
  'md',
  'log',
  'csv',
  'json',
  'xml',
  'yaml',
  'yml',
  'ini',
  'conf',
  'html',
  'htm',
  'css',
  'js',
  'ts',
  'dart',
  'java',
  'kt',
  'swift',
  'c',
  'h',
  'cpp',
  'py',
  'sh',
  'sql',
  'properties',
};
const Set<String> _audioExtensions = {
  'mp3',
  'm4a',
  'aac',
  'wav',
  'ogg',
  'opus',
  'flac',
};
const Set<String> _videoExtensions = {
  'mp4',
  'mov',
  'm4v',
  'webm',
  '3gp',
  'mkv',
};

/// Preview category of a file from its name's extension (case-insensitive).
PreviewKind previewKindFor(String? fileName) {
  if (fileName == null) return PreviewKind.none;
  final dot = fileName.lastIndexOf('.');
  if (dot < 0 || dot == fileName.length - 1) return PreviewKind.none;
  final ext = fileName.substring(dot + 1).toLowerCase();
  if (_imageExtensions.contains(ext)) return PreviewKind.image;
  if (ext == 'svg') return PreviewKind.svg;
  if (_textExtensions.contains(ext)) return PreviewKind.text;
  if (_audioExtensions.contains(ext)) return PreviewKind.audio;
  if (_videoExtensions.contains(ext)) return PreviewKind.video;
  return PreviewKind.none;
}

/// True for kinds shown as a thumbnail (bubble, Files tab).
bool hasThumbnail(PreviewKind kind) =>
    kind == PreviewKind.image || kind == PreviewKind.svg;
