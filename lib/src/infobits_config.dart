import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'analytics_region.dart';
import 'log_event.dart';
import 'options.dart';

/// Central configuration for all Infobits services
class InfobitsConfig {
  static InfobitsConfig? _instance;

  /// Get the current configuration
  static InfobitsConfig? get instance => _instance;

  /// Check if Infobits is configured
  static bool get isConfigured => _instance != null;

  /// API key for Infobits services (optional - if not provided, only local logging works)
  final String? apiKey;

  /// Domain or namespace for the application
  final String? domain;

  /// Whether analytics is enabled
  final bool analyticsEnabled;

  /// Whether logging is enabled
  final bool loggingEnabled;

  /// Debug mode
  final bool debug;

  /// Logging options
  final LoggingOptions loggingOptions;

  /// Analytics ingest URL
  final String analyticsIngestUrl;

  /// Logging ingest URL
  final String loggingIngestUrl;

  /// Analytics region for data collection
  final InfobitsRegion analyticsRegion;

  /// Callback for log events
  final void Function(LoggingLogEvent logEvent)? onLog;

  /// Interval for sending logs
  final Duration sendInterval;

  /// Maximum number of logs to batch
  final int maxLogCount;

  /// Number of context logs to include
  final int includedContextLogs;

  InfobitsConfig._({
    this.apiKey,
    this.domain,
    required this.analyticsEnabled,
    required this.loggingEnabled,
    required this.debug,
    required this.loggingOptions,
    required this.analyticsIngestUrl,
    required this.loggingIngestUrl,
    required this.analyticsRegion,
    this.onLog,
    required this.sendInterval,
    required this.maxLogCount,
    required this.includedContextLogs,
  });

  /// Initialize the configuration
  static Future<void> initialize({
    String? apiKey,
    String? domain,
    String? namespace,
    bool analyticsEnabled = true,
    bool loggingEnabled = true,
    bool? debug,
    LoggingOptions? loggingOptions,
    String? analyticsIngestUrl,
    String? loggingIngestUrl,
    InfobitsRegion? analyticsRegion,
    void Function(LoggingLogEvent logEvent)? onLog,
    Duration sendInterval = const Duration(milliseconds: 100),
    int maxLogCount = 100,
    int includedContextLogs = 0,
  }) async {
    // Validate domain/namespace - only error if both are provided
    if (domain != null && namespace != null) {
      throw ArgumentError('Only one of domain or namespace should be provided');
    }

    // Get domain from package info if not provided
    String? effectiveDomain = domain ?? namespace;
    if (effectiveDomain == null && apiKey != null) {
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        effectiveDomain = packageInfo.packageName;
      } catch (e) {
        // If we can't get package info, throw an error only if API key is provided
        throw ArgumentError(
          'Could not automatically determine domain/namespace from package. Please provide either domain or namespace parameter.',
        );
      }
    }

    // Set debug mode based on build mode if not specified
    debug ??= kDebugMode;

    // Use provided options or default based on build mode
    loggingOptions ??= kDebugMode
        ? LoggingOptions.development()
        : LoggingOptions.production();

    _instance = InfobitsConfig._(
      apiKey: apiKey,
      domain: effectiveDomain,
      analyticsEnabled: analyticsEnabled,
      loggingEnabled: loggingEnabled,
      debug: debug,
      loggingOptions: loggingOptions,
      analyticsRegion: analyticsRegion ?? RegionConfig.defaultRegion,
      analyticsIngestUrl:
          analyticsIngestUrl ?? RegionConfig.defaultAnalyticsIngestUrl,
      loggingIngestUrl:
          loggingIngestUrl ?? RegionConfig.defaultLoggingIngestUrl,
      onLog: onLog,
      sendInterval: sendInterval,
      maxLogCount: maxLogCount,
      includedContextLogs: includedContextLogs,
    );
  }

  /// Check if server communication is enabled (API key is provided)
  bool get hasApiKey => apiKey != null;

  /// Check if analytics can be used
  bool get canUseAnalytics => hasApiKey && analyticsEnabled;

  /// Check if logging can send to server
  bool get canSendLogs => hasApiKey && loggingEnabled;
}
