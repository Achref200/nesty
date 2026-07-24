import 'package:flutter/foundation.dart';

import '../../../../core/services/local_store.dart';
import '../../../../core/services/supabase_service.dart';
import '../domain/profile_setup.dart';

/// Holds the one-time "tell us about you" answers gathered right after a
/// member's first sign-up. Persisted on-device via [LocalStore] so the prompt
/// only shows until it's answered (or skipped), and mirrored to the Supabase
/// `profiles` row when a backend is configured so the data is usable server-side
/// (and by the admin console).
///
/// Pre-migration safe: if the profile columns don't exist yet the upsert simply
/// fails silently and the answers still live locally — matching the app's
/// demo-first philosophy.
class ProfileSetupStore extends ChangeNotifier {
  ProfileSetup _value = const ProfileSetup();
  ProfileSetup get value => _value;

  static const _key = 'profile_setup';

  /// Whether the first-run questions should still be shown. True until the
  /// member has completed or skipped them.
  bool get shouldPrompt => !_value.completed;

  Future<void> load() async {
    final map = LocalStore.instance.getJson(_key);
    if (map != null) {
      _value = ProfileSetup.fromMap(map);
      notifyListeners();
    }
    await _refreshFromBackend();
  }

  /// The backend profile is the source of truth for whether setup is done. If
  /// it's reachable we trust it (so a different account on the same device is
  /// still asked); otherwise we keep the local flag.
  Future<void> _refreshFromBackend() async {
    if (!SupabaseService.isReady) return;
    final client = SupabaseService.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final row = await client
          .from('profiles')
          .select('country, city, onboarding_completed')
          .eq('id', uid)
          .maybeSingle();
      final done =
          row != null &&
          (row['onboarding_completed'] == true ||
              ((row['country'] as String?)?.isNotEmpty ?? false));
      _value = _value.copyWith(
        country: (row?['country'] as String?) ?? _value.country,
        city: (row?['city'] as String?) ?? _value.city,
        completed: done,
      );
      await LocalStore.instance.setJson(_key, _value.toMap());
      notifyListeners();
    } catch (e) {
      // Columns may not exist yet (migration pending) — keep the local flag.
      debugPrint('Profile setup backend refresh failed: $e');
    }
  }

  /// Saves the collected answers and marks setup complete.
  Future<void> save(ProfileSetup answers) async {
    _value = answers.copyWith(completed: true);
    await LocalStore.instance.setJson(_key, _value.toMap());
    notifyListeners();
    await _saveToBackend();
  }

  /// Dismisses the questions without answers. We still mark it complete so the
  /// member isn't nagged on every launch.
  Future<void> skip() async {
    _value = _value.copyWith(completed: true);
    await LocalStore.instance.setJson(_key, _value.toMap());
    notifyListeners();
    await _saveToBackend();
  }

  Future<void> _saveToBackend() async {
    if (!SupabaseService.isReady) return;
    final client = SupabaseService.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await client.from('profiles').upsert({
        'id': uid,
        'country': _value.country,
        'city': _value.city,
        'purpose': _value.purpose,
        'household': _value.household,
        'budget_band': _value.budget,
        'preferred_regions': _value.regions,
        'onboarding_completed': true,
      });
    } catch (e) {
      // Columns may not exist yet (migration pending) — answers stay local.
      debugPrint('Profile setup backend save skipped: $e');
    }
  }

  /// Clears local state (used on sign-out so a different account is asked).
  Future<void> reset() async {
    _value = const ProfileSetup();
    await LocalStore.instance.remove(_key);
    notifyListeners();
  }
}
