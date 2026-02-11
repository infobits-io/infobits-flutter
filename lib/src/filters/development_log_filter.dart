import '../log_event.dart';
import 'log_filter.dart';

/// Prints all logs with `level >= Logger.level` while in development mode (eg
/// when `assert`s are evaluated, Flutter calls this debug mode).
///
/// In release mode ALL logs are omitted.
class LoggingDevelopmentLogFilter extends LoggingLogFilter {
  const LoggingDevelopmentLogFilter({super.level = LoggingLogLevel.verbose});

  @override
  bool shouldLog(LoggingLogEvent logEvent) {
    var shouldLog = false;
    assert(() {
      if (logEvent.level.index >= level!.index) {
        shouldLog = true;
      }
      return true;
    }());
    return shouldLog;
  }
}
