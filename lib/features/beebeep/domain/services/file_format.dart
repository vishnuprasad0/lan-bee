/// Broad file categories used for icons.
enum FileKind { pdf, image, audio, archive, generic }

const Set<String> _imageExtensions = {
  'jpg',
  'jpeg',
  'png',
  'gif',
  'webp',
  'bmp',
  'heic',
  'svg',
};

const Set<String> _audioExtensions = {
  'mp3',
  'aac',
  'm4a',
  'wav',
  'ogg',
  'opus',
  'flac',
  'amr',
};

const Set<String> _archiveExtensions = {
  'zip',
  'rar',
  '7z',
  'tar',
  'gz',
  'tgz',
  'bz2',
  'xz',
};

/// Category of a file from its name's extension (case-insensitive).
FileKind fileKindOf(String? fileName) {
  if (fileName == null) return FileKind.generic;
  final dot = fileName.lastIndexOf('.');
  if (dot < 0 || dot == fileName.length - 1) return FileKind.generic;
  final ext = fileName.substring(dot + 1).toLowerCase();
  if (ext == 'pdf') return FileKind.pdf;
  if (_imageExtensions.contains(ext)) return FileKind.image;
  if (_audioExtensions.contains(ext)) return FileKind.audio;
  if (_archiveExtensions.contains(ext)) return FileKind.archive;
  return FileKind.generic;
}

/// `512 B`, `1.5 KB`, `2.0 MB`, `1.2 GB`.
String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}

/// `m:ss`, for voice notes and the recording timer.
String formatDuration(Duration duration) {
  final seconds = duration.inSeconds % 60;
  return '${duration.inMinutes}:${seconds.toString().padLeft(2, '0')}';
}
