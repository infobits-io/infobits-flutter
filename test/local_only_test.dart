import 'package:flutter_test/flutter_test.dart';
import 'package:infobits/infobits.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Local-only mode (no API key)', () {
    test('Infobits.initialize works without API key', () async {
      await Infobits.initialize();

      expect(Infobits.isInitialized, isTrue);
      expect(Infobits.canLog, isTrue);
      expect(Infobits.canTrack, isFalse); // No analytics without API key
    });

    test('Logger works without API key', () {
      // These should not throw
      Logger.verbose('Test verbose message');
      Logger.debug('Test debug message');
      Logger.info('Test info message');
      Logger.warn('Test warning message');
      Logger.error('Test error message', exception: Exception('test'));
      Logger.fatal('Test fatal message');
    });

    test('Analytics is not available without API key', () {
      expect(Infobits.canTrack, isFalse);

      // Trying to access analytics should throw
      expect(() => InfobitsAnalytics.instance, throwsException);
    });

    test('Validates domain/namespace only when API key is provided', () {
      // Without API key, domain/namespace are not required
      expect(() async => await Infobits.initialize(), returnsNormally);

      // With API key, domain or namespace is required
      expect(
        () => Infobits.initialize(apiKey: 'test-key'),
        throwsArgumentError,
      );

      // With API key and domain should work
      expect(
        () async => await Infobits.initialize(
          apiKey: 'test-key',
          domain: 'test.domain',
        ),
        returnsNormally,
      );
    });
  });
}
