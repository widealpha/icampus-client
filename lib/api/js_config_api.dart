class JSConfigAPI {
  static JSConfigAPI? instance;

  JSConfigAPI._();

  factory JSConfigAPI() {
    instance ??= JSConfigAPI._();
    return instance!;
  }

  ///绑定脚本对应的认证脚本
  Future<bool> bindAuthScript(String pluginId, String? authId) async {
    return true;
  }

  Future<String> courseCode() async {
    return '';
  }
}
