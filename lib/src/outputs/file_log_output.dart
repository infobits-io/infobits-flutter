// Conditional export for platform-specific implementations
export 'file_log_output_stub.dart'
    if (dart.library.io) 'file_log_output_io.dart';
