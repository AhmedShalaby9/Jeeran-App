class ServerException implements Exception {
  final String? message;

  /// Machine-readable reason from the API, e.g. `ai_limit`.
  final String? code;

  /// For `ai_limit`: how long until the next question is allowed.
  final int? retryAfterSeconds;

  const ServerException([this.message, this.code, this.retryAfterSeconds]);
}

class CacheException implements Exception {}

class NetworkException implements Exception {}

class UnauthorizedException implements Exception {}

class NotFoundException implements Exception {}
