/// Raw exceptions thrown by data sources. They are translated into [Failure]s
/// by the repository implementations.
class ServerException implements Exception {
  const ServerException([this.message = 'Server error']);
  final String message;
}

class AuthException implements Exception {
  const AuthException([this.message = 'Auth error']);
  final String message;
}

class NetworkException implements Exception {
  const NetworkException([this.message = 'Network error']);
  final String message;
}

class CacheException implements Exception {
  const CacheException([this.message = 'Cache error']);
  final String message;
}
