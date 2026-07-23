import 'package:flutter/material.dart';

import '../services/local_store.dart';

/// Persists and broadcasts the language selected in Settings.
class AppLocale extends ValueNotifier<Locale> {
  AppLocale._() : super(_read());

  static final AppLocale instance = AppLocale._();
  static const _settingsKey = 'user_settings';

  static Locale _read() {
    final language = LocalStore.instance.getJson(_settingsKey)?['language'];
    return Locale(language == 'Français' ? 'fr' : 'en');
  }

  Future<void> select(String label) async {
    final preferences = {
      'push': true,
      'email': true,
      'reminders': true,
      'inbox': true,
      'language': 'English',
      ...?LocalStore.instance.getJson(_settingsKey),
    };
    preferences['language'] = label;
    await LocalStore.instance.setJson(_settingsKey, preferences);
    value = Locale(label == 'Français' ? 'fr' : 'en');
  }
}

extension AppCopy on BuildContext {
  bool get isFrench => Localizations.localeOf(this).languageCode == 'fr';

  String copy(String english, String french) => isFrench ? french : english;
}
