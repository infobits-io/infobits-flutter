// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import 'infobits_config.dart';
import 'lifecycle_observer.dart';

const String _defaultIngestUrl = "https://eu.infobits.io/a/";

class InfobitsAnalytics {
  static InfobitsAnalytics? _instance;

  /// Gets the instance of Logging
  static InfobitsAnalytics get instance {
    if (_instance == null) {
      throw Exception("Please initialize Infobits Analytics first");
    }

    return _instance!;
  }

  static Future<void> initialize() async {
    final config = InfobitsConfig.instance;
    if (config == null) {
      throw Exception('Infobits configuration not initialized');
    }
    if (!config.hasApiKey) {
      throw Exception('API key is required for analytics');
    }
    if (config.domain == null) {
      throw Exception('Domain is required for analytics');
    }

    _instance = InfobitsAnalytics._create(
      apiKey: config.apiKey!,
      ingestUrl: config.analyticsIngestUrl,
      domain: config.domain!,
      debug: config.debug,
    );
    WidgetsBinding.instance.addObserver(InfobitsLifecycleObserver());
  }

  InfobitsAnalytics._create({
    required this.apiKey,
    required this.domain,
    this.ingestUrl = _defaultIngestUrl,
    this.debug = false,
  });

  final String apiKey;
  final String ingestUrl;
  final String domain;
  final bool debug;

  // Global properties that will be included with all events
  final Map<String, dynamic> _globalProperties = {};

  // Queue for offline events
  final List<Map<String, dynamic>> _eventQueue = [];

  // Track active views
  List<ViewEntry> views = [];

  void track(String path, {String referrerPath = "", resume = false}) async {
    final protocol = kIsWeb ? Uri.base.scheme : "app";
    final domain = kIsWeb ? Uri.base.host : this.domain;
    final url = "$protocol://$domain$path";

    final referrer = referrerPath == ""
        ? ""
        : "$protocol://$domain$referrerPath";

    const String env = kReleaseMode ? "prod" : "dev";

    final language = PlatformDispatcher.instance.locale.toLanguageTag();
    final languages = PlatformDispatcher.instance.locales
        .map((e) => e.toLanguageTag())
        .toList();

    final size = PlatformDispatcher.instance.implicitView?.display.size;
    final width = size?.width.toInt();
    final height = size?.height.toInt();

    String userAgent = "";
    String appVersion = "";

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final appName = packageInfo.appName;
      appVersion = packageInfo.version;
      final operatingSystem = Platform.operatingSystem;
      final osVersion = Platform.operatingSystemVersion;
      final dartVersion = "Dart ${Platform.version}";

      String platform = "";
      final deviceInfoPlugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        platform = androidInfo.model;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        platform = iosInfo.utsname.machine;
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfoPlugin.windowsInfo;
        platform = windowsInfo.productName;
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfoPlugin.linuxInfo;
        platform = linuxInfo.prettyName;
      } else if (Platform.isMacOS) {
        final macosInfo = await deviceInfoPlugin.macOsInfo;
        platform = macosInfo.model;
      } else if (Platform.isFuchsia) {
        platform = "Fuchsia";
      } else {
        platform = "Unknown";
      }

      userAgent =
          '$appName/$appVersion ($platform; $operatingSystem; $osVersion) ($dartVersion)';

