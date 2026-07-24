import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';

import '../services/local_store.dart';

/// Persists and broadcasts the language shown across the app.
///
/// On the very first launch — before the member has chosen anything — the app
/// follows the device language (French if the phone is French, English
/// otherwise). The moment they pick a language in Settings it's stored on-device
/// and takes over from the system default on every launch after that.
class AppLocale extends ValueNotifier<Locale> {
  AppLocale._() : super(_initial());

  static final AppLocale instance = AppLocale._();
  static const _settingsKey = 'user_settings';

  /// The languages the app actually ships translations for.
  static const supported = ['en', 'fr'];

  static Locale _initial() {
    final stored = LocalStore.instance.getJson(_settingsKey)?['language'];
    if (stored is String && stored.isNotEmpty) return _localeForLabel(stored);
    // First run: mirror the device language (only en/fr are supported).
    final system = PlatformDispatcher.instance.locale.languageCode;
    return Locale(system == 'fr' ? 'fr' : 'en');
  }

  static Locale _localeForLabel(String label) =>
      Locale(label == 'Français' ? 'fr' : 'en');

  /// The label for the language currently in effect (for Settings display).
  String get label => value.languageCode == 'fr' ? 'Français' : 'English';

  /// True once the member has explicitly chosen a language (vs. the system
  /// default still being in force).
  bool get isExplicit {
    final stored = LocalStore.instance.getJson(_settingsKey)?['language'];
    return stored is String && stored.isNotEmpty;
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
    value = _localeForLabel(label);
  }
}

extension AppCopy on BuildContext {
  bool get isFrench => Localizations.localeOf(this).languageCode == 'fr';

  String copy(String english, String french) => isFrench ? french : english;
}
