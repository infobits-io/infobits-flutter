// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart'
    show
        DiagnosticsNode,
        FlutterError,
        FlutterErrorDetails,
        PlatformDispatcher,
        kDebugMode,
        kIsWeb,
        kReleaseMode;
import 'package:flutter/widgets.dart';
import 'package:grpc/grpc.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import 'breadcrumb.dart';
import 'infobits_config.dart';
import 'log_event.dart';
import 'log_output.dart';
import 'options.dart';
import 'trace.dart';
import 'utils.dart';

const String _defaultIngestUrl = "https://eu.infobits.io/l/";

/// The main class for handling logs in Logging.
///
/// It has to be initialized to start working but when it has been initialized
/// it will catch errors and crashes.
///
/// You can also use the static methods to log something manually.
class InfobitsLogging {
  static InfobitsLogging? _instance;

  /// Gets the instance of Logging
  static InfobitsLogging get instance {
    if (_instance == null) {
      throw Exception("Please initialize Logging");
    }

    return _instance!;
  }

  /// Initialize Logging using the central configuration
  static Future<void> initialize() async {
    final config = InfobitsConfig.instance;
    if (config == null) {
      throw Exception('Infobits configuration not initialized');
    }
    
    if (_instance != null) {
      _instance!.close();
    }

    _instance = InfobitsLogging._create();
  }

  LoggingOptions get options => InfobitsConfig.instance?.loggingOptions ?? LoggingOptions.development();
  void Function(LoggingLogEvent logEvent)? get onLog => InfobitsConfig.instance?.onLog;
  String get ingestUrl => InfobitsConfig.instance?.loggingIngestUrl ?? _defaultIngestUrl;
  String? get apiKey => InfobitsConfig.instance?.apiKey;
  Duration get sendInterval => InfobitsConfig.instance?.sendInterval ?? const Duration(milliseconds: 100);
  int get maxLogCount => InfobitsConfig.instance?.maxLogCount ?? 100;
  int get includedContextLogs => InfobitsConfig.instance?.includedContextLogs ?? 0;
  String? get domain => InfobitsConfig.instance?.domain;
  String? get namespace => null; // Deprecated - use domain

  InfobitsLogging._create() {
    options.filter.init();
    options.printer.init();
    options.output.init();
    // Register onError handler
    FlutterError.onError = recordFlutterError;
    // Register platform error handler
    PlatformDispatcher.instance.onError = (error, stack) {
      recordError(error, stack);
      return true;
    };
    // Register error widget builder and handler
    ErrorWidget.builder = (errorDetails) {
      recordFlutterError(errorDetails);
      final errorBuilder =
          options.widgetErrorBuilder ?? LoggingOptions.defaultErrorBuilder;
      return errorBuilder(errorDetails);
    };

    debugPrint =
        (message, {wrapWidth}) => recordLog(LoggingLogLevel.debug, message);
  }

  bool get isLoggingCollectionEnabled {
    return apiKey != null;
  }

  /// Crash the app intentionally (for testing purposes)
  void crash([String message = 'Manual crash triggered']) {
    // Log the crash message first
    recordLog(
      LoggingLogLevel.fatal,
      'App crash triggered: $message',
    );
    
    // Wait a moment to ensure log is sent
    Future.delayed(const Duration(milliseconds: 500), () {
      // Force crash by throwing an unhandled exception
      throw Exception('Forced crash: $message');
    });
  }

  /// Closes the logger and releases all resources.
  void close() {
    options.filter.destroy();
    options.printer.destroy();
    options.output.destroy();
  }

  /// Check for unsent reports
  ///
  /// TODO: Actually store logs
  Future<bool> checkForUnsentLogs() async {
    return false;
  }

  /// Deletes the unsent logs
  ///
  /// TODO: Actually delete the unsent logs
  Future<void> deleteUnsentLogs() async {
    print("deleteUnsentLogs");
  }

  /// Send the unsent logs
  ///
  /// TODO: Actually send the unsent logs
  Future<void> sendUnsentLogs() async {
    print("sending unsent logs");
  }

  // Future<void> setUserIdentifier(String identifier) {
  //   return;
  // }

  /// Check if the application crashed the last time it was run
  Future<bool> didCrashOnPreviousExecution() async {
    return false;
  }

  List<Map<String, Object?>> contextLogs = [];

