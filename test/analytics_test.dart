import 'package:flutter_test/flutter_test.dart';
import 'package:infobits/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Analytics Tests', () {
    late MockInfobitsAnalytics mockAnalytics;
    
    setUp(() {
      mockAnalytics = MockInfobitsAnalytics();
    });
    
    test('should track custom events', () {
      // Track a simple event
      mockAnalytics.trackEvent('button_clicked');
      expect(mockAnalytics.wasEventTracked('button_clicked'), isTrue);
      expect(mockAnalytics.trackedEvents.length, 1);
    });
    
    test('should track events with properties', () {
      // Track event with properties
      mockAnalytics.trackEvent(
        'purchase',
        properties: {
          'item': 'Premium Plan',
          'price': 99.99,
          'currency': 'USD',
        },
      );
      
      final events = mockAnalytics.getEventsByName('purchase');
      expect(events.length, 1);
      expect(events.first.properties?['item'], 'Premium Plan');
      expect(events.first.properties?['price'], 99.99);
      expect(events.first.properties?['currency'], 'USD');
    });
    
    test('should track revenue', () {
      // Track multiple revenue events
      mockAnalytics.trackRevenue(50.0, currency: 'USD');
      mockAnalytics.trackRevenue(75.50, currency: 'EUR');
      mockAnalytics.trackRevenue(
        100.0,
        currency: 'USD',
        properties: {'product': 'Enterprise Plan'},
      );
      
      expect(mockAnalytics.totalRevenue, 225.50);
      
      final revenueEvents = mockAnalytics.getEventsByName('revenue');
      expect(revenueEvents.length, 3);
      expect(revenueEvents.last.properties?['product'], 'Enterprise Plan');
    });
    
    test('should track conversions', () {
      // Track conversion events
      mockAnalytics.trackConversion(
        'signup',
        properties: {'source': 'organic', 'plan': 'free'},
      );
      mockAnalytics.trackConversion(
        'upgrade',
        properties: {'from_plan': 'free', 'to_plan': 'pro'},
      );
      
      expect(mockAnalytics.wasEventTracked('conversion_signup'), isTrue);
      expect(mockAnalytics.wasEventTracked('conversion_upgrade'), isTrue);
      
      final signupEvents = mockAnalytics.getEventsByName('conversion_signup');
      expect(signupEvents.first.properties?['source'], 'organic');
    });
    
    test('should manage global properties', () {
      // Set global properties
      mockAnalytics.setGlobalProperties({
        'app_version': '1.0.0',
        'environment': 'test',
      });
      
      expect(mockAnalytics.globalProperties['app_version'], '1.0.0');
      expect(mockAnalytics.globalProperties['environment'], 'test');
      
      // Update global properties
      mockAnalytics.updateGlobalProperties({
        'user_type': 'premium',
        'environment': 'production',
      });
      
      expect(mockAnalytics.globalProperties['app_version'], '1.0.0');
      expect(mockAnalytics.globalProperties['environment'], 'production');
      expect(mockAnalytics.globalProperties['user_type'], 'premium');
    });
    
    test('should track views', () {
      // Track page views
      mockAnalytics.startView('/home');
      mockAnalytics.startView('/profile', referrerPath: '/home');
      mockAnalytics.startView('/settings');
      
      expect(mockAnalytics.wasViewTracked('/home'), isTrue);
      expect(mockAnalytics.wasViewTracked('/profile'), isTrue);
      expect(mockAnalytics.wasViewTracked('/settings'), isTrue);
      expect(mockAnalytics.trackedViews.length, 3);
      
      // End views
      mockAnalytics.endView('/home');
      mockAnalytics.endView('/profile');
      
      expect(mockAnalytics.endedViews.contains('/home'), isTrue);
      expect(mockAnalytics.endedViews.contains('/profile'), isTrue);
    });
    
    test('should clear all tracked data', () {
      // Add some data
      mockAnalytics.trackEvent('test_event');
      mockAnalytics.startView('/test');
      mockAnalytics.setGlobalProperties({'key': 'value'});
      
      // Verify data exists
      expect(mockAnalytics.trackedEvents.isNotEmpty, isTrue);
      expect(mockAnalytics.trackedViews.isNotEmpty, isTrue);
      expect(mockAnalytics.globalProperties.isNotEmpty, isTrue);
      
      // Clear all data
      mockAnalytics.clear();
      
      // Verify data is cleared
      expect(mockAnalytics.trackedEvents.isEmpty, isTrue);
      expect(mockAnalytics.trackedViews.isEmpty, isTrue);
      expect(mockAnalytics.globalProperties.isEmpty, isTrue);
    });
    
    test('should get last event', () {
      mockAnalytics.trackEvent('first_event');
      mockAnalytics.trackEvent('second_event');
      mockAnalytics.trackEvent('last_event');
      
      expect(mockAnalytics.lastEvent?.name, 'last_event');
    });
  });
}