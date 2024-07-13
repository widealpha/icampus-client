import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

import '../bean/user_info.dart';
import '../entity/result.dart';
import '../utils/extensions/response_extension.dart';
import '../utils/http_utils.dart';
import '../utils/store_utils.dart';

class UserAPI {
  static UserAPI? _instance;

  UserAPI._();

  factory UserAPI() {
    _instance ??= UserAPI._();
    return _instance!;
  }

  Future<ResultEntity<void>> login(
      {required String username, required String password}) async {
    try {
      var response = await HttpUtils.post('/login',
          data: {'email': username, 'password': password});
      if (response.ok) {
        await Store.set('token', 'Bearer ${response.data['data']['token']}');

        return ResultEntity.succeed();
      } else {
        return ResultEntity.error(message: response.data['message']);
      }
    } catch (e, stack) {
      debugPrintStack(stackTrace: stack, label: e.toString());
      return ResultEntity.error();
    }
  }

  Future<ResultEntity<void>> register(
      {required String username, required String password}) async {
    var response = await HttpUtils.post('/register',
        data: {'username': username, 'password': password});
    if (response.ok) {
      return ResultEntity.succeed();
    } else {
      return ResultEntity.error(message: response.data['message']);
    }
  }

  Future<ResultEntity<UserInfo>> userInfo() async {
    try {
      var response = await HttpUtils.get('/user/getInfo',
          options: Options(headers: {'Authorization': Store.get('token')}));
      if (response.ok) {
        UserInfo info = UserInfo.fromJson(response.data['data']);
        return ResultEntity.succeed(data: info);
      } else {
        return ResultEntity.error(message: response.data['message']);
      }
    } catch (e, stack) {
      debugPrintStack(stackTrace: stack, label: e.toString());
      return ResultEntity.error();
    }
  }
}
