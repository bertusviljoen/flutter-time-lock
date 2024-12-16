import 'package:logger/logger.dart';

class LoggerUtil {
  static final Logger _logger = Logger();

  static void debug(String tag, String message) {
    _logger.d('[$tag] $message');
  }

  static void info(String tag, String message) {
    _logger.i('[$tag] $message');
  }

  static void warning(String tag, String message) {
    _logger.w('[$tag] $message');
  }

  static void error(String tag, String message,
      [dynamic error, StackTrace? stackTrace]) {
    var errorMessage =
        error.toString() + '\n' + stackTrace.toString() + '\n' + message;
    _logger.e('[$tag] $errorMessage');
  }
}
