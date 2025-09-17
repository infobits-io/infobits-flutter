import 'package:flutter/widgets.dart';

import 'analytics.dart';

/// Signature for a function that extracts a screen name from [RouteSettings].
///
/// Usually, the route name is not a plain string, and it may contains some
/// unique ids that makes it difficult to aggregate over them in Infobits
/// Analytics.
///
/// It is recommended to use this function to extract a plain string name from
/// [RouteSettings].
///
/// If the function returns `null`, the route will not be tracked.
typedef ScreenNameExtractor = String? Function(RouteSettings settings);

String? defaultNameExtractor(RouteSettings settings) => settings.name;

/// [RouteFilter] allows to filter out routes that should not be tracked.
///
/// By default, only [PageRoute]s are tracked.
typedef RouteFilter = bool Function(Route<dynamic>? route);

bool defaultRouteFilter(Route<dynamic>? route) => route is PageRoute || true;

/// A [NavigatorObserver] that sends events to Infobits Analytics when the
/// currently active [ModalRoute] changes.
///
/// When a route is pushed or popped, and if [routeFilter] is true,
/// [nameExtractor] is used to extract a name  from [RouteSettings] of the now
/// active route and that name is sent to Infobits.
class InfobitsAnalyticsObserver extends RouteObserver<ModalRoute<dynamic>> {
  InfobitsAnalyticsObserver({
    this.nameExtractor = defaultNameExtractor,
    this.routeFilter = defaultRouteFilter,
    this.onError,
  });

  final ScreenNameExtractor nameExtractor;
  final RouteFilter routeFilter;
  final void Function(Object error)? onError;

  void _sendScreenView(Route<dynamic> newRoute, Route<dynamic>? oldRoute) {
    String? oldScreenName;
    if (oldRoute != null && routeFilter(oldRoute)) {
      oldScreenName = nameExtractor(oldRoute.settings);
      if (oldScreenName != null) {
        try {
          InfobitsAnalytics.instance.endView(oldScreenName);
        } catch (e) {
          onError?.call(e);
        }
      }
    }
    final String? newScreenName = nameExtractor(newRoute.settings);
    if (newScreenName != null) {
      try {
        InfobitsAnalytics.instance.startView(
          newScreenName,
          referrerPath: oldScreenName ?? "",
        );
      } catch (e) {
        onError?.call(e);
      }
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (routeFilter(route)) {
      _sendScreenView(route, previousRoute);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null && routeFilter(newRoute)) {
      _sendScreenView(newRoute, oldRoute);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null &&
        routeFilter(previousRoute) &&
        routeFilter(route)) {
      _sendScreenView(previousRoute, route);
    }
  }
}
