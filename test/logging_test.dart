import 'package:flutter_test/flutter_test.dart';
import 'package:infobits/testing.dart';

void main() {
  group('Logging Tests', () {
    late MockLogger mockLogger;

    setUp(() {
      mockLogger = MockLogger();
    });

    test('should log messages at different levels', () {
      mockLogger.verbose('Verbose message');
      mockLogger.debug('Debug message');
      mockLogger.info('Info message');
      mockLogger.warn('Warning message');
      mockLogger.error('Error message');
      mockLogger.fatal('Fatal message');

      expect(mockLogger.logs.length, 6);
      expect(mockLogger.getLogsByLevel(LoggingLogLevel.verbose).length, 1);
      expect(mockLogger.getLogsByLevel(LoggingLogLevel.debug).length, 1);
      expect(mockLogger.getLogsByLevel(LoggingLogLevel.info).length, 1);
      expect(mockLogger.getLogsByLevel(LoggingLogLevel.warning).length, 1);
      expect(mockLogger.getLogsByLevel(LoggingLogLevel.error).length, 1);
      expect(mockLogger.getLogsByLevel(LoggingLogLevel.fatal).length, 1);
    });

    test('should log with exceptions', () {
      final exception = Exception('Test exception');

      mockLogger.error(
        'An error occurred',
        exception: exception,
        information: 'Additional context',
      );

      final errorLog = mockLogger.errorLogs.first;
      expect(errorLog.message, 'An error occurred');
      expect(errorLog.exception, exception);
      expect(errorLog.information, 'Additional context');
    });

    test('should log with metadata', () {
      mockLogger.info(
        'User action',
        metadata: {
          'user_id': '12345',
          'action': 'button_click',
          'timestamp': '2024-01-01T12:00:00Z',
        },
      );

      final log = mockLogger.infoLogs.first;
      expect(log.metadata?['user_id'], '12345');
      expect(log.metadata?['action'], 'button_click');
      expect(log.metadata?['timestamp'], '2024-01-01T12:00:00Z');
    });

    test('should check if message was logged', () {
      mockLogger.info('Application started');
      mockLogger.debug('Loading configuration');
      mockLogger.error('Failed to connect to server');

      expect(mockLogger.wasMessageLogged('Application started'), isTrue);
      expect(mockLogger.wasMessageLogged('Loading configuration'), isTrue);
      expect(mockLogger.wasMessageLogged('Failed to connect'), isTrue);
      expect(mockLogger.wasMessageLogged('Not logged'), isFalse);
    });

    test('should get logs by level', () {
      // Log multiple messages at different levels
      mockLogger.debug('Debug 1');
      mockLogger.debug('Debug 2');
      mockLogger.info('Info 1');
      mockLogger.warn('Warning 1');
      mockLogger.warn('Warning 2');
      mockLogger.warn('Warning 3');
      mockLogger.error('Error 1');

      expect(mockLogger.debugLogs.length, 2);
      expect(mockLogger.infoLogs.length, 1);
      expect(mockLogger.warningLogs.length, 3);
      expect(mockLogger.errorLogs.length, 1);
    });

    test('should check for errors and warnings', () {
      mockLogger.info('Normal operation');
      expect(mockLogger.hasErrors, isFalse);
      expect(mockLogger.hasWarnings, isFalse);

      mockLogger.warn('Something unusual');
      expect(mockLogger.hasErrors, isFalse);
      expect(mockLogger.hasWarnings, isTrue);

      mockLogger.error('Something went wrong');
      expect(mockLogger.hasErrors, isTrue);
      expect(mockLogger.hasWarnings, isTrue);
    });

    test('should get last log', () {
      mockLogger.info('First');
      mockLogger.debug('Second');
      mockLogger.error('Last');

      expect(mockLogger.lastLog?.message, 'Last');
      expect(mockLogger.lastLog?.level, LoggingLogLevel.error);
    });

    test('should clear logs', () {
      mockLogger.info('Message 1');
      mockLogger.error('Message 2');
      mockLogger.debug('Message 3');

      expect(mockLogger.logs.length, 3);

      mockLogger.clear();

      expect(mockLogger.logs.isEmpty, isTrue);
      expect(mockLogger.hasErrors, isFalse);
      expect(mockLogger.lastLog, isNull);
    });

    test('should handle complex messages', () {
      final complexObject = {
        'key': 'value',
        'nested': {'inner': 'data'},
        'list': [1, 2, 3],
      };

      mockLogger.debug(complexObject);

      expect(mockLogger.debugLogs.first.message, complexObject);
    });
  });
}
