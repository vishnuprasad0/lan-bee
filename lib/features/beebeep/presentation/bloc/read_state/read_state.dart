import 'package:equatable/equatable.dart';

/// Last-read time per peer id; drives unread counts.
class ReadState extends Equatable {
  const ReadState({this.lastRead = const {}});

  final Map<String, DateTime> lastRead;

  @override
  List<Object?> get props => [lastRead];
}
