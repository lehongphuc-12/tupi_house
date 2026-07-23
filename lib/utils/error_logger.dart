import 'error_logger_stub.dart'
    if (dart.library.io) 'error_logger_io.dart' as implementation;

void appendErrorLog(String content) {
  implementation.appendErrorLog(content);
}
