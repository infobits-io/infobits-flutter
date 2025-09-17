# Infobits Flutter SDK

[![pub package](https://img.shields.io/pub/v/infobits.svg)](https://pub.dev/packages/infobits)
[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?logo=Flutter&logoColor=white)](https://flutter.dev/)
[![Platform](https://img.shields.io/badge/platform-android%20%7C%20ios%20%7C%20web%20%7C%20macos%20%7C%20windows%20%7C%20linux-lightgrey)](https://flutter.dev/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A privacy-focused, comprehensive analytics, logging, error tracking, and performance monitoring SDK for Flutter applications. Infobits provides powerful insights while respecting user privacy - no user identification, no session tracking, just actionable aggregate data.

## Features

- 📊 **Privacy-Focused Analytics** - Track events and conversions without user identification
- 📝 **Advanced Logging** - Multi-level logging with local and remote storage
- 🐛 **Error Tracking** - Comprehensive error capture with stack traces and breadcrumbs
- ⚡ **Performance Monitoring** - Built-in benchmarking and performance tracking
- 🔄 **Offline Support** - Queue events and logs for later transmission
- 🎯 **Crash Reporting** - Automatic crash detection and reporting
- 🏗️ **Developer Friendly** - Simple API, great documentation, and testing utilities

## Quick Start

### Installation

Add `infobits` to your `pubspec.yaml`:

```yaml
dependencies:
  infobits: ^0.1.0
```

### Basic Setup

The simplest way to get started is using `runWithInfobits`:

```dart
import 'package:infobits/infobits.dart';

void main() {
  runWithInfobits(
    app: MyApp(),
    apiKey: 'your-api-key',     // Optional - for remote logging
    domain: 'your-app.com',      // Required with API key
    debug: true,                 // Enable debug mode
  );
}
```

### Alternative Setup

For more control over initialization:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Infobits.initialize(
    apiKey: 'your-api-key',        // Optional
    domain: 'your-app.com',
    analyticsEnabled: true,
    loggingEnabled: true,
    loggingOptions: LoggingOptions.development(),
  );
  
  runApp(MyApp());
}
```

### Local-Only Mode

Infobits works perfectly without an API key for local development:

```dart
void main() {
  runWithInfobits(app: MyApp());
  // All logging will work locally in console
}
```

## Usage

### Analytics

Track custom events with properties:

```dart
// Track simple events
InfobitsAnalytics.instance.trackEvent('button_clicked');

// Track events with properties
InfobitsAnalytics.instance.trackEvent(
  'purchase_completed',
  properties: {
    'amount': 99.99,
    'currency': 'USD',
    'items': ['item1', 'item2'],
  },
);

// Track revenue
InfobitsAnalytics.instance.trackRevenue(
  99.99,
  currency: 'USD',
  properties: {
    'product': 'Premium Plan',
    'payment_method': 'credit_card',
  },
);

// Track conversions
InfobitsAnalytics.instance.trackConversion(
  'signup',
  properties: {
    'source': 'organic',
    'plan': 'free',
  },
);
```

### Navigation Tracking

Automatically track screen views:

```dart
MaterialApp(
  navigatorObservers: [
    InfobitsAnalyticsObserver(),
  ],
  // ...
);
```

Or manually track views:

```dart
InfobitsAnalytics.instance.startView('/home');
// ... when leaving the view
InfobitsAnalytics.instance.endView('/home');
```

### Logging

Multiple log levels for different scenarios:

```dart
// Simple logging
Logger.debug('User clicked button');
Logger.info('Payment processed successfully');
Logger.warn('API rate limit approaching');
Logger.error('Failed to load user data');

// Logging with additional context
Logger.error(
  'Network request failed',
  exception: error,
  information: stackTrace.toString(),
);

// Structured logging with metadata
Logger.info(
  'Order processed',
  metadata: {
    'order_id': '12345',
    'amount': 99.99,
    'items_count': 3,
  },
);
```

### Error Tracking

Errors are automatically captured when using `runWithInfobits`. You can also manually track errors:

```dart
try {
  // Your code
} catch (error, stackTrace) {
  Logger.error(
    'Operation failed',
    exception: error,
    information: stackTrace.toString(),
  );
}
```

### Breadcrumbs

Track user actions leading up to errors:

```dart
// Add breadcrumbs for debugging
Infobits.addBreadcrumb(
  'user_action',
  data: {'button': 'submit', 'form': 'signup'},
);

// Breadcrumbs are automatically included with errors
```

### Performance Monitoring

Built-in benchmarking for performance tracking:

```dart
// Simple benchmark
final timer = Infobits.benchmark.start('api_call');
await makeApiCall();
timer.stop();

// Benchmark with async/await
final result = await Infobits.benchmark.run(
  'database_query',
  () async {
    return await database.query('SELECT * FROM users');
  },
);

// Nested benchmarks
final parentTimer = Infobits.benchmark.start('checkout_flow');
final paymentTimer = Infobits.benchmark.start('payment_processing');
await processPayment();
paymentTimer.stop();
final shippingTimer = Infobits.benchmark.start('shipping_calculation');
await calculateShipping();
shippingTimer.stop();
parentTimer.stop();
```

## Configuration

### Logging Options

Customize logging behavior:

```dart
// Development configuration
LoggingOptions.development(
  printToConsole: true,
  prettyPrint: true,
  includeStackTrace: true,
);

// Production configuration
LoggingOptions.production(
  printToConsole: false,
  minLevel: LogLevel.warning,
);

// Custom configuration
LoggingOptions(
  filter: MyCustomFilter(),
  printer: MyCustomPrinter(),
  output: MultiOutput([
    ConsoleOutput(),
    FileOutput('app.log'),
  ]),
);
```

### Global Properties

Set properties that are included with all events:

```dart
InfobitsAnalytics.instance.setGlobalProperties({
  'app_version': '1.2.3',
  'environment': 'production',
  'platform': Platform.operatingSystem,
});
```

## Testing

Infobits provides testing utilities for unit tests:

```dart
import 'package:infobits/testing.dart';

void main() {
  test('tracks events correctly', () {
    // Use mock implementation
    final mockAnalytics = MockInfobitsAnalytics();
    
    // Your test code
    myFunction();
    
    // Verify events were tracked
    expect(mockAnalytics.trackedEvents, contains('button_clicked'));
  });
}
```

## Privacy & Compliance

Infobits is designed with privacy in mind:

- ✅ No user identification or tracking
- ✅ No session tracking
- ✅ No personal data collection
- ✅ GDPR compliant by design
- ✅ No third-party data sharing
- ✅ All data is aggregated and anonymous

## Platform Support

| Platform | Supported | Notes |
|----------|-----------|-------|
| Android  | ✅ | Full support |
| iOS      | ✅ | Full support |
| Web      | ✅ | Full support |
| macOS    | ✅ | Full support |
| Windows  | ✅ | Full support |
| Linux    | ✅ | Full support |

## Examples

Check out the [example](example/) directory for a complete sample application demonstrating all features.

## API Reference

For detailed API documentation, visit [pub.dev/documentation/infobits](https://pub.dev/documentation/infobits/latest/).

## Migration Guide

### From Google Analytics

```dart
// Before (Google Analytics)
await FirebaseAnalytics.instance.logEvent(
  name: 'purchase',
  parameters: {'value': 99.99},
);

// After (Infobits)
InfobitsAnalytics.instance.trackEvent(
  'purchase',
  properties: {'value': 99.99},
);
```

### From Sentry

```dart
// Before (Sentry)
await Sentry.captureException(error, stackTrace: stackTrace);

// After (Infobits)
Logger.error('Error occurred', exception: error, information: stackTrace.toString());
```

## Troubleshooting

### Events not appearing?
- Check if analytics is enabled: `Infobits.canTrack`
- Verify API key and domain are correct
- Check debug logs for any errors

### Logs not showing?
- Verify logging is enabled: `Infobits.canLog`
- Check log level settings in `LoggingOptions`
- Ensure console output is enabled in development

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## Support

- 📧 Email: support@infobits.io
- 💬 Discord: [Join our community](https://discord.gg/infobits)
- 🐛 Issues: [GitHub Issues](https://github.com/infobits-io/infobits-flutter/issues)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

Built with ❤️ by the Infobits team for the Flutter community.