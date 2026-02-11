import 'package:flutter/widgets.dart';

import 'filters/filters.dart';
import 'outputs/outputs.dart';
import 'printers/printers.dart';
import 'error_rendering/error_widget.dart';
import 'server_filters/filters.dart';

typedef ErrorWidgetBuilder = Widget Function(FlutterErrorDetails details);

/// The options for Logging
///
/// Use the predefined options [LoggingOptions.development]
/// or [LoggingOptions.production]
/// or create your own
class LoggingOptions {
  final ErrorWidgetBuilder? widgetErrorBuilder;
  final LoggingLogFilter filter;
  final LoggingServerFilter serverFilter;
  final LoggingLogPrinter printer;
  final LoggingLogOutput output;

  LoggingOptions({
    this.widgetErrorBuilder,
    this.filter = const LoggingDevelopmentLogFilter(),
    this.serverFilter = const LoggingDevelopmentServerFilter(),
    this.printer = const LoggingPrettyLogPrinter(),
    this.output = const LoggingConsoleLogOutput(),
  });

  /// Used for development uses pretty printer for easy overview
  LoggingOptions.development({
    this.widgetErrorBuilder,
    this.filter = const LoggingDevelopmentLogFilter(),
    this.serverFilter = const LoggingDevelopmentServerFilter(),
    this.printer = const LoggingPrettyLogPrinter(),
    this.output = const LoggingConsoleLogOutput(),
  });

  /// Used for production uses simple printer
  LoggingOptions.production({
    this.widgetErrorBuilder,
    this.filter = const LoggingProductionLogFilter(),
    this.serverFilter = const LoggingProductionServerFilter(),
    this.printer = const LoggingSimpleLogPrinter(),
    this.output = const LoggingConsoleLogOutput(),
  });

  // The default error widget builder
  static ErrorWidgetBuilder defaultErrorBuilder = (errorDetails) {
    String message = '';
    assert(() {
      message =
          '${errorDetails.exception.toString()}\nSee also: https://flutter.dev/docs/testing/errors';
      return true;
    }());
    final Object exception = errorDetails.exception;
    return LoggingErrorWidget.withDetails(
      message: message,
      error: exception is FlutterError ? exception : null,
    );
  };
}
