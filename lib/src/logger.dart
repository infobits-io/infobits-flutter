import 'log_event.dart';
import 'logging.dart';

class Logger {
  /// Log at verbose level
  ///
  /// [message] A descriptive message
  /// [metadata] Additional structured data to include with the log
  static void verbose(
    dynamic message, {
    dynamic exception,
    String? information,
    Map<String, dynamic>? metadata,
  }) {
    InfobitsLogging.instance.recordLog(
      LoggingLogLevel.verbose,
      message,
      exception: exception,
      information: information,
      metadata: metadata,
    );
  }

  /// Log at debug level
  ///
  /// [message] A descriptive message
  /// [metadata] Additional structured data to include with the log
  static void debug(
    dynamic message, {
    dynamic exception,
    String? information,
    Map<String, dynamic>? metadata,
  }) {
    InfobitsLogging.instance.recordLog(
      LoggingLogLevel.debug,
      message,
      exception: exception,
      information: information,
      metadata: metadata,
    );
  }

  /// Log at info level
  ///
  /// [message] A descriptive message
  /// [metadata] Additional structured data to include with the log
  static void info(
    dynamic message, {
    dynamic exception,
    String? information,
    Map<String, dynamic>? metadata,
  }) {
    InfobitsLogging.instance.recordLog(
      LoggingLogLevel.info,
      message,
      exception: exception,
      information: information,
      metadata: metadata,
    );
  }

  /// Log at warn level
  ///
  /// [message] A descriptive message
  /// [metadata] Additional structured data to include with the log
  static void warn(
    dynamic message, {
    dynamic exception,
    String? information,
    Map<String, dynamic>? metadata,
  }) {
    InfobitsLogging.instance.recordLog(
      LoggingLogLevel.warning,
      message,
      exception: exception,
      information: information,
      metadata: metadata,
    );
  }

  /// Log at error level
  ///
  /// [message] A descriptive message
  /// [metadata] Additional structured data to include with the log
  static void error(
    dynamic message, {
    dynamic exception,
    String? information,
    Map<String, dynamic>? metadata,
  }) {
    InfobitsLogging.instance.recordLog(
      LoggingLogLevel.error,
      message,
      exception: exception,
      information: information,
      metadata: metadata,
    );
  }

  /// Log at fatal level
  ///
  /// [message] A descriptive message
  /// [metadata] Additional structured data to include with the log
  static void fatal(
    dynamic message, {
    dynamic exception,
    String? information,
    Map<String, dynamic>? metadata,
  }) {
    InfobitsLogging.instance.recordLog(
      LoggingLogLevel.fatal,
      message,
      exception: exception,
      information: information,
      metadata: metadata,
    );
  }
}
