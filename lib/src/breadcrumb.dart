import 'package:flutter/foundation.dart';

/// Represents a single breadcrumb entry
class Breadcrumb {
  final String category;
  final String? message;
  final Map<String, dynamic>? data;
  final DateTime timestamp;
  final BreadcrumbLevel level;

  Breadcrumb({
    required this.category,
    this.message,
    this.data,
    DateTime? timestamp,
    this.level = BreadcrumbLevel.info,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      if (message != null) 'message': message,
      if (data != null) 'data': data,
      'timestamp': timestamp.toIso8601String(),
      'level': level.toString().split('.').last,
    };
  }

  @override
  String toString() {
    return 'Breadcrumb: $category${message != null ? ' - $message' : ''}';
  }
}

/// Breadcrumb severity levels
enum BreadcrumbLevel {
  debug,
  info,
  navigation,
  error,
  warning,
  user,
  state,
}

/// Manages breadcrumbs for debugging and error tracking
class BreadcrumbManager {
  static BreadcrumbManager? _instance;
  
  /// Maximum number of breadcrumbs to keep
  final int maxBreadcrumbs;
  
  /// List of breadcrumbs
  final List<Breadcrumb> _breadcrumbs = [];
  
  BreadcrumbManager._({
    this.maxBreadcrumbs = 100,
  });
  
  /// Get the singleton instance
  static BreadcrumbManager get instance {
    _instance ??= BreadcrumbManager._();
    return _instance!;
  }
  
  /// Initialize with custom settings
  static void initialize({int maxBreadcrumbs = 100}) {
    _instance = BreadcrumbManager._(maxBreadcrumbs: maxBreadcrumbs);
  }
  
  /// Add a breadcrumb
  void add(
    String category, {
    String? message,
    Map<String, dynamic>? data,
    BreadcrumbLevel level = BreadcrumbLevel.info,
  }) {
    final breadcrumb = Breadcrumb(
      category: category,
      message: message,
      data: data,
      level: level,
    );
    
    _breadcrumbs.add(breadcrumb);
    
    // Trim to max size
    while (_breadcrumbs.length > maxBreadcrumbs) {
      _breadcrumbs.removeAt(0);
    }
    
    if (kDebugMode) {
      print('[Breadcrumb] $breadcrumb');
    }
  }
  
  /// Add a navigation breadcrumb
  void addNavigation(String from, String to, {Map<String, dynamic>? data}) {
    add(
      'navigation',
      message: '$from → $to',
      data: data,
      level: BreadcrumbLevel.navigation,
    );
  }
  
  /// Add a user action breadcrumb
  void addUserAction(String action, {Map<String, dynamic>? data}) {
    add(
      'user',
      message: action,
      data: data,
      level: BreadcrumbLevel.user,
    );
  }
  
  /// Add an HTTP breadcrumb
  void addHttp({
    required String method,
    required String url,
    int? statusCode,
    Map<String, dynamic>? data,
  }) {
    add(
      'http',
      message: '$method $url${statusCode != null ? ' ($statusCode)' : ''}',
      data: {
        'method': method,
        'url': url,
        if (statusCode != null) 'status_code': statusCode,
        ...?data,
      },
      level: statusCode != null && statusCode >= 400
          ? BreadcrumbLevel.error
          : BreadcrumbLevel.info,
    );
  }
  
  /// Add a state change breadcrumb
  void addStateChange(String state, {Map<String, dynamic>? data}) {
    add(
      'state',
      message: state,
      data: data,
      level: BreadcrumbLevel.state,
    );
  }
  
  /// Add an error breadcrumb
  void addError(String error, {Map<String, dynamic>? data}) {
    add(
      'error',
      message: error,
      data: data,
      level: BreadcrumbLevel.error,
    );
  }
  
  /// Get all breadcrumbs
  List<Breadcrumb> get breadcrumbs => List.unmodifiable(_breadcrumbs);
  
  /// Get breadcrumbs as JSON
  List<Map<String, dynamic>> toJson() {
    return _breadcrumbs.map((b) => b.toJson()).toList();
  }
  
  /// Clear all breadcrumbs
  void clear() {
    _breadcrumbs.clear();
  }
  
  /// Get breadcrumbs for the last N seconds
  List<Breadcrumb> getBreadcrumbsSince(Duration duration) {
    final cutoff = DateTime.now().subtract(duration);
    return _breadcrumbs.where((b) => b.timestamp.isAfter(cutoff)).toList();
  }
}