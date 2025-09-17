import '../log_output.dart';

/// Log output receives a [LoggingOutputLog] from [LogPrinter] and sends it to the
/// desired destination.
///
/// This can be an output stream, a file or a network target. [LoggingLogOutput] may
/// cache multiple log messages.
abstract class LoggingLogOutput {
  const LoggingLogOutput();

  void init() {}

  void output(LoggingOutputLog output);

  void destroy() {}
}
