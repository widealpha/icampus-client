import 'package:dio/dio.dart';

import 'package_info_utils.dart';

class HttpUtils {
  static final HttpBase _http = HttpBase();

  static Future<Response<T>> get<T>(String path,
      {Object? data,
      Map<String, dynamic>? params,
      Options? options,
      CancelToken? cancelToken,
      ProgressCallback? onReceiveProgress}) async {
    return _http.get<T>(path,
        data: data,
        queryParameters: params,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress);
  }

  static Future<Response<T>> post<T>(String path,
      {Object? data,
      Map<String, dynamic>? params,
      Options? options,
      CancelToken? cancelToken,
      ProgressCallback? onSendProgress,
      ProgressCallback? onReceiveProgress}) async {
    return _http.post<T>(path,
        data: data,
        queryParameters: params,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress);
  }

  static Future<Response> download(
    String url,
    dynamic savePath, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
    ProgressCallback? onReceiveProgress,
    bool deleteOnError = true,
    String lengthHeader = Headers.contentLengthHeader,
  }) async {
    return _http.download(url, savePath,
        data: data,
        queryParameters: queryParameters,
        options: options,
        deleteOnError: deleteOnError,
        lengthHeader: lengthHeader,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress);
  }

  static Future<Response<T>> request<T>(String path,
      {Object? data,
      Map<String, dynamic>? params,
      Options? options,
      CancelToken? cancelToken,
      ProgressCallback? onReceiveProgress}) async {
    return _http.request<T>(path,
        data: data,
        queryParameters: params,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress);
  }

  static void config(
      {String baseUrl = '',
      Duration connectTimeout = const Duration(seconds: 10),
      Duration receiveTimeout = const Duration(seconds: 10)}) {
    _http.config(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout));
  }
}

class HttpBase {
  static HttpBase? _singleton;
  late final Dio _dio;
  late final int version;

  factory HttpBase() {
    _singleton ??= HttpBase._();
    return _singleton!;
  }

  HttpBase._() {
    _dio = Dio();
    version = PackageInfoUtils.versionCode;
  }

  void config(BaseOptions options) {
    _dio.options = options..headers['S-VERSION'] = version;
  }

  Future<Response<T>> get<T>(String path,
      {Object? data,
      Map<String, dynamic>? queryParameters,
      Options? options,
      CancelToken? cancelToken,
      ProgressCallback? onSendProgress,
      ProgressCallback? onReceiveProgress}) async {
    return _dio.get<T>(path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress);
  }

  Future<Response<T>> post<T>(String path,
      {Object? data,
      Map<String, dynamic>? queryParameters,
      Options? options,
      CancelToken? cancelToken,
      ProgressCallback? onSendProgress,
      ProgressCallback? onReceiveProgress}) async {
    return _dio.post<T>(path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress);
  }

  Future<Response<T>> request<T>(
    String url, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    return _dio.request<T>(url,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress);
  }

  Future<Response> download(
    String url,
    dynamic savePath, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
    ProgressCallback? onReceiveProgress,
    bool deleteOnError = true,
    String lengthHeader = Headers.contentLengthHeader,
  }) async {
    return _dio.download(url, savePath,
        data: data,
        queryParameters: queryParameters,
        options: options,
        deleteOnError: deleteOnError,
        lengthHeader: lengthHeader,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress);
  }
}
