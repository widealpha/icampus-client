import 'package:dio/dio.dart';

import '../../utils/http_utils.dart';
import '../bean/studyroom.dart';
import 'base.dart';

class StudyRoomAPI {
  static StudyRoomAPI? _instance;


  StudyRoomAPI._();

  factory StudyRoomAPI() {
    _instance ??= StudyRoomAPI._();
    return _instance!;
  }

  final String _getBuildings = 'https://handfisher.uk/world_first/core/studyroom/buildings';
  final String _getStudyRoomData = 'https://handfisher.uk/world_first/core/studyroom/data';

  ///获取自习室楼数据
  Future<List<String>> studyRoomBuildings(String campus) async {
    //读取缓存
    var response = await Dio().get(
      _getBuildings,
      queryParameters: {'campus': campus},
    );
    if (response.data['code'] == 0) {
      List list = response.data['data'];
      return list.cast<String>();
    } else {
      return [];
    }
  }

  Future<List<StudyRoom>> getStudyRoomData(
      String campus, String building, String date) async {
    //将yyyy-MM-dd格式的字符串转化为yyyyMMdd形式的后端可以解析的格式
    date = date.replaceAll('-', '');
    List<StudyRoom> studyRooms = [];
    try {
      Response response = await Dio().get(_getStudyRoomData,

          queryParameters: {'campus': campus, 'building': building, 'date': date});
      Map<String, dynamic> responseData = response.data;
      if (responseData['code'] == 0) {
        responseData['data'].forEach((room, status) {
          List list = status;
          studyRooms.add(StudyRoom(
              classroom: room, free: list.map((b) => b == 0).toList()));
        });
      }
    } catch (e) {
      return [];
    }
    return studyRooms;
  }
}
