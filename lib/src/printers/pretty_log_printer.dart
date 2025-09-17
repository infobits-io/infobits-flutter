import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';

import '../ansi_color.dart';
import '../log_event.dart';
import '../trace.dart';
import '../utils.dart';
import 'log_printer.dart';

/// Default implementation of [LoggingLogPrinter].
///
/// Output looks like this:
/// ```
/// ┌──────────────────────────
/// │ Error info
/// ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
/// │ Method stack history
/// ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
/// │ Log message
/// └──────────────────────────
/// ```
class LoggingPrettyLogPrinter extends LoggingLogPrinter {
  static const topLeftCorner = '┌';
  static const bottomLeftCorner = '└';
  static const middleCorner = '├';
  static const verticalLine = '│';
  static const doubleDivider = '─';
  static const singleDivider = '┄';

  static final levelColors = {
    LoggingLogLevel.verbose: AnsiColor.fg(AnsiColor.grey(0.5)),
    LoggingLogLevel.debug: AnsiColor.fg(null),
    LoggingLogLevel.info: AnsiColor.fg(12),
    LoggingLogLevel.warning: AnsiColor.fg(208),
    LoggingLogLevel.error: AnsiColor.fg(196),
    LoggingLogLevel.fatal: AnsiColor.fg(199),
  };

  static final levelEmojis = {
    LoggingLogLevel.verbose: '',
    LoggingLogLevel.debug: '🐛 ',
    LoggingLogLevel.info: '💡 ',
    LoggingLogLevel.warning: '⚠️ ',
    LoggingLogLevel.error: '⛔ ',
    LoggingLogLevel.fatal: '💀 ',
  };

  static DateTime? _startTime;

  /// The index which to begin the stack trace at
  ///
  /// This can be useful if, for instance, Logger is wrapped in another class and
  /// you wish to remove these wrapped calls from stack trace
  final int stackTraceBeginIndex;
  final int methodCount;
  final int errorMethodCount;
  final int lineLength;
  final bool colors;
  final bool printEmojis;
  final bool printTime;

  /// To prevent ascii 'boxing' of any log [Level] include the level in map for excludeBox,
  /// for example to prevent boxing of [Level.verbose] and [Level.info] use excludeBox:{Level.verbose:true, Level.info:true}
  final Map<LoggingLogLevel, bool> excludeBox;

  /// To make the default for every level to prevent boxing entirely set [noBoxingByDefault] to true
  /// (boxing can still be turned on for some levels by using something like excludeBox:{Level.error:false} )
  final bool noBoxingByDefault;

  /// Whether to print log location to the right of the message
  final bool showLogLocation;

  const LoggingPrettyLogPrinter({
    this.stackTraceBeginIndex = 0,
    this.methodCount = 0,
    this.errorMethodCount = 8,
    this.lineLength = 80,
    this.colors = true,
    this.printEmojis = true,
    this.printTime = false,
    this.excludeBox = const {},
    this.noBoxingByDefault = false,
    this.showLogLocation = true,
  });

  @override
  void init() {
    _startTime ??= DateTime.now();

    // Translate excludeBox map (constant if default) to includeBox map with all Level enum possibilities
    // logging.LogLevel.values.forEach((l) => includeBox[l] = !noBoxingByDefault);
    // excludeBox.forEach((k, v) => includeBox[k] = !v);
    super.init();
  }

  @override
  List<String> log(LoggingLogEvent logEvent) {
    String? stackTraceStr;
    if (logEvent.stackTrace == null || logEvent.stackTrace!.isEmpty) {
      if (methodCount > 0) {
        stackTraceStr = formatStackTrace(
            getStackTraceElements(StackTrace.current), methodCount);
      }
    } else if (errorMethodCount > 0) {
      stackTraceStr = formatStackTrace(logEvent.stackTrace!, errorMethodCount);
    }

    String? errString = logEvent.exception == null || logEvent.exception == ""
        ? null
        : logEvent.exception.toString();

    String? timeStr;
    if (printTime) {
      timeStr = getTime();
    }

    String messageString = formatMessage(logEvent.message);

    if (logEvent.information != null && logEvent.information!.trim() != "") {
      messageString += "\n\n${logEvent.information}";
    }

    return _formatAndPrint(
      logEvent.level,
      messageString,
      timeStr,
      errString,
      stackTraceStr,
    );
  }

