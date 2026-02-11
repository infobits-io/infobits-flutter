import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'analytics.dart';
import 'analytics_region.dart';
import 'benchmark.dart';
import 'breadcrumb.dart';
import 'infobits_config.dart';
import 'logging.dart';
import 'log_event.dart';
import 'logger.dart';
import 'options.dart';

/// Main Infobits class that provides unified initialization and error handling
class Infobits {
  static bool _initialized = false;

  /// Check if Infobits has been initialized
  static bool get isInitialized => _initialized;

  /// Get the current configuration
  static InfobitsConfig? get config => InfobitsConfig.instance;

  /// Get the API key if configured
  static String? get apiKey => config?.apiKey;

  /// Get the domain if configured
  static String? get domain => config?.domain;

  /// Check if debug mode is enabled
  static bool get debug => config?.debug ?? kDebugMode;

  /// Check if logging is available
  static bool get canLog {
    if (!_initialized) return false;
    try {
      // Check if we can access the logging instance
      InfobitsLogging.instance;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Check if analytics is available
  static bool get canTrack {
    if (!_initialized) return false;
    if (config?.canUseAnalytics != true) return false;
    try {
      // Check if we can access the analytics instance
      InfobitsAnalytics.instance;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Get the benchmark instance
  static InfobitsBenchmark get benchmark => InfobitsBenchmark.instance;

  /// Get the breadcrumb manager instance
  static BreadcrumbManager get breadcrumbs => BreadcrumbManager.instance;

  /// Add a breadcrumb for debugging
  static void addBreadcrumb(
    String category, {
    String? message,
    Map<String, dynamic>? data,
    BreadcrumbLevel level = BreadcrumbLevel.info,
  }) {
    breadcrumbs.add(category, message: message, data: data, level: level);
  }

  /// Unified initialization for both Analytics and Logging
  ///
  /// This method initializes both Infobits Analytics and Logging with a single call.
  ///
  /// Optional parameters:
  /// - [apiKey]: Your Infobits API key (required for sending logs to server)
  /// - [domain] or [namespace]: Your application domain or namespace (required if apiKey is provided)
  ///
  /// Other optional parameters:
  /// - [analyticsEnabled]: Enable analytics tracking (default: true)
  /// - [loggingEnabled]: Enable logging (default: true)
  /// - [debug]: Enable debug mode for verbose output (default: false in release, true in debug)
  /// - [loggingOptions]: Custom logging options (default: development in debug, production in release)
  /// - [analyticsRegion]: Region for data collection (default: EU)
  /// - [analyticsIngestUrl]: Custom analytics ingest URL
  /// - [loggingIngestUrl]: Custom logging ingest URL
  /// - [onLog]: Callback for log events
  /// - [sendInterval]: Interval for sending logs (default: 100ms)
  /// - [maxLogCount]: Maximum number of logs to batch (default: 100)
  /// - [includedContextLogs]: Number of context logs to include (default: 0)
  static Future<void> initialize({
    String? apiKey,
    String? domain,
    String? namespace,
    bool analyticsEnabled = true,
    bool loggingEnabled = true,
    bool? debug,
    LoggingOptions? loggingOptions,
    InfobitsRegion? analyticsRegion,
    String? analyticsIngestUrl,
    String? loggingIngestUrl,
    void Function(LoggingLogEvent logEvent)? onLog,
    Duration sendInterval = const Duration(milliseconds: 100),
    int maxLogCount = 100,
    int includedContextLogs = 0,
  }) async {
    // Initialize the configuration
    await InfobitsConfig.initialize(
      apiKey: apiKey,
      domain: domain,
      namespace: namespace,
      analyticsEnabled: analyticsEnabled,
      loggingEnabled: loggingEnabled,
      debug: debug,
      loggingOptions: loggingOptions,
      analyticsRegion: analyticsRegion,
      analyticsIngestUrl: analyticsIngestUrl,
      loggingIngestUrl: loggingIngestUrl,
      onLog: onLog,
      sendInterval: sendInterval,
      maxLogCount: maxLogCount,
      includedContextLogs: includedContextLogs,
    );

    final config = InfobitsConfig.instance!;

    // Initialize Analytics if enabled and API key is provided
    if (config.canUseAnalytics) {
      await InfobitsAnalytics.initialize();
    }

    // Initialize Logging (always, even without API key for local logging)
    if (config.loggingEnabled) {
      await InfobitsLogging.initialize();
    }

    // Initialize breadcrumb manager
    BreadcrumbManager.initialize(maxBreadcrumbs: 100);

    _initialized = true;
  }

  /// Run an app with Infobits initialization and error handling
  ///
  /// This function:
  /// 1. Ensures Flutter bindings are initialized
  /// 2. Sets up a protected Zone with runZonedGuarded
  /// 3. Initializes Infobits inside the zone
  /// 4. Runs your app with comprehensive error handling
  ///
  /// The initialization parameters are the same as [Infobits.initialize].
  ///
  /// Example:
  /// ```dart
  /// void main() {
  ///   runWithInfobits(
  ///     app: MyApp(),
  ///     apiKey: 'your-api-key',  // Optional - only needed for server logging
  ///     // domain is optional - will be extracted from package name if not provided
  ///   );
  /// }
  /// ```
  static void runWithInfobits({
    required Widget app,
    String? apiKey,
    String? domain,
    String? namespace,
    bool analyticsEnabled = true,
    bool loggingEnabled = true,
    bool? debug,
    LoggingOptions? loggingOptions,
    InfobitsRegion? analyticsRegion,
    String? analyticsIngestUrl,
    String? loggingIngestUrl,
    void Function(LoggingLogEvent logEvent)? onLog,
    Duration sendInterval = const Duration(milliseconds: 100),
    int maxLogCount = 100,
    int includedContextLogs = 0,
    void Function(Object error, StackTrace stack)? onError,
    bool ensureInitialized = true,
  }) {
    runZonedGuarded(
      () async {
        // Ensure Flutter bindings are initialized INSIDE the zone
        if (ensureInitialized) {
          WidgetsFlutterBinding.ensureInitialized();
        }

        // Initialize Infobits inside the zone
        // This will set up all error handlers (FlutterError.onError, PlatformDispatcher.onError, etc.)
        await initialize(
          apiKey: apiKey,
          domain: domain,
          namespace: namespace,
          analyticsEnabled: analyticsEnabled,
          loggingEnabled: loggingEnabled,
          debug: debug,
          loggingOptions: loggingOptions,
          analyticsRegion: analyticsRegion,
          analyticsIngestUrl: analyticsIngestUrl,
          loggingIngestUrl: loggingIngestUrl,
          onLog: onLog,
          sendInterval: sendInterval,
          maxLogCount: maxLogCount,
          includedContextLogs: includedContextLogs,
        );

        // Run the app
        runApp(app);
      },
      (error, stack) {
        // This catches errors in the current Zone
        // At this point, Infobits should be initialized (unless initialization itself failed)

        if (canLog) {
          // Log the error using Infobits
          Logger.error(
            'Uncaught zone error',
            exception: error,
            information: stack.toString(),
          );
        } else if (kDebugMode) {
          // Fallback logging in debug mode if Infobits isn't available
          print('Zone error (Infobits not available): $error');
          print('Stack trace: $stack');
        }

        // Call custom error handler if provided
        onError?.call(error, stack);
      },
    );
  }
}

/// Convenience function to run an app with Infobits initialization and error handling
///
/// This is a top-level function that wraps [Infobits.runWithInfobits]
/// for easier usage.
///
/// Example for local logging only:
/// ```dart
/// void main() {
///   runWithInfobits(app: MyApp());
/// }
/// ```
///
/// Example with server logging:
/// ```dart
/// void main() {
///   runWithInfobits(
///     app: MyApp(),
///     apiKey: 'your-api-key',
///     // domain is optional - will be extracted from package name if not provided
///   );
/// }
/// ```
void runWithInfobits({
  required Widget app,
  String? apiKey,
  String? domain,
  String? namespace,
  bool analyticsEnabled = true,
  bool loggingEnabled = true,
  bool? debug,
  LoggingOptions? loggingOptions,
  InfobitsRegion? analyticsRegion,
  String? analyticsIngestUrl,
  String? loggingIngestUrl,
  void Function(LoggingLogEvent logEvent)? onLog,
  Duration sendInterval = const Duration(milliseconds: 100),
  int maxLogCount = 100,
  int includedContextLogs = 0,
  void Function(Object error, StackTrace stack)? onError,
  bool ensureInitialized = true,
}) {
  Infobits.runWithInfobits(
    app: app,
    apiKey: apiKey,
    domain: domain,
    namespace: namespace,
    analyticsEnabled: analyticsEnabled,
    loggingEnabled: loggingEnabled,
    debug: debug,
    loggingOptions: loggingOptions,
    analyticsRegion: analyticsRegion,
    analyticsIngestUrl: analyticsIngestUrl,
    loggingIngestUrl: loggingIngestUrl,
    onLog: onLog,
    sendInterval: sendInterval,
    maxLogCount: maxLogCount,
    includedContextLogs: includedContextLogs,
    onError: onError,
    ensureInitialized: ensureInitialized,
  );
}
