import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/di/injection.dart';
import 'core/services/local_store.dart';
import 'core/services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStore.init();
  await SupabaseService.init();
  await configureDependencies();
  runApp(const NestlyApp());
}

