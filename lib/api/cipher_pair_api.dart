import 'package:dio/dio.dart';

import '../bean/cipher_pair.dart';
import '../entity/result.dart';
import '../utils/extensions/response_extension.dart';
import '../utils/http_utils.dart';
import '../utils/store_utils.dart';

class CipherPairAPI {
  static CipherPairAPI? _instance;

  CipherPairAPI._();

  factory CipherPairAPI() {
    _instance ??= CipherPairAPI._();
    return _instance!;
  }

  final String _defaultCipher = 'default-cipher';

  Future<ResultEntity<void>> add(CipherPair cipherPair) async {
    var response = await HttpUtils.post('/cipherpair/add',
        data: cipherPair.toJson(),
        options: Options(headers: {'Authorization': Store.get('token')}));
    if (response.ok) {
      return ResultEntity.succeed();
    } else {
      return ResultEntity.error(message: response.data['message']);
    }
  }

  Future<ResultEntity<List<CipherPair>>> list() async {
    var response = await HttpUtils.get('/cipherpair/list',
        options: Options(headers: {'Authorization': Store.get('token')}));
    if (response.ok) {
      List list = response.data['data'];
      return ResultEntity.succeed(
          data: list.map((e) => CipherPair.fromJson(e)).toList());
    } else {
      return ResultEntity.error(message: response.data['message']);
    }
  }

  Future<ResultEntity<List<CipherPair>>> delete(
      {required int cipherPairId}) async {
    var response = await HttpUtils.get('/cipherpair/delete',
        data: {'id': cipherPairId},
        options: Options(headers: {'Authorization': Store.get('token')}));
    if (response.ok) {
      return ResultEntity.succeed();
    } else {
      return ResultEntity.error(message: response.data['message']);
    }
  }

  Future<ResultEntity<CipherPair>> pluginCipherPair(
      {required String pluginId}) async {
    int? cipherId = Store.get('$pluginId-cipher');
    if (cipherId == null) {
      return defaultCipherPair();
    } else {
      var result = await list();
      return ResultEntity.succeed(
          data: result.data!.firstWhere((element) => element.id == cipherId,
              orElse: () => result.data!.first));
    }
  }

  Future<ResultEntity<CipherPair>> defaultCipherPair() async {
    int? cipherId = Store.get(_defaultCipher);
    var result = await list();
    if (!result.success || result.data!.isEmpty) {
      return ResultEntity.error(message: '没有设置默认密钥');
    }
    if (cipherId == null) {
      return ResultEntity.succeed(data: result.data!.first);
    } else {
      return ResultEntity.succeed(
          data: result.data!.firstWhere((element) => element.id == cipherId,
              orElse: () => result.data!.first));
    }
  }

  Future<ResultEntity<void>> setDefaultCipherPair(
      {required int cipherPairId}) async {
    await Store.set(_defaultCipher, cipherPairId);
    return ResultEntity.succeed();
  }

  bool get hasDefaultCipherPair {
    return Store.containsKey(_defaultCipher);
  }
}
