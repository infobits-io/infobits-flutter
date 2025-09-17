import 'package:flutter_test/flutter_test.dart';
import 'package:infobits/infobits.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Infobits Package', () {
    test('Logger can be instantiated', () {
      final logger = Logger();
      expect(logger, isNotNull);
    });

    test('InfobitsAnalytics can be initialized through Infobits', () async {
      // Initialize through central Infobits configuration
      await Infobits.initialize(
        apiKey: 'test-key',
        domain: 'test.domain',
      );
      // Analytics should now be available
      expect(InfobitsAnalytics.instance, isNotNull);
    });
  });
}