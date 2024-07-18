import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:icampus/api/plugin_api.dart';
import '../auth/js_auth_manager.dart';
import '../bean/cipher_pair.dart';
import '../bean/exam.dart';
import '../entity/result.dart';
import '../utils/cache_utils.dart';
import '../utils/store_utils.dart';
import 'base.dart';
import 'cipher_pair_api.dart';
import 'http_request.dart';
import 'js_api.dart';

class ExamAPI {
  static ExamAPI? instance;

  ExamAPI._();

  factory ExamAPI() {
    instance ??= ExamAPI._();
    return instance!;
  }

  final String _pluginName = '考试安排';

  final String _examCacheKey = 'examCache';
  final String _service = 'http://bkzhjx.wh.sdu.edu.cn/sso.jsp';
  final String _examsAPIPath = '${Server.edu}/exam';
  final HttpRequest _http = HttpRequest();

  Future<ResultEntity<List<Exam>>> exams({bool useCache = true}) async {
    if (useCache) {
      try {
        String? cache = await CacheUtils.loadText(_examCacheKey);
        if (cache != null) {
          List list = jsonDecode(cache);
          return ResultEntity.succeed(
              data: list.map((jsonMap) => Exam.fromJson(jsonMap)).toList());
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
          username: pair.name, password: pair.password, scriptPath: path);
      String? cookie = await manager.cookie(_service);
      if (cookie == null) {
        return ResultEntity.error(message: '获取Cookie出错');
      }
      ResultEntity<List> result =
          await JSAPI().rpcRunJS(await _pluginFunctionPath(), params: [cookie]);
      if (result.success) {
        List list = result.data!;
        var res = list.map((jsonMap) => Exam.fromJson(jsonMap)).toList();
        CacheUtils.cacheText(_examCacheKey, jsonEncode(res));
        return ResultEntity.succeed(data: res);
      } else {
        return ResultEntity.error(message: result.message);
      }
    } catch (e, stack) {
      debugPrintStack(stackTrace: stack, label: e.toString());
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
  }

  Future<String> _pluginAuthPath() async {
    Map<String, String> res =
        jsonDecode(Store.get('pluginBindAuth', defaultValue: '{}')!)
            .cast<String, String>();
    if (res[_pluginName] == null || res[_pluginName]!.isEmpty) {
      var plugin = (await PluginAPI.getByTitle('中国科学院大学')).data!;
      return plugin.url;
    }
    var plugin = (await PluginAPI.getByTitle(res[_pluginName]!)).data!;
    return plugin.url;
  }

  Future<String> _pluginFunctionPath() async {
    Map<String, String> res =
    jsonDecode(Store.get('pluginBindAuth', defaultValue: '{}')!)
        .cast<String, String>();
    if (res[_pluginName] == null || res[_pluginName]!.isEmpty) {
      var plugin = (await PluginAPI.getByTitle('中国科学院大学-$_pluginName')).data!;
      return plugin.url;
    }
    var plugin =
    (await PluginAPI.getByTitle('${res[_pluginName]!}-$_pluginName')).data!;
    return plugin.url;
  }
}
