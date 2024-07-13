abstract class AuthManager {
  final bool debug;

  AuthManager({this.debug = false});

  Future<String?> cookie(String service);

  Future<void> clearCookies();

  Future<bool> removeCookie(String service);
}

class TGTInvalidException implements Exception {}

class CookieInvalidException implements Exception {}

class PasswordErrorException implements Exception {}
