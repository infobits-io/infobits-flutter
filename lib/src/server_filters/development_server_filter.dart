import '../log_event.dart';
import 'server_filter.dart';

/// Prints all logs with `level >= Logger.level` while in development mode (eg
/// when `assert`s are evaluated, Flutter calls this debug mode).
///
/// In release mode ALL logs are omitted.
class LoggingDevelopmentServerFilter extends LoggingServerFilter {
  const LoggingDevelopmentServerFilter({super.level = LoggingLogLevel.info});

  @override
  bool shouldSend(LoggingLogEvent logEvent) {
    var shouldSend = false;
    assert(() {
      if (logEvent.level.index >= level!.index) {
        shouldSend = true;
      }
      return true;
    }());
    return shouldSend;
  }
}
