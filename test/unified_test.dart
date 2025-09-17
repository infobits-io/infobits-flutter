import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infobits/infobits.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Unified Infobits API', () {
    test('Infobits.initialize works with required parameters', () async {
      await Infobits.initialize(apiKey: 'test-api-key', domain: 'test.domain');

      expect(Infobits.isInitialized, isTrue);
      expect(InfobitsAnalytics.instance, isNotNull);
      expect(InfobitsLogging.instance, isNotNull);
    });

    test('runWithInfobits initializes and runs app', () async {
      // Create a simple test widget
      const testApp = MaterialApp(home: Scaffold(body: Text('Test App')));

      // Run the app with Infobits
      runWithInfobits(
        app: testApp,
        apiKey: 'test-api-key-2',
        domain: 'test.domain2',
        ensureInitialized: false, // Already initialized in test setup
      );

      // Give time for initialization
      await Future.delayed(const Duration(milliseconds: 200));

      // Check that Infobits is initialized
      expect(Infobits.isInitialized, isTrue);
    });

    test('Infobits.initialize validates domain/namespace', () {
      // Test missing both domain and namespace
      expect(
        () => Infobits.initialize(apiKey: 'test-key'),
        throwsArgumentError,
      );

      // Test providing both domain and namespace
      expect(
        () => Infobits.initialize(
          apiKey: 'test-key',
          domain: 'domain',
          namespace: 'namespace',
        ),
        throwsArgumentError,
      );
    });
  });
}
