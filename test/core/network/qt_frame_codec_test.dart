import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:beebeep/core/network/qt_frame_codec.dart';

void main() {
  final payload = Uint8List.fromList(List<int>.generate(400, (i) => i % 251));
  group('AdaptiveQtFrameCodec', () {
    test('detects a 16-bit framed HELLO when no prefix is preset', () {
      final codec = AdaptiveQtFrameCodec()
        ..addChunk(QtFrameCodec().encodeFrame16(payload));
      final frames = codec.takeFrames();
      expect(frames, hasLength(1));
      expect(frames.single, payload);
      expect(codec.prefix, QtFramePrefix.u16be);
    });
    test('cannot read a 16-bit framed HELLO when 32-bit is preset', () {
      // Regression: file transfer preset u32 before HELLO and never saw the
      // desktop's HELLO ("missing HELLO").
      final codec = AdaptiveQtFrameCodec()
        ..setPrefix(QtFramePrefix.u32be)
        ..addChunk(QtFrameCodec().encodeFrame16(payload));
      expect(codec.takeFrames(), isEmpty);
    });
    test('reads 32-bit frames after switching post-HELLO', () {
      final codec = AdaptiveQtFrameCodec()
        ..addChunk(QtFrameCodec().encodeFrame16(payload));
      expect(codec.takeFrames(), hasLength(1));
      codec
        ..setPrefix(QtFramePrefix.u32be)
        ..addChunk(QtFrameCodec().encodeFrame(payload))
        ..addChunk(QtFrameCodec().encodeFrame(payload));
      expect(codec.takeFrames(), hasLength(2));
    });
    test('HELLO frame header is a 16-bit block size', () {
      final frame = QtFrameCodec().encodeFrame16(payload);
      // 0x0194 = 4 + 400, then 0x00000190 = 400, as seen on the wire.
      expect(frame.sublist(0, 6), [0x01, 0x94, 0x00, 0x00, 0x01, 0x90]);
    });
  });
}
