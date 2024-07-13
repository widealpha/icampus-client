import 'dart:convert';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';

import '../api/js_api.dart';
import '../main.dart';
import 'auth_manager.dart';

class JSAuthManager extends AuthManager {
  final String username;
  final String password;
  final String scriptPath;
  final Map<String, String> _cacheCookie = {};
  // final CookieJar _cookieJar = CookieJar();

  JSAuthManager({
    required this.username,
    required this.password,
    required this.scriptPath,
  });

  @override
  Future<void> clearCookies() async {
    _cacheCookie.clear();
    // return _cookieJar.deleteAll();
  }

  @override
  Future<String?> cookie(String service) async {
    // Uri uri = Uri.parse(service);
    // var cookieList = await _cookieJar.loadForRequest(uri);
    //如果cookiejar中没有cookie那么执行相应的js脚本获取cookie
    //否则从cookiejar中读取cookie并快速返回
    if (!_cacheCookie.containsKey(service)) {
      var response =
          await JSAPI().rpcRunJS(scriptPath, functionName: 'captcha', params: []);
      String validateCode = '';
      if (response.success) {
        validateCode =
            await _showCaptcha(response.data['url'], response.data['cookie']);
      }
      Map<String, String> cookieMap = {};
      var loginRes = await JSAPI().rpcRunJS(scriptPath,
          functionName: 'login',
          params: [username, password, validateCode, response.data['cookie']]);
      if (loginRes.success) {
        cookieMap.addAll(jsonDecode(loginRes.data).cast<String, String>());
      }
      List<Cookie> cookies =
          cookieMap.entries.map((e) => Cookie(e.key, e.value)).toList();

      String cookie =
          cookies.map((cookie) => '${cookie.name}=${cookie.value}').join(';');
      _cacheCookie[service] = cookie;
      return cookie;
    } else {
      // String cookie = cookieList
      //     .map((cookie) => '${cookie.name}=${cookie.value}')
      //     .join(';');
      return _cacheCookie[service];
    }
  }

  Future<String> _showCaptcha(String url, String cookie) async {
    String validateCode = await showDialog<String>(
            context: navigatorKey.currentContext!,
            builder: (context) {
              TextEditingController controller = TextEditingController();
              return AlertDialog(
                title: const Text('验证码'),
                content: Column(
                  children: [
                    Image.network(url, headers: {'cookie': cookie}),
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(labelText: '请输入验证码'),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('取消')),
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context, controller.text);
                      },
                      child: const Text('确认')),
                ],
              );
            }) ??
        '';
    return validateCode;
  }

  @override
  Future<bool> removeCookie(String service) async {
    _cacheCookie.remove(service);
    // await _cookieJar.delete(Uri.parse(service));
    return true;
  }
}
