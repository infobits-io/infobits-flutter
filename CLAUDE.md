# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Package Overview

Infobits is a privacy-focused Flutter SDK providing:
- Analytics tracking without user identification
- Multi-level logging with local/remote storage
- Error tracking with breadcrumbs
- Performance benchmarking
- Offline support with event queuing

## Common Commands

### Development
```bash
# Install dependencies
flutter pub get

# Run tests
flutter test

# Run a specific test file
flutter test test/analytics_test.dart

# Run tests with coverage
flutter test --coverage

# Analyze code for issues
flutter analyze

# Format code
dart format .

# Check pub score (before publishing)
dart pub publish --dry-run
```

### Example App
```bash
# Run example app
cd example
flutter run

# Run specific example variant
flutter run -t lib/main_simple.dart
flutter run -t lib/main_local_only.dart
flutter run -t lib/main_manual.dart
```

## Architecture

### Core Components

**Infobits Class (`lib/src/infobits.dart`)**
- Central initialization point
- Manages configuration and initialization state
- Provides unified error handling via `runWithInfobits`
- Coordinates between Analytics, Logging, and Benchmarking subsystems

**Analytics System**
- `InfobitsAnalytics` - Main analytics interface for event tracking
- `InfobitsAnalyticsObserver` - Flutter navigation observer for automatic screen tracking
- Server communication via gRPC for efficient data transmission
- Event batching and offline queuing

**Logging System**
- `Logger` - Static interface for logging at different levels
- `InfobitsLogging` - Core logging implementation
- Modular architecture with:
  - **Filters**: Control which logs are processed (e.g., `DevelopmentLogFilter`, `ProductionLogFilter`)
  - **Printers**: Format log output (e.g., `PrettyLogPrinter`, `SimpleLogPrinter`)
  - **Outputs**: Send logs to destinations (e.g., `ConsoleLogOutput`, `FileLogOutput`, `StreamLogOutput`)

**Platform Support**
- Conditional imports for web/WASM compatibility
- `file_log_output.dart` uses conditional exports:
  - `file_log_output_io.dart` for native platforms (uses dart:io)
  - `file_log_output_stub.dart` for web/WASM (no file operations)

### Key Design Patterns

1. **Singleton Pattern**: Most services use singleton instances (`InfobitsAnalytics.instance`, `InfobitsLogging.instance`)

2. **Builder Pattern**: `LoggingOptions` provides preset configurations:
   - `LoggingOptions.development()` - Console output with pretty printing
   - `LoggingOptions.production()` - Minimal output, higher log levels

3. **Observer Pattern**: Navigation and lifecycle observers for automatic tracking

4. **Strategy Pattern**: Pluggable filters, printers, and outputs for logging

## Testing Approach

The package includes comprehensive test coverage:
- Unit tests for all major components
- Mock implementations provided in `lib/testing.dart`
- Test utilities in `lib/src/testing/`

Run tests before any significant changes to ensure compatibility.

## Important Considerations

### WASM/Web Compatibility
The package now supports web/WASM through conditional imports. File operations are stubbed out on web platforms. When modifying platform-specific code, ensure both implementations are updated.

### Privacy by Design
- No user identification or session tracking
- All analytics data is anonymous and aggregated
- No personal data collection
- GDPR compliant by default

### Error Handling
When using `runWithInfobits`, all Flutter errors and exceptions are automatically captured. The function wraps the app with error boundaries and zone error handlers.

### Performance
- Events are batched before sending (default: 100ms interval, 100 event batch size)
- Offline support with automatic retry
- gRPC used for efficient binary communication with servers

## Package Publishing

Before publishing:
1. Update version in `pubspec.yaml`
2. Update CHANGELOG.md
3. Run `dart format .`
4. Run `flutter analyze`
5. Run `flutter test`
6. Check pub score: `dart pub publish --dry-run`
7. Ensure all platforms are supported (check WASM compatibility)