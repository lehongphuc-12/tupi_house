import 'dart:io';

void appendErrorLog(String content) {
  try {
    final file = File('error_log.txt');
    file.writeAsStringSync(content, mode: FileMode.append);
  } catch (_) {
    // Error logging must never interrupt application startup or rendering.
  }
}
