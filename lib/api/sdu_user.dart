import '../entity/result.dart';
import '../utils/store_utils.dart';
import 'base.dart';
import 'http_request.dart';
import 'js_api.dart';

class SduUserAPI {
  static const _usernameKey = 'icampus-user';
  static const _passwordKey = 'sdu-password';
  static SduUserAPI? _instance;

  SduUserAPI._();

  factory SduUserAPI() {
    _instance ??= SduUserAPI._();
    return _instance!;
  }

  Future<bool> userExist() async {
    String? username = await SecureStore.read(_usernameKey);
    String? password = await SecureStore.read(_passwordKey);
    return username != null && password != null;
  }

  Future<String?> loadUsername() async {
    return await SecureStore.read(_usernameKey);
  }

  Future<void> saveUser(String username, String password) async {
    await HttpRequest().clearCache();
    await SecureStore.write(_usernameKey, username);
    await SecureStore.write(_passwordKey, password);
  }
}
