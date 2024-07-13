import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../auth/auth_manager.dart';
import '../auth/sdu_auth_manager.dart';

class HttpRequest {
  final Dio _dio = Dio();
  late final AuthManager _authManager;

  static HttpRequest? _instance;

  HttpRequest._(bool debug) {
    _authManager = SduAuthManager(debug: debug);
  }

  factory HttpRequest({bool debug = kDebugMode}) {
    _instance ??= HttpRequest._(debug);
    return _instance!;
  }

  Future<void> clearCache() async {
    _authManager.clearCookies();
  }

  Future<Response<T>> get<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.get(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<String?> cookie(String service) async {
    return _authManager.cookie(service);
  }
}

class TGTInvalidException implements Exception {}

class CookieInvalidException implements Exception {}

class PasswordErrorException implements Exception {}
