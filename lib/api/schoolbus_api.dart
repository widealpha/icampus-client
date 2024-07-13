import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

import '../../utils/http_utils.dart';
import '../bean/schoolbus.dart';
import 'base.dart';

class SchoolBusAPI {
  static SchoolBusAPI? _instance;
  final String _searchSchoolBus = 'https://handfisher.uk/world_first/core/schoolbus';

  SchoolBusAPI._();

  factory SchoolBusAPI() {
    _instance ??= SchoolBusAPI._();
    return _instance!;
  }

  Future<List<SchoolBus>> searchSchoolBus(
      String from, String to, bool weekend) async {
    try {
      var response = (await Dio().get(_searchSchoolBus,
              queryParameters: {'start': from, 'end': to, 'isWeekend': weekend ? 1 : 0}))
          .data;
      if (response == null || response['code'] != 0) {
        return [];
      }
      List dataList = response['data'];
      return dataList.map((e) => SchoolBus.fromJson(e)).toList();
    } catch (e) {
      debugPrint(e.toString());
    }
    return [];
  }
}
