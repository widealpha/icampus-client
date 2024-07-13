import 'package:dio/dio.dart';

extension ContextExtension on Response {
  bool get ok {
    return statusCode != null &&
        statusCode! < 400 &&
        data != null &&
        data['status'] == 200;
  }

  String? get message {
    return data?['message'];
  }
}
