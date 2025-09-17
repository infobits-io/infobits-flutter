import 'log_event.dart';

/// Output log contains the level and lines of a log event
class LoggingOutputLog {
  final LoggingLogLevel level;
  final List<String> lines;

  LoggingOutputLog(this.level, this.lines);
}
