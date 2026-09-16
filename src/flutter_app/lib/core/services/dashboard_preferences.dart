import 'package:shared_preferences/shared_preferences.dart';

/// Local UI preferences for the Shop/Showroom dashboard.
class DashboardPreferences {
  DashboardPreferences._();

  static const showAtAGlanceKey = 'dashboard_show_at_a_glance';

  static Future<bool> isAtAGlanceVisible() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(showAtAGlanceKey) ?? true;
  }

  static Future<void> setAtAGlanceVisible(bool visible) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(showAtAGlanceKey, visible);
  }
}
