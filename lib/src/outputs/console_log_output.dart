import '../log_output.dart';
import 'log_output.dart';

/// Default implementation of [LoggingLogOutput].
///
/// It sends everything to the system console.
class LoggingConsoleLogOutput extends LoggingLogOutput {
  const LoggingConsoleLogOutput();

  @override
  void output(LoggingOutputLog output) {
    // ignore: avoid_print
    output.lines.forEach(print);
  }
}
