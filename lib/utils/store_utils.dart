import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/adapters.dart';

import 'package_info_utils.dart';

class Store {
  static bool _initialized = false;
  static late final Box _defaultBox;
  static late final Box<String> _pluginBox;
  static late final Box<String> _pluginPermissionBox;


  static Box<String> get pluginBox => _pluginBox;

  static Box<String> get pluginPermissionBox => _pluginPermissionBox;

  static Future<void> initialize({FlavorEnum flavor = FlavorEnum.prod}) async {
    if (_initialized) {
      return;
    }
    String? subDir;
    if (flavor == FlavorEnum.prod) {
      subDir = 'icampus';
    } else {
      subDir = 'icampus-${flavor.value}';
    }
    await Hive.initFlutter(subDir);
    _defaultBox = await Hive.openBox('default');
    _pluginBox = await Hive.openBox('plugin');
    _pluginPermissionBox = await Hive.openBox('pluginPermission');
    _initialized = true;
  }

  static bool containsKey(String key) {
    return _defaultBox.containsKey(key);
  }

  static String getString(String key, {String def = "", Box? box}) {
    return get<String>(key, box: box) ?? def;
  }

  static int getInt(String key, {int def = 0, Box? box}) {
    return get<int>(key, box: box) ?? def;
  }

  static double getDouble(String key, {double def = 0.0, Box? box}) {
    return get<double>(key, box: box) ?? def;
  }

  static bool getBool(String key, {bool def = false, Box? box}) {
    return get<bool>(key, box: box) ?? def;
  }

  static List<T> getList<T>(String key, {List<T> def = const [], Box? box}) {
    Iterable? l = get(key, box: box);
    if (l == null || l.isEmpty) {
      return def;
    } else {
      return l.cast<T>().toList();
    }
  }

  static Map<K, V> getMap<K, V>(String key,
      {Map<K, V> def = const {}, Box? box}) {
    Map<String, dynamic>? map = get<Map<String, dynamic>>(key, box: box);
    if (map == null || map.isEmpty) {
      return def;
    } else {
      return map.cast<K, V>();
    }
  }

  ///能够被get的类除基本数据类型、String、List, Map, DateTime, Uint8List外
  ///必须实现hive适配器[https://docs.hivedb.dev/#/custom-objects/type_adapters]
  static T? get<T>(String key, {T? defaultValue, Box? box}) {
    box ??= _defaultBox;
    return box.get(key, defaultValue: defaultValue);
  }

  ///能够被set的类除基本数据类型、String、List, Map, DateTime, Uint8List外
  ///必须实现hive适配器[https://docs.hivedb.dev/#/custom-objects/type_adapters]
  static Future<void> set(String key, dynamic value, {Box? box}) {
    box ??= _defaultBox;
    return box.put(key, value);
  }

  static Future<void> putAll(Map<String, dynamic> entries, {Box? box}) {
    box ??= _defaultBox;
    return box.putAll(entries);
  }

  static Future<void> remove(String key, {Box? box}) {
    box ??= _defaultBox;
    return box.delete(key);
  }

  static Future<void> removeKeys(List<String> keys, {Box? box}) {
    box ??= _defaultBox;
    return box.deleteAll(keys);
  }

  static Future<int> removeAll({Box? box}) {
    box ??= _defaultBox;
    return box.clear();
  }
}

class SecureStore {
  static const storage = FlutterSecureStorage();

  static Future<String?> read(String key) async {
    return await storage.read(key: key);
  }

  static Future<void> delete(String key) async {
    await storage.delete(key: key);
  }

  static Future<void> write(String key, String? value) async {
    await storage.write(key: key, value: value);
  }
}
