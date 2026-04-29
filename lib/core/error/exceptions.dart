class ServerException implements Exception {
  final String? message;
  const ServerException([this.message]);
}

class CacheException implements Exception {}

class NetworkException implements Exception {}

class UnauthorizedException implements Exception {}

class NotFoundException implements Exception {}
