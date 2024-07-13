import 'dart:convert';

import 'package:flutter/cupertino.dart';

import '../bean/cipher_pair.dart';
import '../bean/user_info.dart';
import '../utils/store_utils.dart';

class UserModel with ChangeNotifier {
  final String _userInfoKey = 'userInfo';
  bool _isLogin = false;
  UserInfo? _userInfo;

  UserInfo get userInfo => _userInfo!;

  bool get isLogin => _isLogin;


  set userInfo(UserInfo? info) {
    if (info == null) {
      Store.remove(_userInfoKey);
      _isLogin = false;
    } else {
      Store.set(_userInfoKey, jsonEncode(info));
      _userInfo = info;
      _isLogin = true;
    }
    notifyListeners();
  }

  void logout() {
    Store.remove('token');
    Store.remove(_userInfoKey);
    userInfo = null;
  }

  UserModel() {
    UserInfo? info;
    if (Store.containsKey(_userInfoKey)) {
      info = UserInfo.fromJson(jsonDecode(Store.get(_userInfoKey)!));
    }
    userInfo = info;
  }
}
