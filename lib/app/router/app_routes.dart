/// Centralized route paths and names.
abstract final class AppRoutes {
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String auth = '/auth';
  static const String blocked = '/blocked';
  static const String home = '/home';
  static const String listingDetails = '/listing/:id';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String profile = '/profile';

  static String listingDetailsPath(String id) => '/listing/$id';
}
