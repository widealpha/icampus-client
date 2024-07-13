import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class CacheEntity {
  String key;
  String value;
  String type;
  DateTime expires;

  CacheEntity({
    required this.key,
    required this.value,
    required this.type,
    required this.expires,
  });

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'value': value,
      'type': type,
      'expires': expires.toString(),
    };
  }

  factory CacheEntity.fromJson(Map<String, dynamic> map) {
    return CacheEntity(
      key: map['key'] as String,
      value: map['value'] as String,
      type: map['type'] as String,
      expires: DateTime.parse(map['expires']),
    );
  }
}

class CacheUtils {
  static const String fileType = 'FILE';
  static const String textType = 'TEXT';
  static Box<String>? _cacheBox;
  static final Map<String, String> _memoryCache = {};
  static final Map<String, DateTime> _memoryCacheExpires = {};

  static Future<void> _ensureInitialize() async {
    _cacheBox ??= await Hive.openBox('cache');
  }

  static Future<String?> loadText(String key) async {
    try {
      await _ensureInitialize();
      if (_memoryCache.containsKey(key) &&
          _memoryCacheExpires.containsKey(key)) {
        if (_memoryCacheExpires[key]!.isAfter(DateTime.now())) {
          return _memoryCache[key];
        } else {
          return null;
        }
      }
      String? cacheString = _cacheBox!.get(key);
      if (cacheString != null) {
        var entity = CacheEntity.fromJson(jsonDecode(cacheString));
        if (entity.expires.isAfter(DateTime.now())) {
          if (entity.type == textType) {
            return entity.value;
          } else {
            var dir = await getApplicationCacheDirectory();
            String cacheFilename = entity.value;
            File file = File(path.join(dir.path, cacheFilename));
            return file.readAsString();
          }
        } else {
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  static Future<Uint8List?> loadCacheFile(String key) async {
    try {
      await _ensureInitialize();
      String? cacheString = _cacheBox!.get(key);
      if (cacheString != null) {
        var entity = CacheEntity.fromJson(jsonDecode(cacheString));
        if (entity.type == fileType && entity.expires.isAfter(DateTime.now())) {
          var dir = await getApplicationCacheDirectory();
          String cacheFilename = entity.value;
          File file = File(path.join(dir.path, cacheFilename));
          return file.readAsBytes();
        } else {
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  static Future<void> cacheFile(String key, Uint8List bytes,
      {Duration expires = const Duration(days: 100000)}) async {
    await _ensureInitialize();
    var dir = await getApplicationCacheDirectory();
    String cacheFilename = '${DateTime.now().millisecondsSinceEpoch}.cache';
    File file = File(path.join(dir.path, cacheFilename));
    await file.writeAsBytes(bytes);
    await _cacheBox!.put(
        key,
        jsonEncode(CacheEntity(
          key: key,
          value: cacheFilename,
          type: fileType,
          expires: DateTime.now().add(expires),
        )));
  }

  static Future<void> cacheText(String key, String value,
      {Duration expires = const Duration(days: 10000),
      bool onlyMemoryCache = false}) async {
    if (value.length > 10000) {
      debugPrint(
          'Warning: Cache text longer than 10000 with key :$key, please use cacheLongText instead');
    }
    await _ensureInitialize();
    _memoryCache[key] = value;
    _memoryCacheExpires[key] = DateTime.now().add(expires);
    if (onlyMemoryCache) {
      return;
    }
    await _cacheBox!.put(
        key,
        jsonEncode(CacheEntity(
          key: key,
          value: value,
          type: textType,
          expires: DateTime.now().add(expires),
        )));
  }

  static Future<void> cacheLongText(String key, String value,
      {Duration expires = const Duration(days: 100000)}) async {
    await _ensureInitialize();
    var dir = await getApplicationCacheDirectory();
    String? cacheFilename;
    //load filename from cache if exist
    if (_cacheBox!.containsKey(key)) {
      var entity = CacheEntity.fromJson(jsonDecode(_cacheBox!.get(key)!));
      if (entity.type == fileType) {
        cacheFilename = entity.value;
      }
    }
    cacheFilename ??= '${DateTime.now().millisecondsSinceEpoch}.cache';
    File file = File(path.join(dir.path, cacheFilename));
    await file.writeAsString(value);
    String jsonString = jsonEncode(CacheEntity(
      key: key,
      value: cacheFilename,
      type: fileType,
      expires: DateTime.now().add(expires),
    ));
    await _cacheBox!.put(key, jsonString);
  }

  static void removeCache(String key) async {
    await _ensureInitialize();
    _memoryCache.remove(key);
    _memoryCacheExpires.remove(key);
    String? cacheString = _cacheBox!.get(key);
    if (cacheString != null) {
      var entity = CacheEntity.fromJson(jsonDecode(cacheString));
      if (entity.type == fileType) {
        File file = File(entity.type);
        if (await file.exists()) file.delete();
      }
    }
    _cacheBox!.delete(key);
  }

  static void clearCache() async {
    await _ensureInitialize();
    _cacheBox!.keys.map((key) => removeCache(key));
    _memoryCache.clear();
    _memoryCacheExpires.clear();
    _cacheBox!.clear();
  }
}
