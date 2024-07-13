import 'dart:convert';
import 'dart:math';

///课表课程信息
class Course {
  ///网络未指定id,本地指定随机id
  static final Random _random = Random();
  static int count = _random.nextInt(10000);

  ///后端返回的课程唯一id
  int id;

  ///课程号
  String courseId;

  ///课程名
  String courseName;

  ///上课地点
  String courseLocation;

  ///上课节次[1-5]
  int courseOrder;

  ///上课星期[1-7]
  int courseWeekday;

  ///教师
  String courseTeacher;

  ///是否是用户添加课程
  bool userCourse;

  ///开始时间和截止时间
  String startTime;
  String endTime;

  ///上课周
  List<int> courseWeeks;

  ///课序号
  int courseIndex;

  ///开课学院
  String academy;

  ///剩余课容量
  int remaining;

  ///种类
  String category;

  ///课程详情信息
  String courseInfo;

  ///学分,从[CourseAPI._mergeCourseCredit]获取
  double credit;

  ///考察方式,从[AcademicAPI.allEducationPlan]获取
  String examType;

  factory Course.empty() {
    return Course.fromJson({});
  }

  Course(
      {required this.id,
        required this.courseId,
        required this.courseName,
        required this.courseLocation,
        required this.courseOrder,
        required this.courseWeekday,
        required this.courseTeacher,
        required this.userCourse,
        required this.startTime,
        required this.endTime,
        required this.courseWeeks,
        required this.courseIndex,
        required this.academy,
        required this.credit,
        required this.remaining,
        required this.category,
        required this.courseInfo,
        required this.examType});

  factory Course.fromJson(Map<String, dynamic> jsonMap) {
    //每次给count随机增加一个数,实现hashcode的变化
    count += _random.nextInt(3) + 1;
    var course = Course(
      id: jsonMap["id"] ?? count,
      courseId: jsonMap["courseId"] ?? '$count',
      courseName: jsonMap["courseName"] ?? '',
      courseLocation: jsonMap["courseLocation"] ?? '',
      courseOrder: jsonMap["courseOrder"] ?? 0,
      courseWeekday: jsonMap["courseWeekday"] ?? 0,
      courseTeacher: jsonMap["courseTeacher"] ?? '',
      userCourse: jsonMap['userCourse'] ?? false,
      startTime: jsonMap['startTime'] ?? '00:00',
      endTime: jsonMap["endTime"] ?? '00:00',
      courseWeeks:
      (json.decode(jsonMap['courseWeeks'] ?? '[]') as List).cast<int>()
        ..sort(),
      courseIndex: jsonMap["courseIndex"] ?? 0,
      academy: jsonMap["courseAcademy"] ?? '',
      credit: jsonMap["credit"]?.toDouble() ?? 0.0,
      remaining: jsonMap["remaining"] ?? 0,
      category: jsonMap["category"] ?? '',
      courseInfo: jsonMap["courseInfo"] ?? '',
      examType: jsonMap["examType"] ?? '',
    );
    var end = DateTime.tryParse('20000101 ${course.startTime}:00')
        ?.add(const Duration(hours: 1, minutes: 50));
    if (end != null) {
      course.endTime = '${end.hour < 10 ? '0' : ''}${end.hour}'
          ':${end.minute < 10 ? '0' : ''}${end.minute}';
    } else {
      course.endTime = '00:00';
    }
    return course;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'courseName': courseName,
      'courseLocation': courseLocation,
      'courseOrder': courseOrder,
      'courseWeekday': courseWeekday,
      'courseTeacher': courseTeacher,
      'userCourse': userCourse,
      'startTime': startTime,
      'endTime': endTime,
      'courseWeeks': jsonEncode(courseWeeks),
      'courseIndex': courseIndex,
      'academy': academy,
      'credit': credit,
      'remaining': remaining,
      'category': category,
      'courseInfo': courseInfo,
      'examType': examType,
    };
  }

}
