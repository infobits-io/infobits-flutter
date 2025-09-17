import 'package:flutter_test/flutter_test.dart';
import 'package:infobits/infobits.dart';

void main() {
  group('Breadcrumb Tests', () {
    late BreadcrumbManager breadcrumbs;
    
    setUp(() {
      BreadcrumbManager.initialize(maxBreadcrumbs: 10);
      breadcrumbs = BreadcrumbManager.instance;
      breadcrumbs.clear();
    });
    
    test('should add basic breadcrumbs', () {
      breadcrumbs.add('test', message: 'Test breadcrumb');
      
      expect(breadcrumbs.breadcrumbs.length, 1);
      expect(breadcrumbs.breadcrumbs.first.category, 'test');
      expect(breadcrumbs.breadcrumbs.first.message, 'Test breadcrumb');
    });
    
    test('should add breadcrumbs with data', () {
      breadcrumbs.add(
        'user_action',
        message: 'Button clicked',
        data: {'button_id': 'submit', 'form': 'login'},
        level: BreadcrumbLevel.user,
      );
      
      final breadcrumb = breadcrumbs.breadcrumbs.first;
      expect(breadcrumb.data?['button_id'], 'submit');
      expect(breadcrumb.data?['form'], 'login');
      expect(breadcrumb.level, BreadcrumbLevel.user);
    });
    
    test('should add navigation breadcrumbs', () {
      breadcrumbs.addNavigation('/home', '/profile');
      breadcrumbs.addNavigation('/profile', '/settings', data: {'tab': 'privacy'});
      
      expect(breadcrumbs.breadcrumbs.length, 2);
      expect(breadcrumbs.breadcrumbs[0].message, '/home → /profile');
      expect(breadcrumbs.breadcrumbs[1].message, '/profile → /settings');
      expect(breadcrumbs.breadcrumbs[1].data?['tab'], 'privacy');
    });
    
    test('should add user action breadcrumbs', () {
      breadcrumbs.addUserAction('form_submitted', data: {'form_id': 'signup'});
      breadcrumbs.addUserAction('button_clicked');
      
      expect(breadcrumbs.breadcrumbs.length, 2);
      expect(breadcrumbs.breadcrumbs[0].category, 'user');
      expect(breadcrumbs.breadcrumbs[0].message, 'form_submitted');
      expect(breadcrumbs.breadcrumbs[0].data?['form_id'], 'signup');
    });
    
    test('should add HTTP breadcrumbs', () {
      breadcrumbs.addHttp(
        method: 'GET',
        url: 'https://api.example.com/users',
        statusCode: 200,
      );
      
      breadcrumbs.addHttp(
        method: 'POST',
        url: 'https://api.example.com/login',
        statusCode: 401,
        data: {'error': 'Invalid credentials'},
      );
      
      expect(breadcrumbs.breadcrumbs.length, 2);
      expect(breadcrumbs.breadcrumbs[0].level, BreadcrumbLevel.info);
      expect(breadcrumbs.breadcrumbs[1].level, BreadcrumbLevel.error);
      expect(breadcrumbs.breadcrumbs[1].data?['error'], 'Invalid credentials');
    });
    
    test('should add state change breadcrumbs', () {
      breadcrumbs.addStateChange('app_foreground');
      breadcrumbs.addStateChange('app_background', data: {'reason': 'user_switched_apps'});
      
      expect(breadcrumbs.breadcrumbs.length, 2);
      expect(breadcrumbs.breadcrumbs[0].message, 'app_foreground');
      expect(breadcrumbs.breadcrumbs[1].data?['reason'], 'user_switched_apps');
    });
    
    test('should add error breadcrumbs', () {
      breadcrumbs.addError('Network timeout', data: {'url': 'api.example.com'});
      breadcrumbs.addError('Database connection failed');
      
      expect(breadcrumbs.breadcrumbs.length, 2);
      expect(breadcrumbs.breadcrumbs[0].level, BreadcrumbLevel.error);
      expect(breadcrumbs.breadcrumbs[0].data?['url'], 'api.example.com');
    });
    
    test('should respect max breadcrumbs limit', () {
      // Add more than max breadcrumbs
      for (int i = 0; i < 15; i++) {
        breadcrumbs.add('test', message: 'Breadcrumb $i');
      }
      
      // Should only keep the last 10
      expect(breadcrumbs.breadcrumbs.length, 10);
      expect(breadcrumbs.breadcrumbs.first.message, 'Breadcrumb 5');
      expect(breadcrumbs.breadcrumbs.last.message, 'Breadcrumb 14');
    });
    
    test('should get breadcrumbs since duration', () async {
      breadcrumbs.add('old', message: 'Old breadcrumb');
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      breadcrumbs.add('recent', message: 'Recent breadcrumb');
      breadcrumbs.add('very_recent', message: 'Very recent breadcrumb');
      
      final recentBreadcrumbs = breadcrumbs.getBreadcrumbsSince(
        const Duration(milliseconds: 50),
      );
      
      expect(recentBreadcrumbs.length, 2);
      expect(recentBreadcrumbs[0].message, 'Recent breadcrumb');
      expect(recentBreadcrumbs[1].message, 'Very recent breadcrumb');
    });
    
    test('should convert to JSON', () {
      breadcrumbs.add(
        'test',
        message: 'Test message',
        data: {'key': 'value'},
        level: BreadcrumbLevel.info,
      );
      
      final json = breadcrumbs.toJson();
      
      expect(json.length, 1);
      expect(json[0]['category'], 'test');
      expect(json[0]['message'], 'Test message');
      expect(json[0]['data']['key'], 'value');
      expect(json[0]['level'], 'info');
      expect(json[0]['timestamp'], isNotNull);
    });
    
    test('should clear breadcrumbs', () {
      breadcrumbs.add('test1');
      breadcrumbs.add('test2');
      breadcrumbs.add('test3');
      
      expect(breadcrumbs.breadcrumbs.length, 3);
      
      breadcrumbs.clear();
      
      expect(breadcrumbs.breadcrumbs.isEmpty, isTrue);
    });
  });
}