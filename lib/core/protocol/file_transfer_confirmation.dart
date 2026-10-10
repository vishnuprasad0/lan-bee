import 'dart:convert';
import 'dart:typed_data';

import 'beebeep_constants.dart';

/// First protocol version whose bytes-arrived confirmation carries the total
/// and a pause command (file transfer resume).
const int beeBeepFileTransferResumeProtocolVersion = 82;

/// The receiver's acknowledgement in a file transfer. The sender waits for it
/// after the file header (with [bytesArrived] 0) and after every chunk before
/// sending the next chunk.
///
/// Proto >= 82: `bytes`, `total`, command (1 = continue, 2 = pause) and a
/// trailing space, joined by the data field separator. Older protos send only
/// the byte count. Either way the text is padded with '0' to a whole number
/// of cipher blocks (appended for >= 82, prepended before).
Uint8List encodeFileTransferConfirmation({
  required int protocolVersion,
  required int bytesArrived,
  required int totalBytesArrived,
  bool pause = false,
}) {
  final List<int> bytes;
  if (protocolVersion < beeBeepFileTransferResumeProtocolVersion) {
    var text = '$bytesArrived';
    while (text.length % beeBeepEncryptedDataBlockSize != 0) {
      text = '0$text';
    }
    bytes = utf8.encode(text);
  } else {
    final text = [
      '$bytesArrived',
      '$totalBytesArrived',
      pause ? '2' : '1',
      ' ',
    ].join(beeBeepDataFieldSeparator);
    final encoded = utf8.encode(text).toList();
    while (encoded.length % beeBeepEncryptedDataBlockSize != 0) {
      encoded.add(0x30); // '0'
    }
    bytes = encoded;
  }
  return Uint8List.fromList(bytes);
}

/// Parses a confirmation built by [encodeFileTransferConfirmation] (or by
/// BeeBEEP desktop). Returns null when it is not a confirmation.
({int bytesArrived, int totalBytesArrived, bool pause})?
decodeFileTransferConfirmation(int protocolVersion, Uint8List data) {
  final text = utf8.decode(data, allowMalformed: true).trim();
  if (protocolVersion < beeBeepFileTransferResumeProtocolVersion) {
    final bytes = int.tryParse(text);
    if (bytes == null) return null;
    return (bytesArrived: bytes, totalBytesArrived: -1, pause: false);
  }
  final parts = text.split(beeBeepDataFieldSeparator);
  if (parts.length < 3) return null;
  final bytes = int.tryParse(parts[0]);
  if (bytes == null) return null;
  return (
    bytesArrived: bytes,
    totalBytesArrived: int.tryParse(parts[1]) ?? -1,
    pause: int.tryParse(parts[2]) == 2,
  );
}