  Timer? sendTimer;

  List<Map<String, Object?>> logsToBeSent = [];

  Future<void> sendLogs() async {
    if (logsToBeSent.isEmpty) {
      return;
    }

    const String env = kReleaseMode ? "prod" : "dev";

    final language = PlatformDispatcher.instance.locale.toLanguageTag();
    final languages = PlatformDispatcher.instance.locales
        .map((e) => e.toLanguageTag())
        .toList();

    String userAgent = "";
    String appVersion = "";

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final appName = packageInfo.appName;
      appVersion = packageInfo.version;
      String operatingSystem = "";
      String osVersion = "";
      String dartVersion = "";

      if (kIsWeb) {
        dartVersion = "Dart/Web";
      } else {
        dartVersion = "Dart ${Platform.version}";
      }

      String platform = "";
      final deviceInfoPlugin = DeviceInfoPlugin();

      if (kIsWeb) {
        final webInfo = await deviceInfoPlugin.webBrowserInfo;
        operatingSystem = "web";
        osVersion = webInfo.browserName.toString();
        platform = webInfo.platform ?? "unknown";

        if (webInfo.userAgent != null) {
          userAgent =
              '$appName/$appVersion ${webInfo.userAgent!} ($dartVersion)';
        }
      } else {
        operatingSystem = Platform.operatingSystem;
        osVersion = Platform.operatingSystemVersion;

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
      }
    } catch (e) {
      print("Error getting package info: $e");
    }

    final logs = logsToBeSent;
    logsToBeSent = [];

    if (includedContextLogs > 0) {
      logs.addAll(contextLogs);
      contextLogs = [];
    }

    final body = jsonEncode({
      'k': apiKey,
      'e': env,
      'la': languages,
      'pl': language,
      't': DateTime.now().timeZoneName,
      'tv': 'flutter-0.0.1-alpha',
      'logs': logs,
    });

    final endpoint = Uri.parse("${ingestUrl}log");
    final headers = {
      'Content-Type': 'application/json',
      'User-Agent': userAgent,
    };
    final client = http.Client();

