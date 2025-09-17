import 'package:flutter/material.dart';

import '../../src/log_event.dart';
import 'mock_analytics.dart';
import 'mock_logger.dart';

/// Test configuration for Infobits
class InfobitsTestConfig {
  final MockInfobitsAnalytics mockAnalytics;
  final MockLogger mockLogger;
  
  InfobitsTestConfig({
    MockInfobitsAnalytics? analytics,
    MockLogger? logger,
  })  : mockAnalytics = analytics ?? MockInfobitsAnalytics(),
        mockLogger = logger ?? MockLogger();
  
  /// Reset all mocks
  void reset() {
    mockAnalytics.clear();
    mockLogger.clear();
  }
}

/// Create a test widget with Infobits mocks
Widget createTestWidget(
  Widget child, {
  InfobitsTestConfig? config,
}) {
  return MaterialApp(
    home: child,
  );
}


/// Verify that an event was tracked
bool verifyEventTracked(
  MockInfobitsAnalytics analytics,
  String eventName, {
  Map<String, dynamic>? expectedProperties,
}) {
  final events = analytics.getEventsByName(eventName);
  if (events.isEmpty) return false;
  
  if (expectedProperties != null) {
    final lastEvent = events.last;
    for (final entry in expectedProperties.entries) {
      if (lastEvent.properties?[entry.key] != entry.value) {
        return false;
      }
    }
  }
  return true;
}

/// Verify that a log was recorded
bool verifyLogRecorded(
  MockLogger logger,
  String message, {
  LoggingLogLevel? level,
}) {
  if (!logger.wasMessageLogged(message)) {
    return false;
  }
  
  if (level != null) {
    final logsWithMessage = logger.logs
        .where((log) => log.message.toString().contains(message))
        .toList();
    return logsWithMessage.any((log) => log.level == level);
  }
  
  return true;
}

/// Create a test exception
Exception createTestException([String message = 'Test exception']) {
  return Exception(message);
}

/// Create a test stack trace
StackTrace createTestStackTrace() {
  return StackTrace.current;
}

/// Wait for async operations
Future<void> waitForAsync([Duration duration = const Duration(milliseconds: 100)]) {
  return Future.delayed(duration);
}

