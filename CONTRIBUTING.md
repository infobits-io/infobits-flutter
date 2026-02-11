# Contributing to Infobits Flutter SDK

Thank you for your interest in contributing to the Infobits Flutter SDK! We welcome contributions from the community.

## How to Contribute

### Reporting Issues

If you find a bug or have a feature request, please open an issue on our [GitHub repository](https://github.com/infobits-io/infobits-flutter/issues).

When reporting issues, please include:
- Flutter version (`flutter --version`)
- Infobits package version
- Minimal code sample to reproduce the issue
- Expected vs actual behavior
- Any error messages or stack traces

### Submitting Pull Requests

1. **Fork the repository** and create your branch from `master`.

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Make your changes**:
   - Follow the existing code style
   - Add/update tests as needed
   - Update documentation if needed

4. **Verify your changes**:
   ```bash
   # Run tests
   flutter test
   
   # Check formatting
   dart format --set-exit-if-changed .
   
   # Analyze code
   flutter analyze
   
   # Test the example app
   cd example
   flutter run
   ```

5. **Update CHANGELOG.md**:
   - Add your changes under the "Unreleased" section
   - Follow the [Keep a Changelog](https://keepachangelog.com/) format

6. **Commit your changes**:
   - Use clear, descriptive commit messages
   - Follow conventional commits format (e.g., `feat:`, `fix:`, `docs:`)

7. **Push to your fork** and submit a pull request

8. **PR Guidelines**:
   - Provide a clear description of the changes
   - Reference any related issues
   - Ensure all CI checks pass
   - Be responsive to feedback

## Development Setup

### Prerequisites

- Flutter SDK (stable channel)
- Dart SDK
- IDE with Flutter support (VS Code, Android Studio, etc.)

### Running Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/analytics_test.dart
```

### Code Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `dart format` to format code
- Keep lines under 80 characters when possible
- Add comments for complex logic
- Use meaningful variable and function names

### Documentation

- Update the README.md for user-facing changes
- Add inline documentation for public APIs
- Include examples for new features
- Update the example app to demonstrate new functionality

## Code of Conduct

Please be respectful and considerate in all interactions. We aim to maintain a welcoming and inclusive environment for all contributors.

## License

By contributing, you agree that your contributions will be licensed under the BSD 3-Clause License.

## Questions?

If you have questions about contributing, feel free to:
- Open a discussion on GitHub
- Contact us at support@infobits.io

Thank you for helping make Infobits better!