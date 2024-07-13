import 'package:dio/dio.dart';

class Server {
  static const String host = 'https://widealpha.top';
  static const String baseUrl = '$host/icampus';
  static const String auth = "/auth";
  static const String core = "/core";
  static const String edu = "/edu";
  static const String user = "/auth/user";
  static const String library = "/library";
  static const String forum = "/forum";
  static const String pic = "/pic";
}

extension ResponseExtension on Response {
  bool get valid {
    return data != null && data['code'] == 0;
  }
}
