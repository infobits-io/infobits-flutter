import 'dart:async';

/// Mock implementation of InfobitsAnalytics for testing
class MockInfobitsAnalytics {
  /// List of tracked events
  final List<TrackedEvent> trackedEvents = [];
  
  /// List of tracked views
  final List<String> trackedViews = [];
  
  /// List of ended views
  final List<String> endedViews = [];
  
  /// Global properties
  final Map<String, dynamic> globalProperties = {};
  
  /// Track a custom event
  Future<void> trackEvent(
    String eventName, {
    Map<String, dynamic>? properties,
  }) async {
    trackedEvents.add(TrackedEvent(
      name: eventName,
      properties: properties,
      timestamp: DateTime.now(),
    ));
  }
  
  /// Track revenue
  Future<void> trackRevenue(
    double amount, {
    String currency = 'USD',
    Map<String, dynamic>? properties,
  }) async {
    trackedEvents.add(TrackedEvent(
      name: 'revenue',
      properties: {
        'amount': amount,
        'currency': currency,
        ...?properties,
      },
      timestamp: DateTime.now(),
    ));
  }
  
  /// Track a conversion
  Future<void> trackConversion(
    String conversionType, {
    Map<String, dynamic>? properties,
  }) async {
    trackedEvents.add(TrackedEvent(
      name: 'conversion_$conversionType',
      properties: properties,
      timestamp: DateTime.now(),
    ));
  }
  
  /// Start tracking a view
  void startView(String path, {String referrerPath = ''}) {
    trackedViews.add(path);
  }
  
  /// End tracking a view
  Future<void> endView(String path) async {
    endedViews.add(path);
  }
  
  /// Set global properties
  void setGlobalProperties(Map<String, dynamic> properties) {
    globalProperties.clear();
    globalProperties.addAll(properties);
  }
  
  /// Update global properties
  void updateGlobalProperties(Map<String, dynamic> properties) {
    globalProperties.addAll(properties);
  }
  
  /// Clear all tracked data
  void clear() {
    trackedEvents.clear();
    trackedViews.clear();
    endedViews.clear();
    globalProperties.clear();
  }
  
  /// Get events by name
  List<TrackedEvent> getEventsByName(String name) {
    return trackedEvents.where((e) => e.name == name).toList();
  }
  
  /// Check if an event was tracked
  bool wasEventTracked(String eventName) {
    return trackedEvents.any((e) => e.name == eventName);
  }
  
  /// Check if a view was tracked
  bool wasViewTracked(String path) {
    return trackedViews.contains(path);
  }
  
  /// Get the last tracked event
  TrackedEvent? get lastEvent => 
      trackedEvents.isEmpty ? null : trackedEvents.last;
  
  /// Get total revenue tracked
  double get totalRevenue {
    return trackedEvents
        .where((e) => e.name == 'revenue')
        .fold(0.0, (sum, e) => sum + (e.properties?['amount'] as double? ?? 0));
  }
}

/// Represents a tracked event
class TrackedEvent {
  final String name;
  final Map<String, dynamic>? properties;
  final DateTime timestamp;
  
  TrackedEvent({
    required this.name,
    this.properties,
    required this.timestamp,
  });
  
  @override
  String toString() {
    return 'TrackedEvent(name: $name, properties: $properties, timestamp: $timestamp)';
  }
}