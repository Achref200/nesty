import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'app/app.dart';
import 'app/di/injection.dart';
import 'core/services/local_store.dart';
import 'core/services/push_service.dart';
import 'core/services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  PlatformDispatcher.instance.onError = (error, stack) {
    if (_isOauthCodeExchangeError(error)) {
      debugPrint(
        'OAuth callback exchange failed. Verify Google Client Secret and redirect URIs in Supabase/Google Cloud.',
      );
      return true;
    }
    return false;
  };

  await runZonedGuarded(() async {
    await LocalStore.init();
    await SupabaseService.init();
    await PushService.init();
    await configureDependencies();
    runApp(const NestlyApp());
  }, (error, stack) {
    if (_isOauthCodeExchangeError(error)) {
      debugPrint(
        'OAuth callback exchange failed. Verify Google Client Secret and redirect URIs in Supabase/Google Cloud.',
      );
      return;
    }
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'main',
        context: ErrorDescription('while bootstrapping the app'),
      ),
    );
  });
}

bool _isOauthCodeExchangeError(Object error) {
  if (error is! sb.AuthException) return false;
  final message = error.message.toLowerCase();
  return message.contains('unable to exchange external code');
}

