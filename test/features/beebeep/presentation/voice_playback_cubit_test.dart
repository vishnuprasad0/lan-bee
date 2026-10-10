import 'package:flutter_test/flutter_test.dart';

import 'package:beebeep/features/beebeep/presentation/bloc/voice_playback/voice_playback_cubit.dart';

import '../../../support/test_harness.dart';

void main() {
  test('only one voice note plays at a time', () async {
    final player = FakeVoicePlayer();
    final cubit = VoicePlaybackCubit(player);
    addTearDown(cubit.close);

    await cubit.toggle('a', '/a.aac', total: const Duration(seconds: 5));
    expect(cubit.state.messageId, 'a');
    expect(cubit.state.isPlaying, isTrue);

    await cubit.toggle('b', '/b.aac');
    expect(cubit.state.messageId, 'b');
    expect(cubit.state.isPlaying, isTrue);
    expect(cubit.state.position, Duration.zero);
    expect(player.played, ['/a.aac', '/b.aac']);
  });

  test('toggle on the current note pauses it', () async {
    final cubit = VoicePlaybackCubit(FakeVoicePlayer());
    addTearDown(cubit.close);

    await cubit.toggle('a', '/a.aac');
    await cubit.toggle('a', '/a.aac');
    expect(cubit.state.messageId, 'a');
    expect(cubit.state.isPlaying, isFalse);
  });

  test('position updates and completion reset the note', () async {
    final player = FakeVoicePlayer();
    final cubit = VoicePlaybackCubit(player);
    addTearDown(cubit.close);

    await cubit.toggle('a', '/a.aac', total: const Duration(seconds: 5));
    player.position.add(const Duration(seconds: 2));
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.position, const Duration(seconds: 2));

    player.complete.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.isPlaying, isFalse);
    expect(cubit.state.position, Duration.zero);
  });

  test('stopIfPlaying clears the deleted note only', () async {
    final cubit = VoicePlaybackCubit(FakeVoicePlayer());
    addTearDown(cubit.close);

    await cubit.toggle('a', '/a.aac');
    await cubit.stopIfPlaying(['other']);
    expect(cubit.state.messageId, 'a');
    await cubit.stopIfPlaying(['a']);
    expect(cubit.state.messageId, isNull);
  });
}
