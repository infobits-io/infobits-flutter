import '../ansi_color.dart';
import '../log_event.dart';
import 'log_printer.dart';

/// Outputs simple log messages:
/// ```
/// [ERROR] Log message  ERROR: Error info
/// ```
class LoggingSimpleLogPrinter extends LoggingLogPrinter {
  static final levelPrefixes = {
    LoggingLogLevel.verbose: '[VERBOSE]',
    LoggingLogLevel.debug: '[DEBUG]',
    LoggingLogLevel.info: '[INFO]',
    LoggingLogLevel.warning: '[WARNING]',
    LoggingLogLevel.error: '[ERROR]',
    LoggingLogLevel.fatal: '[FATAL]',
  };

  static final levelColors = {
    LoggingLogLevel.verbose: AnsiColor.fg(AnsiColor.grey(0.5)),
    LoggingLogLevel.debug: AnsiColor.fg(null),
    LoggingLogLevel.info: AnsiColor.fg(12),
    LoggingLogLevel.warning: AnsiColor.fg(208),
    LoggingLogLevel.error: AnsiColor.fg(196),
    LoggingLogLevel.fatal: AnsiColor.fg(199),
  };

  final bool printTime;
  final bool colors;

  const LoggingSimpleLogPrinter({this.printTime = false, this.colors = true});

  @override
  List<String> log(LoggingLogEvent logEvent) {
    var errorStr = logEvent.exception != null && logEvent.exception != ""
        ? '  ERROR: ${logEvent.exception}'
        : '';
    var timeStr = printTime ? 'TIME: ${DateTime.now().toIso8601String()}' : '';
    return [
      '${_labelFor(logEvent.level)} $timeStr ${logEvent.message}$errorStr',
    ];
  }

  String _labelFor(LoggingLogLevel level) {
    var prefix = levelPrefixes[level]!;
    var color = levelColors[level]!;

    return colors ? color(prefix) : prefix;
  }
}
