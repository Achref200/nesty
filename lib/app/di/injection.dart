import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import '../../core/config/supabase_config.dart';
import '../../core/services/supabase_service.dart';
import '../../features/assistant/data/datasources/assistant_remote_datasource.dart';
import '../../features/assistant/data/datasources/gemini_remote_datasource.dart';
import '../../features/assistant/data/repositories/assistant_repository_impl.dart';
import '../../features/assistant/domain/repositories/assistant_repository.dart';
import '../../features/assistant/domain/usecases/send_message_usecase.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/datasources/demo_auth_remote_data_source.dart';
import '../../features/auth/data/datasources/supabase_auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/get_current_user.dart';
import '../../features/auth/domain/usecases/sign_in.dart';
import '../../features/auth/domain/usecases/sign_out.dart';
import '../../features/auth/domain/usecases/sign_up.dart';
import '../../features/auth/domain/usecases/update_profile.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/listings/data/datasources/listing_remote_data_source.dart';
import '../../features/listings/data/datasources/host_listings_store.dart';
import '../../features/listings/data/datasources/local_listings_store.dart';
import '../../features/listings/data/datasources/mock_listing_remote_data_source.dart';
import '../../features/listings/data/datasources/supabase_listing_remote_data_source.dart';
import '../../features/listings/data/repositories/listing_repository_impl.dart';
import '../../features/listings/domain/repositories/listing_repository.dart';
import '../../features/listings/domain/usecases/get_listing_by_id.dart';
import '../../features/listings/domain/usecases/get_listings.dart';
import '../../features/listings/presentation/cubit/listing_details_cubit.dart';
import '../../features/listings/presentation/cubit/listings_cubit.dart';
import '../../features/notifications/data/notifications_store.dart';
import '../../features/reservations/data/reservations_store.dart';
import '../../features/saved/presentation/cubit/saved_cubit.dart';
import '../../features/subscription/data/subscription_store.dart';

/// Global service locator.
final GetIt sl = GetIt.instance;

/// Wires the whole app. Data sources switch between Supabase and demo
/// implementations based on [SupabaseConfig.isConfigured], so the app runs
/// end-to-end with or without a backend.
Future<void> configureDependencies() async {
  final useSupabase = SupabaseConfig.isConfigured;

  // ---- Auth ----
  sl.registerLazySingleton<AuthRemoteDataSource>(() {
    if (useSupabase) {
      return SupabaseAuthRemoteDataSource(SupabaseService.client);
    }
    return DemoAuthRemoteDataSource();
  });
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<AuthRemoteDataSource>()),
  );
  sl.registerLazySingleton(() => SignIn(sl()));
  sl.registerLazySingleton(() => SignUp(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));
  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerLazySingleton(() => UpdateProfile(sl()));
  sl.registerLazySingleton(
    () => AuthCubit(
      signIn: sl(),
      signUp: sl(),
      signOut: sl(),
      getCurrentUser: sl(),
      updateProfile: sl(),
      repository: sl(),
    ),
  );

  // ---- Listings ----
  sl.registerLazySingleton(() => LocalListingsStore());
  sl.registerLazySingleton(() => HostListingsStore(sl()));
  sl.registerLazySingleton<ListingRemoteDataSource>(() {
    if (useSupabase) {
      return SupabaseListingRemoteDataSource(SupabaseService.client);
    }
    return MockListingRemoteDataSource(sl<LocalListingsStore>());
  });
  sl.registerLazySingleton<ListingRepository>(
    () => ListingRepositoryImpl(sl<ListingRemoteDataSource>()),
  );
  sl.registerLazySingleton(() => GetListings(sl()));
  sl.registerLazySingleton(() => GetListingById(sl()));
  sl.registerFactory(() => ListingsCubit(getListings: sl()));
  sl.registerFactory(() => ListingDetailsCubit(getListingById: sl()));

  // ---- Saved (favourites) ----
  sl.registerLazySingleton(() => SavedCubit());

  // ---- Reservations (visits, stays, calendar) ----
  sl.registerLazySingleton(() => ReservationsStore());

  // ---- Notifications (activity center) ----
  sl.registerLazySingleton(() => NotificationsStore());

  // ---- Subscription (Partner paywall & plan) ----
  sl.registerLazySingleton(() => SubscriptionStore());

  // ---- AI assistant (contextual, available everywhere) ----
  sl.registerLazySingleton(() => http.Client());
  sl.registerLazySingleton<AssistantRemoteDataSource>(
    () => GeminiRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<AssistantRepository>(
    () => AssistantRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => SendMessageUseCase(sl()));
}
