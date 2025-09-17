import '../../src/log_event.dart';

/// Mock implementation of Logger for testing
class MockLogger {
  /// List of all logged messages
  final List<LogEntry> logs = [];

  /// Log at verbose level
  void verbose(
    dynamic message, {
    dynamic exception,
    String? information,
    Map<String, dynamic>? metadata,
  }) {
    logs.add(
      LogEntry(
        level: LoggingLogLevel.verbose,
        message: message,
        exception: exception,
        information: information,
        metadata: metadata,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Log at debug level
  void debug(
    dynamic message, {
    dynamic exception,
    String? information,
    Map<String, dynamic>? metadata,
  }) {
    logs.add(
      LogEntry(
        level: LoggingLogLevel.debug,
        message: message,
        exception: exception,
        information: information,
        metadata: metadata,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Log at info level
  void info(
    dynamic message, {
    dynamic exception,
    String? information,
    Map<String, dynamic>? metadata,
  }) {
    logs.add(
      LogEntry(
        level: LoggingLogLevel.info,
        message: message,
        exception: exception,
        information: information,
        metadata: metadata,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Log at warning level
  void warn(
    dynamic message, {
    dynamic exception,
    String? information,
    Map<String, dynamic>? metadata,
  }) {
    logs.add(
      LogEntry(
        level: LoggingLogLevel.warning,
        message: message,
        exception: exception,
        information: information,
        metadata: metadata,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Log at error level
  void error(
    dynamic message, {
    dynamic exception,
    String? information,
    Map<String, dynamic>? metadata,
  }) {
    logs.add(
      LogEntry(
        level: LoggingLogLevel.error,
        message: message,
        exception: exception,
        information: information,
        metadata: metadata,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Log at fatal level
  void fatal(
    dynamic message, {
    dynamic exception,
    String? information,
    Map<String, dynamic>? metadata,
  }) {
    logs.add(
      LogEntry(
        level: LoggingLogLevel.fatal,
        message: message,
        exception: exception,
        information: information,
        metadata: metadata,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Clear all logs
  void clear() {
    logs.clear();
  }

  /// Get logs by level
  List<LogEntry> getLogsByLevel(LoggingLogLevel level) {
    return logs.where((log) => log.level == level).toList();
  }

  /// Get error logs
  List<LogEntry> get errorLogs => getLogsByLevel(LoggingLogLevel.error);

  /// Get warning logs
  List<LogEntry> get warningLogs => getLogsByLevel(LoggingLogLevel.warning);

  /// Get info logs
  List<LogEntry> get infoLogs => getLogsByLevel(LoggingLogLevel.info);

  /// Get debug logs
  List<LogEntry> get debugLogs => getLogsByLevel(LoggingLogLevel.debug);

  /// Check if any errors were logged
  bool get hasErrors => errorLogs.isNotEmpty;

  /// Check if any warnings were logged
  bool get hasWarnings => warningLogs.isNotEmpty;

  /// Get the last log entry
  LogEntry? get lastLog => logs.isEmpty ? null : logs.last;

  /// Check if a message was logged
  bool wasMessageLogged(String message) {
    return logs.any((log) => log.message.toString().contains(message));
  }
}

/// Represents a log entry
class LogEntry {
  final LoggingLogLevel level;
  final dynamic message;
  final dynamic exception;
  final String? information;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  LogEntry({
    required this.level,
    required this.message,
    this.exception,
    this.information,
    this.metadata,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'LogEntry(level: $level, message: $message, timestamp: $timestamp)';
  }
}
