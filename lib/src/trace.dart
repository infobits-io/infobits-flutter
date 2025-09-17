/// Simple class to store a stack trace
class LoggingTrace {
  String file;
  String? className;
  String? method;
  int? line;
  int? column;

  LoggingTrace({
    required this.file,
    this.className,
    this.method,
    this.line,
    this.column,
  });
}
