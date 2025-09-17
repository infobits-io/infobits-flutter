import '../log_event.dart';

/// An abstract handler of log events.
///
/// A log printer creates and formats the output, which is then sent to
/// [LoggingOutputLog].
///
/// You can implement a `LoggingLogPrinter` from scratch or extend [LoggingPrettyLogPrinter].
abstract class LoggingLogPrinter {
  const LoggingLogPrinter();

  void init() {}

  /// Is called every time a new [LoggingLogEvent] is sent and handles printing or
  /// storing the message.
  List<String> log(LoggingLogEvent logEvent);

  void destroy() {}
}