    try {
      final response =
          await client.post(endpoint, headers: headers, body: body);
      if (response.statusCode == 200) {
        print("Sent ${logs.length} logs to server");
      } else {
        print("Failed sending logs to server: ${response.statusCode}");
      }
    } catch (e) {
      print("Error sending logs to server: $e");
    }
  }

  Future<Map<String, Object?>> prepareLogForServer(
      LoggingLogEvent logEvent) async {
    final protocol = kIsWeb ? Uri.base.scheme : "app";
    final domain = kIsWeb ? Uri.base.host : this.domain;
    final path = kIsWeb ? Uri.base.path : "";
    final url = "$protocol://$domain$path";

    final size = PlatformDispatcher.instance.implicitView?.display.size;
    final width = size?.width.toInt();
    final height = size?.height.toInt();

    List<Map<String, String>> stackTrace = [];
    if (logEvent.stackTrace != null) {
      for (var i = 0; i < logEvent.stackTrace!.length; i++) {
        final trace = logEvent.stackTrace![i];
        stackTrace.add({
          'order': i.toString(),
          'class': trace.className.toString(),
          'method': trace.method.toString(),
          'file': trace.file,
          'line': trace.line.toString(),
          'column': trace.column.toString(),
        });
      }
    }

    // Include breadcrumbs for error and fatal logs
    List<Map<String, dynamic>>? breadcrumbsJson;
    if (logEvent.level == LoggingLogLevel.error || 
        logEvent.level == LoggingLogLevel.fatal) {
      breadcrumbsJson = BreadcrumbManager.instance.toJson();
    }
    
    return {
      'level': logEvent.level.index + 1,
      'message': logEvent.message.toString(),
      'exception': logEvent.exception?.toString(),
      'information': logEvent.information,
      'stack_trace': stackTrace,
      'url': url,
      'referrer': '',
      'screen_resolution': '${width}x$height',
      'created_at': logEvent.loggedAt.toUtc().toIso8601String(),
      if (logEvent.metadata != null) 'metadata': logEvent.metadata,
      if (breadcrumbsJson != null && breadcrumbsJson.isNotEmpty) 
        'breadcrumbs': breadcrumbsJson,
    };
  }

  /// Send log to the server
  Future<void> queueLogForSending(LoggingLogEvent logEvent) async {
    sendTimer?.cancel();

    final log = await prepareLogForServer(logEvent);

    print("Queued log for sending: $log");

    logsToBeSent.add(log);

    sendTimer = Timer(sendInterval, sendLogs);
  }

  Future<void> addContextLogs(LoggingLogEvent logEvent) async {
    if (contextLogs.length >= maxLogCount) {
      contextLogs.removeAt(0);
    }

    final log = await prepareLogForServer(logEvent);

    contextLogs.add(log);
  }

  /// Record a log and send it to the server if possible
  ///
  /// TODO: Store locally if not connected to internet or if crashed
  Future<void> recordLog(
    LoggingLogLevel level,
    dynamic message, {
    dynamic exception,
    String? information,
    List<LoggingTrace>? stackTrace,
    bool? printDetails,
    Map<String, dynamic>? metadata,
  }) async {
    dynamic exceptionFixed;
    List<LoggingTrace>? stackTraceFixed;
    try {
      exceptionFixed = exception;
    } catch (e) {
      // Fix weird web problem
    }
    try {
      stackTraceFixed = stackTrace;
    } catch (e) {
      // Fix weird web problem
    }

    final LoggingLogEvent logEvent = LoggingLogEvent(
      level: level,
      message: message,
      exception: exceptionFixed,
      information: information,
      stackTrace: stackTraceFixed,
      metadata: metadata,
    );

    // Issues with log should NOT influence
    // the main software behavior.
    try {
      // Send to server
      if (isLoggingCollectionEnabled) {
        if (options.serverFilter.shouldSend(logEvent)) {
          if (apiKey == null) {
            if (kDebugMode) {
              print("INFOBITS LOGGING: No API key set, cannot send log");
            }
          } else {
            queueLogForSending(logEvent);
          }
        } else if (includedContextLogs > 0) {
          addContextLogs(logEvent);
        }
      }

      // Print to console
      if (options.filter.shouldLog(logEvent)) {
        var output = options.printer.log(logEvent);

        if (onLog != null) {
          onLog!(logEvent);
        }

        if (output.isNotEmpty) {
          var outputEvent = LoggingOutputLog(level, output);
          options.output.output(outputEvent);
        }
      }
    } catch (e, s) {
      print(e);
      print(s);
    }
  }

  /// Record an error and send it to the server
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    dynamic reason,
    Iterable<DiagnosticsNode> information = const [],
    bool fatal = false,
  }) {
    final String informationString = information.isEmpty
        ? ''
        : (StringBuffer()..writeAll(information, '\n')).toString();

    // Replace null or empty stack traces with the current stack trace.
    final StackTrace stackTrace = (stack == null || stack.toString().isEmpty)
        ? StackTrace.current
        : stack;

    // Extract stack trace
    final List<LoggingTrace> stackTraceElements =
        getStackTraceElements(stackTrace);

    // Extract reason of the error
    String message = "App encountered an error";
    if (reason != null) {
      if (reason is ErrorDescription) {
        message = "An error occurred ${reason.toDescription()}";
      } else {
        message = reason.toString();
      }
    } else if (exception is GrpcError && exception.message != null) {
      message = exception.message!;
    }

    return recordLog(
      fatal ? LoggingLogLevel.fatal : LoggingLogLevel.error,
      message,
      exception: exception,
      stackTrace: stackTraceElements,
      information: informationString,
      printDetails: false,
    );
  }

  /// Record a flutter error
  /// This is used to catch exceptions in the app
  ///
  /// [FlutterErrorDetails] a object containing all information about the exception
  Future<void> recordFlutterError(
    FlutterErrorDetails flutterErrorDetails, {
    bool fatal = false,
  }) {
    return recordError(
      flutterErrorDetails.exceptionAsString(),
      flutterErrorDetails.stack,
      reason: flutterErrorDetails.context,
      information: flutterErrorDetails.informationCollector == null
          ? []
          : flutterErrorDetails.informationCollector!(),
      fatal: fatal,
    );
  }

  /// Record a fatal flutter error
  ///
  /// [FlutterErrorDetails] a object containing all information about the exception
  Future<void> recordFlutterFatalError(
      FlutterErrorDetails flutterErrorDetails) {
    return recordFlutterError(flutterErrorDetails, fatal: true);
  }
}