      if (kIsWeb) {
        final webInfo = await deviceInfoPlugin.webBrowserInfo;
        if (webInfo.userAgent != null) {
          userAgent =
              '$appName/$appVersion ${webInfo.userAgent!} ($dartVersion)';
        }
      }
    } catch (e) {
      if (debug) print("Error getting package info: $e");
    }

    if (debug) print("UserAgent: $userAgent");

    final body = jsonEncode({
      'k': apiKey,
      'e': env,
      'u': url,
      'r': referrer,
      'pl': language,
      'l': languages,
      't': DateTime.now().timeZoneName,
      'sr': '${width}x$height',
      'av': appVersion,
      'tv': "flutter-0.0.1-alpha",
      'ca': DateTime.now().toUtc().toIso8601String(),
    });

    final endpoint = Uri.parse("${ingestUrl}view");
    final headers = {
      'Content-Type': 'application/json',
      'User-Agent': userAgent,
    };
    final client = http.Client();

    try {
      final response = await client.post(
        endpoint,
        headers: headers,
        body: body,
      );
      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        final id = res['id'];
        if (resume) {
          views.firstWhere((view) => view.path == path).paused = false;
        } else {
          views.add(ViewEntry(id, path));
        }
        if (debug) print("Tracked event${resume ? " (resumed)" : ""} $path");
      } else {
        if (debug) print("Failed to track event: ${response.statusCode}");
      }
    } catch (e) {
      if (debug) print("Error tracking event: $e");
    }
  }

  void pauseViews() {
    if (debug) print("Pausing views");
    for (var view in views) {
      endView(view.path, paused: true);
    }
  }

  void resumeViews() {
    if (debug) print("Resuming views");
    for (var view in views) {
      if (view.paused) {
        track(view.path, referrerPath: view.path, resume: true);
      }
    }
  }

  void endViews() {
    if (debug) print("Ending views");
    for (var view in views) {
      if (!view.paused) endView(view.path);
    }
    views.clear();
  }

  /// Tracks a view with the given [path].
  void startView(String path, {String referrerPath = ''}) {
    track(path, referrerPath: referrerPath);
  }

  /// Track a custom event with optional properties
  Future<void> trackEvent(
    String eventName, {
    Map<String, dynamic>? properties,
  }) async {
    final eventData = {
      'event': eventName,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'properties': {..._globalProperties, ...?properties},
    };

    await _sendEvent('custom', eventData);
  }

  /// Track revenue with amount and optional properties
  Future<void> trackRevenue(
    double amount, {
    String currency = 'USD',
    Map<String, dynamic>? properties,
  }) async {
    final revenueData = {
      'amount': amount,
      'currency': currency,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'properties': {..._globalProperties, ...?properties},
    };

    await _sendEvent('revenue', revenueData);
  }

  /// Track a conversion event
  Future<void> trackConversion(
    String conversionType, {
    Map<String, dynamic>? properties,
  }) async {
    final conversionData = {
      'type': conversionType,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'properties': {..._globalProperties, ...?properties},
    };

    await _sendEvent('conversion', conversionData);
  }

  /// Set global properties that will be included with all events
  void setGlobalProperties(Map<String, dynamic> properties) {
    _globalProperties.clear();
    _globalProperties.addAll(properties);
  }

  /// Update global properties (merge with existing)
  void updateGlobalProperties(Map<String, dynamic> properties) {
    _globalProperties.addAll(properties);
  }

  /// Remove a global property
  void removeGlobalProperty(String key) {
    _globalProperties.remove(key);
  }

  /// Clear all global properties
  void clearGlobalProperties() {
    _globalProperties.clear();
  }

  /// Internal method to send events
  Future<void> _sendEvent(String eventType, Map<String, dynamic> data) async {
    try {
      // Get device and app info
      String userAgent = "";
      String appVersion = "";
      String platform = "";

      try {
        final packageInfo = await PackageInfo.fromPlatform();
        appVersion = packageInfo.version;

        final deviceInfoPlugin = DeviceInfoPlugin();
        if (!kIsWeb) {
          if (Platform.isAndroid) {
            final androidInfo = await deviceInfoPlugin.androidInfo;
            platform = 'Android ${androidInfo.version.release}';
          } else if (Platform.isIOS) {
            final iosInfo = await deviceInfoPlugin.iosInfo;
            platform = 'iOS ${iosInfo.systemVersion}';
          } else if (Platform.isMacOS) {
            final macInfo = await deviceInfoPlugin.macOsInfo;
            platform = 'macOS ${macInfo.osRelease}';
          } else if (Platform.isWindows) {
            final winInfo = await deviceInfoPlugin.windowsInfo;
            platform = 'Windows ${winInfo.productName}';
          } else if (Platform.isLinux) {
            final linuxInfo = await deviceInfoPlugin.linuxInfo;
            platform = 'Linux ${linuxInfo.prettyName}';
          }
        } else {
          final webInfo = await deviceInfoPlugin.webBrowserInfo;
          platform = 'Web ${webInfo.browserName}';
          userAgent = webInfo.userAgent ?? '';
        }
      } catch (e) {
        if (debug) print('Error getting device info: $e');
      }

      // Add common fields
      final eventPayload = {
        'k': apiKey,
        'domain': domain,
        'event_type': eventType,
        'environment': kReleaseMode ? 'production' : 'development',
        'platform': platform,
        'app_version': appVersion,
        'sdk_version': 'flutter-0.1.0',
        'language': PlatformDispatcher.instance.locale.toLanguageTag(),
        'timezone': DateTime.now().timeZoneName,
        'screen_size': _getScreenSize(),
        ...data,
      };

      // Send the event
      final endpoint = Uri.parse('${ingestUrl}event');
      final headers = {
        'Content-Type': 'application/json',
        if (userAgent.isNotEmpty) 'User-Agent': userAgent,
      };

      final response = await http
          .post(endpoint, headers: headers, body: jsonEncode(eventPayload))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              // Queue event for retry if timeout
              _queueEvent(eventPayload);
              throw Exception('Event send timeout');
            },
          );

      if (response.statusCode == 200) {
        if (debug) {
          print('Event sent successfully: $eventType');
          if (data['event'] != null) {
            print('  Event name: ${data['event']}');
          }
        }
      } else {
        // Queue event for retry if failed
        _queueEvent(eventPayload);
        if (debug) {
          print('Failed to send event: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (debug) print('Error sending event: $e');
      // Queue the event for later retry
      _queueEvent(data);
    }
  }

  /// Queue an event for later sending (offline support)
  void _queueEvent(Map<String, dynamic> eventData) {
    _eventQueue.add(eventData);
    if (_eventQueue.length > 1000) {
      // Remove oldest events if queue is too large
      _eventQueue.removeAt(0);
    }
  }

  /// Process queued events (call this when coming back online)
  Future<void> processQueuedEvents() async {
    if (_eventQueue.isEmpty) return;

    final eventsToProcess = List<Map<String, dynamic>>.from(_eventQueue);
    _eventQueue.clear();

    for (final event in eventsToProcess) {
      try {
        final endpoint = Uri.parse('${ingestUrl}event');
        final response = await http.post(
          endpoint,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(event),
        );

        if (response.statusCode != 200) {
          // Re-queue if still failing
          _queueEvent(event);
        }
      } catch (e) {
        // Re-queue on error
        _queueEvent(event);
      }
    }
  }

  /// Get screen size as a string
  String _getScreenSize() {
    final size = PlatformDispatcher.instance.implicitView?.display.size;
    if (size != null) {
      return '${size.width.toInt()}x${size.height.toInt()}';
    }
    return 'unknown';
  }

  Future<void> endView(String path, {bool paused = false}) async {
    try {
      final view = views.firstWhere((view) => view.path == path);
      final id = view.id;
      if (paused) {
        view.paused = true;
      } else {
        views.remove(view);
      }

      final body = jsonEncode({'k': apiKey, 'id': id});

      final endpoint = Uri.parse("${ingestUrl}end-view");
      final headers = {'Content-Type': 'application/json'};
      final response = await http.post(endpoint, headers: headers, body: body);
      if (response.statusCode == 200) {
        if (debug) print("Ended event${paused ? " (paused)" : ""} $path");
      } else {
        if (debug) print("Failed to end event: ${response.statusCode}");
      }
    } catch (e) {
      if (debug) print("Error ending event: $e");
    }
  }
}

class ViewEntry {
  final String id;
  final String path;
  bool paused = false;

  ViewEntry(this.id, this.path, {this.paused = false});
}
