import '../log_event.dart';
import 'log_filter.dart';

/// Prints all logs with `level >= Logger.level` even in production.
class LoggingProductionLogFilter extends LoggingLogFilter {
  const LoggingProductionLogFilter({super.level = LoggingLogLevel.info});

  @override
  bool shouldLog(LoggingLogEvent logEvent) {
    return logEvent.level.index >= level!.index;
  }
}
