import 'dart:async';

import '../log_output.dart';
import 'log_output.dart';

class LoggingStreamLogOutput extends LoggingLogOutput {
  late StreamController<List<String>> _controller;
  bool _shouldForward = false;

  LoggingStreamLogOutput() {
    _controller = StreamController<List<String>>(
      onListen: () => _shouldForward = true,
      onPause: () => _shouldForward = false,
      onResume: () => _shouldForward = true,
      onCancel: () => _shouldForward = false,
    );
  }

  Stream<List<String>> get stream => _controller.stream;

  @override
  void output(LoggingOutputLog output) {
    if (!_shouldForward) {
      return;
    }

    _controller.add(output.lines);
  }

  @override
  void destroy() {
    _controller.close();
  }
}
