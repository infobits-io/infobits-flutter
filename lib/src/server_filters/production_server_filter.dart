import '../log_event.dart';
import 'server_filter.dart';

/// Prints all logs with `level >= Logger.level` even in production.
class LoggingProductionServerFilter extends LoggingServerFilter {
  const LoggingProductionServerFilter({super.level = LoggingLogLevel.warning});

  @override
  bool shouldSend(LoggingLogEvent logEvent) {
    return logEvent.level.index >= level!.index;
  }
}
