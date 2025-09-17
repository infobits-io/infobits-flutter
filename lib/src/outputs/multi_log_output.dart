import '../log_output.dart';
import 'log_output.dart';

/// Logs simultaneously to multiple [LoggingLogOutput] outputs.
class MultiOutput extends LoggingLogOutput {
  late List<LoggingLogOutput> _outputs;

  MultiOutput(List<LoggingLogOutput?>? outputs) {
    _outputs = _normalizeOutputs(outputs);
  }
  List<LoggingLogOutput> _normalizeOutputs(List<LoggingLogOutput?>? outputs) {
    final normalizedOutputs = <LoggingLogOutput>[];

    if (outputs != null) {
      for (final output in outputs) {
        if (output != null) {
          normalizedOutputs.add(output);
        }
      }
    }

    return normalizedOutputs;
  }

  @override
  void init() {
    for (var o in _outputs) {
      o.init();
    }
  }

  @override
  void output(LoggingOutputLog output) {
    for (var o in _outputs) {
      o.output(output);
    }
  }

  @override
  void destroy() {
    for (var o in _outputs) {
      o.destroy();
    }
  }
}
