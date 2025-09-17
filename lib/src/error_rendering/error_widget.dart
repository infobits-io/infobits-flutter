import 'package:flutter/widgets.dart';

import 'error_render_box.dart';

class LoggingErrorWidget extends LeafRenderObjectWidget {
  /// The message to display.
  final String message;
  final FlutterError? _flutterError;

  LoggingErrorWidget(Object exception)
      : message = _stringify(exception),
        _flutterError = exception is FlutterError ? exception : null,
        super(key: UniqueKey());

  /// Creates a widget that displays the given error message.
  ///
  /// An explicit [FlutterError] can be provided to be reported to inspection
  /// tools. It need not match the message.
  LoggingErrorWidget.withDetails({this.message = '', FlutterError? error})
      : _flutterError = error,
        super(key: UniqueKey());

  static String _stringify(Object? exception) {
    try {
      return exception.toString();
    } catch (error) {
      // If we get here, it means things have really gone off the rails, and we're better
      // off just returning a simple string and letting the developer find out what the
      // root cause of all their problems are by looking at the console logs.
    }
    return 'Error';
  }

  @override
  RenderBox createRenderObject(BuildContext context) =>
      LoggingRenderErrorBox(message, _flutterError);
}
