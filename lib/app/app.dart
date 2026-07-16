import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/config/app_config.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../features/saved/presentation/cubit/saved_cubit.dart';
import 'di/injection.dart';
import 'router/app_router.dart';

/// Root widget. Provides the app-wide [AuthCubit] and [SavedCubit] and builds
/// the router once.
class NestlyApp extends StatefulWidget {
  const NestlyApp({super.key});

  @override
  State<NestlyApp> createState() => _NestlyAppState();
}

class _NestlyAppState extends State<NestlyApp> {
  late final AuthCubit _authCubit;
  late final GoRouter router;

  @override
  void initState() {
    super.initState();
    _authCubit = sl<AuthCubit>()..checkSession();
    router = createRouter(_authCubit);
  }

  @override
  void dispose() {
    _authCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authCubit),
        BlocProvider<SavedCubit>(create: (_) => sl<SavedCubit>()),
      ],
      child: MaterialApp.router(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: router,
      ),
    );
  }
}
