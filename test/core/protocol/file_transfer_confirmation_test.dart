import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:beebeep/core/protocol/file_transfer_confirmation.dart';

void main() {
  group('encodeFileTransferConfirmation', () {
    test('proto >= 82: bytes, total, continue, space, padded with 0', () {
      final data = encodeFileTransferConfirmation(
        protocolVersion: 95,
        bytesArrived: 49152,
        totalBytesArrived: 98304,
      );

      expect(data.length % 16, 0);
      final text = utf8.decode(data);
      expect(text, startsWith('49152\u202898304\u20281\u2028 '));
      expect(
        text.substring('49152\u202898304\u20281\u2028 '.length),
        matches(RegExp(r'^0*$')),
      );
    });

    test('after the file header the confirmation carries 0 bytes', () {
      final data = encodeFileTransferConfirmation(
        protocolVersion: 95,
        bytesArrived: 0,
        totalBytesArrived: 0,
      );
      expect(utf8.decode(data), startsWith('0\u20280\u20281\u2028 '));
    });

    test('pause uses command 2', () {
      final data = encodeFileTransferConfirmation(
        protocolVersion: 95,
        bytesArrived: 0,
        totalBytesArrived: 10,
        pause: true,
      );
      expect(utf8.decode(data), startsWith('0\u202810\u20282\u2028'));
    });

    test('old protos send the count left-padded with 0 to 16 bytes', () {
      final data = encodeFileTransferConfirmation(
        protocolVersion: 70,
        bytesArrived: 1234,
        totalBytesArrived: 1234,
      );
      expect(utf8.decode(data), '0000000000001234');
    });
  });

  group('decodeFileTransferConfirmation', () {
    test('round-trips both formats', () {
      final modern = decodeFileTransferConfirmation(
        95,
        encodeFileTransferConfirmation(
          protocolVersion: 95,
          bytesArrived: 7,
          totalBytesArrived: 21,
        ),
      );
      expect(modern, (bytesArrived: 7, totalBytesArrived: 21, pause: false));

      final legacy = decodeFileTransferConfirmation(
        70,
        encodeFileTransferConfirmation(
          protocolVersion: 70,
          bytesArrived: 9,
          totalBytesArrived: 9,
        ),
      );
      expect(legacy?.bytesArrived, 9);
    });

    test('rejects data that is not a confirmation', () {
      expect(
        decodeFileTransferConfirmation(95, utf8.encode('BEE-FILE')),
        isNull,
      );
    });
  });
}
