import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// Thin wrapper around Supabase initialization.
///
/// Initialization is skipped entirely when credentials are not configured so
/// the app can boot in demo mode without throwing.
abstract final class SupabaseService {
  static bool _initialized = false;

  static bool get isReady => _initialized && SupabaseConfig.isConfigured;

  static Future<void> init() async {
    if (!SupabaseConfig.isConfigured || _initialized) return;
    await Supabase.initialize(
      url: SupabaseConfig.url,
      // ignore: deprecated_member_use
      anonKey: SupabaseConfig.anonKey,
    );
    _initialized = true;
  }

  /// Convenience accessor. Only valid when [isReady] is true.
  static SupabaseClient get client => Supabase.instance.client;
}