  String formatMessage(dynamic message) {
    var messageTitle = "";
    messageTitle += message.runtimeType.toString();

    if (message is Map || message is Iterable) {
      const encoder = JsonEncoder.withIndent('  ', toEncodableFallback);
      final encodedString = encoder.convert(message);
      return "$messageTitle\n$encodedString";
    } else if (message is Widget) {
      final widgetString = formatWidget(message.toString());
      return "$messageTitle widget\n$widgetString";
    } else {
      return message.toString();
    }
  }

  String formatWidget(String widgetString, [int depth = 0]) {
    String finalString = "";
    RegExp bodyMatch = RegExp(r"\((.*)\)");
    var body = bodyMatch.firstMatch(widgetString.trim().replaceAll("\n", ""));
    if (body != null) {
      finalString +=
          "${"".padLeft(depth * 2)}${widgetString.split("(")[0].trim()}(";
      var bodyString = body[1];
      if (bodyString != null) {
        var fieldvars = bodyString.split(",");
        if (fieldvars.length == 1) {
          finalString +=
              "${formatWidget(fieldvars[0].trim(), depth + 1).trim()})";
        } else {
          finalString += "\n";
          for (var fieldvar in fieldvars) {
            finalString +=
                "${"".padLeft(depth * 2 + 2)}${formatWidget(fieldvar, depth + 1).trim()},\n";
          }
          finalString += "${"".padLeft(depth * 2)})";
        }
      } else {
        return widgetString;
      }
    } else {
      return widgetString;
    }
    return finalString;
  }

  String? formatStackTrace(List<LoggingTrace> stackTrace, int methodCount) {
    if (stackTraceBeginIndex > 0 &&
        stackTraceBeginIndex < stackTrace.length - 1) {
      stackTrace = stackTrace.sublist(stackTraceBeginIndex);
    }

    // Find largest class method string
    int classMethodLength = 25;
    int count1 = 0;
    for (var line in stackTrace) {
      if (_discardDeviceStacktraceLine(line.file) ||
          _discardWebStacktraceLine(line.file) ||
          _discardBrowserStacktraceLine(line.file)) {
        continue;
      }

      String classMethod =
          "${line.className == "" ? "" : "${line.className}."}${line.method}";

      classMethodLength = max(classMethodLength, classMethod.length);

      if (++count1 == methodCount) {
        break;
      }
    }

    var formatted = <String>[];
    var count = 0;
    for (var line in stackTrace) {
      if (_discardDeviceStacktraceLine(line.file) ||
          _discardWebStacktraceLine(line.file) ||
          _discardBrowserStacktraceLine(line.file)) {
        continue;
      }

      String classMethod =
          "${line.className == "" ? "" : "${line.className}."}${line.method}";

      formatted.add(
          '#${count.toString().padRight(2)}  ${classMethod.padRight(classMethodLength)}   (${line.file}:${line.line}:${line.column}) ');
      if (++count == methodCount) {
        break;
      }
    }

    if (formatted.isEmpty) {
      return null;
    } else {
      return formatted.join('\n');
    }
  }

  String? getLogLocation() {
    final stackTrace = getStackTraceElements(StackTrace.current);
    for (var line in stackTrace) {
      if (_discardDeviceStacktraceLine(line.file) ||
          _discardWebStacktraceLine(line.file) ||
          _discardBrowserStacktraceLine(line.file)) {
        continue;
      }

      return "(${line.file}:${line.line}:${line.column})";
    }
    return null;
  }

  bool _discardDeviceStacktraceLine(String file) {
    return file.startsWith('package:logging');
  }

  bool _discardWebStacktraceLine(String file) {
    return file.startsWith('packages/logging') ||
        file.startsWith('dart-sdk/lib');
  }

  bool _discardBrowserStacktraceLine(String file) {
    return file.startsWith('package:logging') || file.startsWith('dart:');
  }

  String getTime() {
    String threeDigits(int n) {
      if (n >= 100) return '$n';
      if (n >= 10) return '0$n';
      return '00$n';
    }

    String twoDigits(int n) {
      if (n >= 10) return '$n';
      return '0$n';
    }

    var now = DateTime.now();
    var h = twoDigits(now.hour);
    var min = twoDigits(now.minute);
    var sec = twoDigits(now.second);
    var ms = threeDigits(now.millisecond);
    var timeSinceStart = now.difference(_startTime!).toString();
    return '$h:$min:$sec.$ms (+$timeSinceStart)';
  }

  AnsiColor _getLevelColor(LoggingLogLevel level) {
    if (colors) {
      return levelColors[level]!;
    } else {
      return AnsiColor.none();
    }
  }

  AnsiColor _getErrorColor(LoggingLogLevel level) {
    if (colors) {
      if (level == LoggingLogLevel.fatal) {
        return levelColors[LoggingLogLevel.fatal]!;
      } else {
        return levelColors[LoggingLogLevel.error]!;
      }
    } else {
      return AnsiColor.none();
    }
  }

  String _getEmoji(LoggingLogLevel level) {
    if (printEmojis) {
      return levelEmojis[level]!;
    } else {
      return '';
    }
  }

  List<String> _formatAndPrint(
    LoggingLogLevel level,
    String message,
    String? time,
    String? error,
    String? stacktrace,
  ) {
    bool includeBox = excludeBox.containsKey(level) ? excludeBox[level]! : true;

    var doubleDividerLine = StringBuffer();
    var singleDividerLine = StringBuffer();
    for (var i = 0; i < lineLength - 1; i++) {
      doubleDividerLine.write(doubleDivider);
      singleDividerLine.write(singleDivider);
    }

    String borderTop = '$topLeftCorner$doubleDividerLine';
    String borderMiddle = '$middleCorner$singleDividerLine';
    String borderBottom =
        '$bottomLeftCorner$doubleDividerLine${AnsiColor.ansiDefault}';

    // This code is non trivial and a type annotation here helps understanding.
    // ignore: omit_local_variable_types
    List<String> buffer = [];
    var verticalLineAtLevel = includeBox ? ('$verticalLine ') : '';
    var color = _getLevelColor(level);
    if (includeBox) buffer.add(color(borderTop));

    if (error != null) {
      var errorColor = _getErrorColor(level);
      for (var line in error.split('\n')) {
        buffer.add(
          color(verticalLineAtLevel) +
              errorColor.resetForeground +
              errorColor(line) +
              errorColor.resetBackground,
        );
      }
      if (includeBox) {
        buffer.add(color(borderMiddle));
      }
    }

    if (stacktrace != null) {
      for (var line in stacktrace.split('\n')) {
        buffer.add(color('$verticalLineAtLevel$line'));
      }
      if (includeBox) {
        buffer.add(color(borderMiddle));
      }
    }

    if (time != null) {
      buffer.add(color('$verticalLineAtLevel$time'));
      if (includeBox) {
        buffer.add(color(borderMiddle));
      }
    }

    var emoji = _getEmoji(level);
    var messageLines = message.split('\n');
    for (var i = 0; i < messageLines.length; i++) {
      var line = messageLines[i];
      var prefix = i == 0 ? emoji : "".padLeft(emoji.length);
      var location = "";
      if (showLogLocation &&
          error == null &&
          i == (messageLines.length / 2).floor()) {
        final stringLocation = getLogLocation();
        final fullString = '$verticalLineAtLevel$prefix$line$stringLocation';
        final int lengthDiff = lineLength - fullString.length;
        final int spacerCount = lengthDiff > 5 ? lengthDiff : 6;
        location = "${" " * spacerCount}$stringLocation";
      }
      buffer.add(color('$verticalLineAtLevel$prefix$line$location'));
    }
    if (includeBox) {
      buffer.add(color(borderBottom));
    }

    return buffer;
  }
}
