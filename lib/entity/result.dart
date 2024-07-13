///状态码Status Code
enum SC {
  success(0, '请求成功'),

  ///服务器未知错误
  serverError(-1, '服务器错误'),

  ///未知错误
  unknownError(-10001, '未知错误'),

  ///用户端设备错误
  deviceError(-10002, '客户端错误'),

  ///用户取消操作
  userCancel(-10003, '用户取消'),

  ///无操作
  noOperation(-10004, '无操作'),

  ///超时
  timeout(-10005, '超时'),
  ;

  const SC(this.code, this.reason);

  final String reason;
  final int code;
}

class ResultEntity<T> {
  static final Map<int, SC> _scMap = {};
  final bool success;
  final SC code;
  final String message;
  final T? data;

  ///成功实体
  ///[code]状态信息
  ///[message] 默认为code中的reason信息,提供后会覆写code中包含的reason信息
  ///[data] 请求实体的返回值
  factory ResultEntity.succeed(
      {SC code = SC.success, String? message, T? data}) {
    message ??= SC.success.reason;
    return ResultEntity._(
        success: true, code: code, message: message, data: data);
  }

  ///失败实体
  ///[code]状态信息
  ///[message] 默认为code中的reason信息,提供后会覆写code中包含的reason信息
  ///[data] 请求实体的返回值
  factory ResultEntity.error(
      {SC code = SC.serverError, String? message, T? data}) {
    message ??= SC.serverError.reason;
    return ResultEntity._(
        success: false, code: code, message: message, data: data);
  }

  ///用户取消
  ///[message] 默认为code中的reason信息,提供后会覆写code中包含的reason信息
  ///[data] 请求实体的返回值
  factory ResultEntity.cancel({String? message, T? data}) {
    message ??= SC.userCancel.reason;
    return ResultEntity._(
        success: false, code: SC.userCancel, message: message, data: data);
  }

  ///无操作
  ///[message] 默认为code中的reason信息,提供后会覆写code中包含的reason信息
  ///[data] 请求实体的返回值
  factory ResultEntity.nop({String? message, T? data}) {
    message ??= SC.noOperation.reason;
    return ResultEntity._(
        success: false, code: SC.userCancel, message: message, data: data);
  }

  ///无操作
  ///[message] 默认为code中的reason信息,提供后会覆写code中包含的reason信息
  ///[data] 请求实体的返回值
  factory ResultEntity.fromSC(SC sc, {T? data}) {
    return ResultEntity._(
        success: false, code: sc, message: sc.reason, data: data);
  }

  ///失败实体
  ///[code]状态信息
  ///[data] 请求实体的返回值
  factory ResultEntity.timeout({SC code = SC.timeout, T? data}) {
    return ResultEntity._(
        success: false, code: code, message: '请求超时', data: data);
  }

  ///用户取消
  ///[code]对应[SC]中的[SC.code]信息,通过该code生成SC,不存在在该code则返回[SC.UNKNOWN_ERROR]
  ///[message] 默认为code中的reason信息,提供后会覆写code中包含的reason信息
  ///[data] 请求实体的返回值
  factory ResultEntity.fromCode({int? code, String? message, T? data}) {
    if (_scMap.isEmpty) {
      for (var sc in SC.values) {
        _scMap[sc.code] = sc;
      }
    }
    if (code == null) {
      return ResultEntity.error(
        code: SC.unknownError,
        message: message ?? SC.unknownError.reason,
        data: data,
      );
    } else if (code == 0) {
      return ResultEntity.succeed(
        code: SC.success,
        message: message ?? SC.success.reason,
        data: data,
      );
    } else {
      SC statusCode =
          _scMap.containsKey(code) ? _scMap[code]! : SC.unknownError;
      return ResultEntity.error(
        code: statusCode,
        message: message ?? statusCode.reason,
        data: data,
      );
    }
  }

  const ResultEntity._(
      {required this.success,
      required this.code,
      required this.message,
      this.data});

  ResultEntity copyWith({
    bool? result,
    SC? code,
    String? message,
    T? data,
    SC? statusCode,
  }) {
    return ResultEntity._(
      success: result ?? this.success,
      code: code ?? this.code,
      message: message ?? this.message,
      data: data ?? this.data,
    );
  }

  @override
  String toString() {
    return 'ResultEntity{success: $success, code: $code, message: $message, data: $data}';
  }
}
