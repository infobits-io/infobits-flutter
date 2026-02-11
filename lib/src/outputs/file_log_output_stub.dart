// Stub implementation for web/WASM compatibility
import 'dart:convert';
import '../log_output.dart';
import 'log_output.dart';

class LoggingFileLogOutput extends LoggingLogOutput {
  final dynamic file;
  final bool overrideExisting;
  final Encoding encoding;

  LoggingFileLogOutput({
    required this.file,
    this.overrideExisting = false,
    this.encoding = utf8,
  });

  @override
  void init() {
    // No-op for web platform
  }

  @override
  void output(LoggingOutputLog output) {
    // No-op for web platform - file operations not available
    // Could potentially use localStorage or IndexedDB here if needed
  }

  @override
  void destroy() async {
    // No-op for web platform
  }
}
