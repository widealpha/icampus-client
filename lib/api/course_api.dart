import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../auth/auth_manager.dart';
import '../auth/js_auth_manager.dart';
import '../bean/cipher_pair.dart';
import '../entity/result.dart';
import '../bean/course.dart';
import '../utils/cache_utils.dart';
import '../utils/store_utils.dart';
import 'base.dart';
import 'cipher_pair_api.dart';
import 'js_api.dart';
import 'plugin_api.dart';

class CourseAPI {
  static CourseAPI? instance;

  CourseAPI._();

  factory CourseAPI() {
    instance ??= CourseAPI._();
    return instance!;
  }

  final String _pluginName = '课程表';
  // final HttpRequest _http = HttpRequest();
  final String _service = 'http://bkzhjx.wh.sdu.edu.cn/sso.jsp';
  final String _courseCacheKey = 'courseCache';
  final String _customCourseKey = 'customCourseKey';
  final String _coursesAPIPath = '${Server.edu}/course_schedule';
  JSAuthManager? authManager;

  Future<ResultEntity<List<Course>>> courses({bool useCache = true}) async {
    if (useCache) {
      try {
        String? cache = await CacheUtils.loadText(_courseCacheKey);
        if (cache != null) {
          List list = jsonDecode(cache);
          return ResultEntity.succeed(
              data: list.map((jsonMap) => Course.fromJson(jsonMap)).toList());
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    try {
      CipherPair pair =
          (await CipherPairAPI().pluginCipherPair(pluginId: _pluginName)).data!;
      String path = await _pluginAuthPath();
      JSAuthManager manager = JSAuthManager(
          username: pair.name,
          password: pair.password,
          scriptPath: path);
      String? cookie = await manager.cookie(_service);
      if (cookie == null) {
        return ResultEntity.error(message: '获取Cookie出错');
      }
      String base = await rootBundle.loadString('assets/js/base.js');
      String code = await JSAPI().jsCode(_coursesAPIPath);
      //指定调用函数方法名,并调用方法
      String result = await JSAPI().runJs('$base\n$code', params: [cookie]);
      Map<String, dynamic> data = jsonDecode(result);
      if (data['code'] == 0) {
        List list = data['data'];
        var res = list.map((jsonMap) => Course.fromJson(jsonMap)).toList();
        CacheUtils.cacheText(_courseCacheKey, jsonEncode(res));
        return ResultEntity.succeed(data: res);
      }
    } catch (e) {
      if (e is PasswordErrorException) {
        return ResultEntity.error(message: '获取失败,请检查统一身份认证账户是否正确');
      } else if (e is JSExecuteException) {
        return ResultEntity.error(message: '获取数据失败,执行代码出错');
      } else if (e is DioException) {
        debugPrint('获取cookie出错: ${e.response?.statusCode}');
        return ResultEntity.error(message: '获取cookie失败,网络错误');
      } else {
        return ResultEntity.error(message: '获取数据失败');
      }
    }
    return ResultEntity.error();
  }

  Future<List<Course>> customCourses() async {
    String? cache = await CacheUtils.loadText(_customCourseKey);
    if (cache != null) {
      List list = jsonDecode(cache);
      return list.map((jsonMap) => Course.fromJson(jsonMap)).toList();
    }
    return [];
  }

  Future<void> addCustomCourse(Course course) async {
    String? cache = await CacheUtils.loadText(_customCourseKey);
    List<Course> courses = [];
    if (cache != null) {
      List list = jsonDecode(cache);
      courses = list.map((jsonMap) => Course.fromJson(jsonMap)).toList();
    }
    courses.add(course);
    await CacheUtils.cacheText(_customCourseKey, jsonEncode(courses));
  }

  Future<void> removeCustomCourse(int courseId) async {
    String? cache = await CacheUtils.loadText(_customCourseKey);
    if (cache != null) {
      List list = jsonDecode(cache);
      var courses = list.map((jsonMap) => Course.fromJson(jsonMap)).toList();
      courses.removeWhere((c) => c.id == courseId);
      await CacheUtils.cacheText(_customCourseKey, jsonEncode(courses));
    }
  }

  Future<String> _pluginAuthPath() async {
    Map<String, String> res =
        jsonDecode(Store.get('pluginBindAuth', defaultValue: '{}')!)
            .cast<String, String>();
    if (res[_pluginName] == null || res[_pluginName]!.isEmpty) {
      var plugin = (await PluginAPI.getByTitle('中国科学院大学')).data!;
      return plugin.url;
    }
    var plugin = (await PluginAPI.getByTitle(res['plugin']!)).data!;
    return plugin.url;
  }
}
