import 'package:flutter/foundation.dart';

/// Which bottom-nav/rail tab is active. A plain index rather than named tabs
/// to match [AppShell]'s existing flat `_screens` list — lets other screens
/// (e.g. "Prep for this job" on a job card) switch tabs programmatically.
class NavigationState extends ChangeNotifier {
  int tabIndex = 1; // Home is the default landing tab

  void goTo(int index) {
    if (tabIndex == index) return;
    tabIndex = index;
    notifyListeners();
  }
}
