import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_js/extensions/fetch.dart';
import 'package:flutter_js/flutter_js.dart';
import '../entity/result.dart';
import '../utils/cache_utils.dart';
import '../utils/http_utils.dart';
import 'base.dart';

class JSAPI {
  static JSAPI? _instance;

  JSAPI._();

  factory JSAPI() {
    _instance ??= JSAPI._();
    return _instance!;
  }

  Future<String> jsCode(String apiPath,
      {Map<String, String> headers = const {}}) async {
    String? jsCode = await CacheUtils.loadText(apiPath);
    if (jsCode == null) {
      var response =
          await HttpUtils.get(apiPath, options: Options(headers: headers));
      jsCode = response.data;
      await CacheUtils.cacheLongText(
        apiPath,
        jsCode!,
        expires: Duration.zero
        // expires: const Duration(hours: 24),
      );
    }
    return jsCode;
  }

  Future<ResultEntity<T>> rpcRunJS<T>(String path,
      {String functionName = 'execute',
      List<String> params = const [],
      Map<String, String> headers = const {}}) async {
    try {
      // String base = await rootBundle.loadString('assets/js/base.js');
      String base = '';
      String code = await jsCode(path, headers: headers);
      //指定调用函数方法名,并调用方法
      String result = await runJs('$base\n$code',
          functionName: functionName, params: params);
      Map<String, dynamic> res = jsonDecode(result);
      if (res['code'] == 0 || res['code'] == 1) {
        return ResultEntity.succeed(message: res['message'], data: res['data']);
      } else {
        return ResultEntity.error(message: res['message']);
      }
    } catch (e, stack) {
      debugPrintStack(stackTrace: stack, label: e.toString());
      if (e is JSExecuteException) {
        return ResultEntity.error(message: '执行代码出错');
      }
      return ResultEntity.error(message: '远程服务调用失败');
    }
  }

  Future<String> runJs(String code,
      {String functionName = 'execute', List<String> params = const []}) async {
    StringBuffer paramBuff = StringBuffer();
    for (var param in params) {
      paramBuff.write(param);
    }
    String paramString = params.join('","');
    if (paramString.isNotEmpty) {
      paramString = '"$paramString"';
    }
    String functionCall = '$code\n$functionName($paramString);\n';
    var javascriptRuntime = getJavascriptRuntime();
    await javascriptRuntime.enableFetch();
    JsEvalResult asyncResult =
        await javascriptRuntime.evaluateAsync(functionCall);
    javascriptRuntime.executePendingJob();
    final promiseResolved = await javascriptRuntime.handlePromise(asyncResult);
    if (promiseResolved.isError) {
      throw JSExecuteException(message: promiseResolved.stringResult);
    }
    return promiseResolved.stringResult;
  }
}

class JSExecuteException {
  String? message;

  JSExecuteException({this.message});

  @override
  String toString() {
    return 'JSExecuteException{message: $message}';
  }
}
