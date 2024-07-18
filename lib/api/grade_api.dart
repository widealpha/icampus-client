import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:icampus/api/plugin_api.dart';

import '../auth/js_auth_manager.dart';
import '../bean/cipher_pair.dart';
import '../entity/result.dart';
import '../bean/grade.dart';
import '../utils/store_utils.dart';
import 'base.dart';
import 'cipher_pair_api.dart';
import 'http_request.dart';
import 'js_api.dart';

class GradeAPI {
  static GradeAPI? instance;

  GradeAPI._();

  factory GradeAPI() {
    instance ??= GradeAPI._();
    return instance!;
  }

  final HttpRequest _http = HttpRequest();
  final String _service = 'http://bkzhjx.wh.sdu.edu.cn/sso.jsp';
  final String _coursesAPIPath = '${Server.edu}/grade';
  final String _pluginName = '成绩查询';

  Future<ResultEntity<List<Grade>>> grades(String semester) async {
    try {
      CipherPair pair =
          (await CipherPairAPI().pluginCipherPair(pluginId: _pluginName)).data!;
      String authPath = await _pluginAuthPath();
      JSAuthManager manager = JSAuthManager(
          username: pair.name, password: pair.password, scriptPath: authPath);
      String? cookie = await manager.cookie(_service);
      if (cookie == null) {
        return ResultEntity.error(message: '获取Cookie出错');
      }
      ResultEntity<List> result =
          await JSAPI().rpcRunJS(await _pluginFunctionPath(), params: [cookie, semester]);
      if (result.success) {
        return ResultEntity.succeed(
            data: result.data!
                .map((jsonMap) => Grade.fromJson(jsonMap))
                .toList());
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
