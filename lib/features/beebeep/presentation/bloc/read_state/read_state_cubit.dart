import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/use_cases/load_last_read_times.dart';
import '../../../domain/use_cases/save_last_read.dart';
import 'read_state.dart';

class ReadStateCubit extends Cubit<ReadState> {
  ReadStateCubit({
    required LoadLastReadTimes loadLastReadTimes,
    required SaveLastRead saveLastRead,
  }) : _loadLastReadTimes = loadLastReadTimes,
       _saveLastRead = saveLastRead,
       super(const ReadState());

  final LoadLastReadTimes _loadLastReadTimes;
  final SaveLastRead _saveLastRead;

  Future<void> load() async {
    final stored = await _loadLastReadTimes();
    // Keep anything marked read while the load was in flight.
    emit(ReadState(lastRead: {...stored, ...state.lastRead}));
  }

  /// Marks the conversation read up to [upTo] (default: now). Incoming
  /// timestamps come from the sender's clock, so callers pass the newest
  /// message time and the later of the two wins.
  void markRead(String peerId, {DateTime? upTo}) {
    final now = DateTime.now();
    final at = (upTo != null && upTo.isAfter(now)) ? upTo : now;
    final current = state.lastRead[peerId];
    if (current != null && !at.isAfter(current)) return;
    emit(ReadState(lastRead: {...state.lastRead, peerId: at}));
    unawaited(_saveLastRead(peerId, at));
  }
}
