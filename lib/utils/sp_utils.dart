import 'package:shared_preferences/shared_preferences.dart';

enum SPEnum {
  init('init'),
  showCase('showCase'),
  themeModeFollowSystem('themeModeFollowSystem'),
  darkThemeMode('darkThemeMode'),
  developMode('developMode'),
  themeColor('themeColor'),
  favorSections('favorSections'),
  readNotice('readNotice');

  final String key;

  const SPEnum(this.key);
}

class SPUtils {
  ///下面是一些key,减少魔法字符串
  ///所有api的baseHost的id号
  static const String hostId = 'hostId';
  static const String sectionSubscription = 'sectionSubscription';

  static SharedPreferences? _sp;

  static Future<void> initialize() async {
    _sp ??= await SharedPreferences.getInstance();
  }

  ///必须先进行初始化
  static SharedPreferences get instance {
    assert(_sp != null);
    return _sp!;
  }

  static dynamic get(SPEnum key) {
    return _sp?.get(key.key);
  }

  static double? getDouble(SPEnum key) {
    return _sp?.getDouble(key.key);
  }

  static int? getInt(SPEnum key) {
    return _sp?.getInt(key.key);
  }

  static String? getString(SPEnum key) {
    return _sp?.getString(key.key);
  }

  static bool? getBool(SPEnum key) {
    return _sp?.getBool(key.key);
  }

  static List<String>? getStringList(SPEnum key) {
    return _sp?.getStringList(key.key);
  }

  static Object getWithDefault(SPEnum key, {Object object = const Object()}) {
    return _sp?.get(key.key) ?? object;
  }

  static double doubleWithDefault(SPEnum key, {double defaultValue = 0.0}) {
    return _sp?.getDouble(key.key) ?? defaultValue;
  }

  static int intWithDefault(SPEnum key, {int defaultValue = 0}) {
    return _sp?.getInt(key.key) ?? defaultValue;
  }

  static String stringWithDefault(SPEnum key, {String defaultValue = ''}) {
    return _sp?.getString(key.key) ?? defaultValue;
  }

  static bool boolWithDefault(SPEnum key, {bool defaultValue = false}) {
    return _sp?.getBool(key.key) ?? defaultValue;
  }

  static List<String> stringListWithDefault(SPEnum key,
      {List<String> defaultValue = const <String>[]}) {
    return _sp?.getStringList(key.key) ?? defaultValue;
  }

  static Future<bool> setDouble(SPEnum key, double value) {
    if (_sp == null) {
      return Future.value(false);
    }
    return _sp!.setDouble(key.key, value);
  }

  static Future<bool> setInt(SPEnum key, int value) {
    if (_sp == null) {
      return Future.value(false);
    }
    return _sp!.setInt(key.key, value);
  }

  static Future<bool> setString(SPEnum key, String value) {
    if (_sp == null) {
      return Future.value(false);
    }
    return _sp!.setString(key.key, value);
  }

  static Future<bool> setBool(SPEnum key, bool value) {
    if (_sp == null) {
      return Future.value(false);
    }
    return _sp!.setBool(key.key, value);
  }

  static Future<bool> setStringList(SPEnum key, List<String> value) {
    if (_sp == null) {
      return Future.value(false);
    }
    return _sp!.setStringList(key.key, value);
  }

  static bool contains(SPEnum key) {
    return _sp?.containsKey(key.key) ?? false;
  }

  static Future<bool> remove(SPEnum key) {
    if (_sp == null) {
      return Future.value(false);
    }
    return _sp!.remove(key.key);
  }

  static Future<bool> clear() {
    if (_sp == null) {
      return Future.value(false);
    }
    return _sp!.clear();
  }

  Future<void> reload() async {
    return _sp?.reload();
  }
}
