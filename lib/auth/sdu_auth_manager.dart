import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:retry/retry.dart';
import 'package:synchronized/synchronized.dart';

import '../utils/store_utils.dart';
import 'auth_manager.dart';

class SduAuthManager extends AuthManager {
  static const usernameKey = 'sdu-user';
  static const passwordKey = 'sdu-password';
  static const baseCasUrl = 'https://pass.sdu.edu.cn/cas/login?service=';

  final Dio _dio = Dio();
  final _cookieJar = CookieJar();

  String? _tgt;
  final Lock _tgtLock = Lock();
  final _serviceCookie = <String, String>{};

  static SduAuthManager? _instance;

  SduAuthManager._({bool debug = false}) : super(debug: debug) {
    _dio.interceptors.add(CookieManager(_cookieJar));
  }

  factory SduAuthManager({bool debug = false}) {
    _instance ??= SduAuthManager._(debug: debug);
    return _instance!;
  }

  @override
  Future<String?> cookie(String service) async {
    if (_serviceCookie.containsKey(service)) {
      //校验cookie是否有效,有效直接返回
      String cookie = _serviceCookie[service]!;
      var response = await _dio.get(service);
      if (response.redirects.every(
          (redirect) => !redirect.location.toString().contains(baseCasUrl))) {
        if (debug) {
          debugPrint('$service: use cached auth');
        }
        return cookie;
      }
    }
    if (debug) {
      debugPrint('$service: fetch new auth');
    }
    //预先请求服务,获取请求服务的凭证
    var response = await _dio.get(service);
    service = Uri.encodeFull(service);
    String casUrl = '$baseCasUrl$service';
    //通过retry配合锁机制
    await _doLoginTgt();
    //通过TGT获取ticket
    response = await retry(
        () async {
          try {
            return await _dio.post(
                'https://pass.sdu.edu.cn/cas/restlet/tickets/$_tgt',
                data: 'service=$service');
          } catch (e) {
            //500代表tgt过期
            if (e is DioException && e.response?.statusCode == 500) {
              debugPrint('TGT失效');
              throw TGTInvalidException();
            } else {
              rethrow;
            }
          }
        },
        retryIf: (e) => e is TGTInvalidException,
        onRetry: (e) async {
          if (debug) {
            debugPrint('user TGT invalidate, retry');
          }
          //置空tgt,很重要,涉及到上文的锁机制
          //通过tgt置空重入锁,否则无法进入doLoginTgt的登录逻辑中
          _tgt = null;
          await _doLoginTgt();
        });
    //通过ticket获取cookie
    response = await _dio.get(service,
        queryParameters: {'ticket': '${response.data}'},
        options: Options(
            headers: {"Referer": casUrl},
            followRedirects: false,
            validateStatus: (status) {
              return status != null && status < 400;
            }));
    const maxRedirect = 8;
    var redirects = 0;
    while (response.statusCode == 302) {
      if (++redirects > maxRedirect) {
        return null;
      }
      final redirectUri = Uri.parse(response.headers['location']![0]);
      Uri uri = response.realUri;
      response = await _dio.getUri(uri.resolveUri(redirectUri),
          options: Options(
              followRedirects: false,
              validateStatus: (status) {
                return status != null && status < 400;
              }));
    }
    // if (site == 'card') {
    //   var document = html.parse(response.data);
    //   response = await _dio.getUri(
    //       Uri.parse('https://card2.sdu.edu.cn:8757/cassyno/index'),
    //       data: FormData.fromMap({
    //         'ssoticketid':
    //         document.getElementById('ssoticketid')?.attributes['value'],
    //         'errorcode': '1',
    //         'continueurl': ''
    //       }),
    //       options: Options(
    //           followRedirects: false,
    //           validateStatus: (status) {
    //             return status != null && status < 400;
    //           }));
    // }

    var cookieList = await _cookieJar.loadForRequest(response.realUri);
    String cookie =
        cookieList.map((cookie) => '${cookie.name}=${cookie.value}').join(';');
    if (debug) {
      debugPrint('$service: $cookie');
    }
    _serviceCookie[service] = cookie;
    return cookie;
  }

  @override
  Future<void> clearCookies() async {
    _tgt = null;
    _serviceCookie.clear();
    await _cookieJar.deleteAll();
  }

  @override
  Future<bool> removeCookie(String service) async {
    if (_serviceCookie.containsKey(service)) {
      _serviceCookie.remove(service);
      return true;
    }
    return false;
  }

  Future<bool> _doLoginTgt() async {
    //同步锁
    return await _tgtLock.synchronized(() async {
      //很重要,通过此处标记进来的请求,不会再次请求TGT
      if (_tgt != null) {
        return true;
      }

      String? username = await SecureStore.read(usernameKey);
      String? password = await SecureStore.read(passwordKey);
      if (debug) {
        debugPrint('$username: fetch TGT');
      }
      try {
        var response = await _dio.post(
          'https://pass.sdu.edu.cn/cas/restlet/tickets',
          data: 'username=$username&password=$password',
        );
        _tgt = response.data;
        return true;
      } on DioException catch (e) {
        debugPrint('获取TGT失败: ${e.response?.statusCode}');
        if (e.response?.statusCode == 400) {
          throw PasswordErrorException();
        }
        rethrow;
      } catch (e) {
        debugPrint('获取TGT失败,网络错误');
        rethrow;
      }
    }, timeout: const Duration(seconds: 10));
  }
}
