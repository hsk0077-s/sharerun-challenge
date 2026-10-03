import 'package:shared_preferences/shared_preferences.dart';

import 'run_finish_share_card.dart';

/// Last share-card background. Display only; stored on the phone.
abstract final class RunFinishThemeStore {
  static const prefsKey = 'run_finish_share_theme';

  static Future<RunFinishCardTheme> load() async {
    try {
      final name = (await SharedPreferences.getInstance()).getString(prefsKey);
      for (final theme in RunFinishCardTheme.colorThemes) {
        if (theme.name == name) return theme;
      }
    } catch (_) {}
    return RunFinishCardTheme.dark;
  }

  static Future<void> save(RunFinishCardTheme theme) async {
    if (theme == RunFinishCardTheme.photo) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsKey, theme.name);
    } catch (_) {}
  }
}
