import 'trace.dart';

/// The different log event levels
enum LoggingLogLevel { verbose, debug, info, warning, error, fatal }

/// Log event contains all the information of a log event
class LoggingLogEvent {
  final LoggingLogLevel level;
  final dynamic message;
  final dynamic exception;
  final String? information;
  final List<LoggingTrace>? stackTrace;
  final Map<String, dynamic>? metadata;
  final DateTime loggedAt = DateTime.now();

  LoggingLogEvent({
    required this.level,
    required this.message,
    this.exception,
    this.information,
    this.stackTrace,
    this.metadata,
  });
}
