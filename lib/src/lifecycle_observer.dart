import 'package:flutter/widgets.dart';

import 'analytics.dart';

class InfobitsLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      InfobitsAnalytics.instance.resumeViews();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      InfobitsAnalytics.instance.pauseViews();
    } else if (state == AppLifecycleState.detached) {
      InfobitsAnalytics.instance.endViews();
    }
  }
}
