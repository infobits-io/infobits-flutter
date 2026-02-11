import 'dart:collection';

import '../log_output.dart';
import 'log_output.dart';

/// Buffers [OutputEvent]s.
class LoggingMemoryOutput extends LoggingLogOutput {
  /// Maximum events in [buffer].
  final int bufferSize;

  /// A secondary [LoggingLogOutput] to also received events.
  final LoggingLogOutput? secondOutput;

  /// The buffer of events.
  final ListQueue<LoggingOutputLog> buffer;

  LoggingMemoryOutput({this.bufferSize = 20, this.secondOutput})
    : buffer = ListQueue(bufferSize);

  @override
  void output(LoggingOutputLog output) {
    if (buffer.length == bufferSize) {
      buffer.removeFirst();
    }

    buffer.add(output);

    secondOutput?.output(output);
  }
}
