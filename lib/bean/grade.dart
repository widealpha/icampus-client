class Grade {
  String courseId;
  String courseParam;
  String courseName;
  String dailyScore;
  String examScore;
  String totalScore;
  String level;
  String credit;
  String gpa;
  String highestScore;
  String lowestScore;
  String type;
  String semester;

  Grade({
    required this.courseId,
    required this.courseParam,
    required this.courseName,
    required this.dailyScore,
    required this.examScore,
    required this.totalScore,
    required this.level,
    required this.credit,
    required this.gpa,
    required this.highestScore,
    required this.lowestScore,
    required this.type,
    required this.semester,
  });

  Map<String, dynamic> toJson() {
    return {
      'courseParam': courseParam,
      'courseId': courseId,
      'courseName': courseName,
      'dailyScore': dailyScore,
      'examScore': examScore,
      'totalScore': totalScore,
      'level': level,
      'credit': credit,
      'gpa': gpa,
      'highestScore': highestScore,
      'lowestScore': lowestScore,
      'type': type,
      'semester': semester,
    };
  }

  factory Grade.fromJson(Map<String, dynamic> map) {
    return Grade(
      courseId: map['courseId'] ?? '',
      courseParam: map['courseParam'] ?? '',
      courseName: map['courseName'] ?? '',
      dailyScore: map['dailyScore'] ?? '',
      examScore: map['examScore'] ?? '',
      totalScore: map['totalScore'] ?? '',
      level: map['level'] ?? '',
      credit: map['credit'] ?? '',
      gpa: map['gpa'] ?? '',
      highestScore: map['highestScore'] ?? '',
      lowestScore: map['lowestScore'] ?? '',
      type: map['type'] ?? '',
      semester: map['semester'] ?? '',
    );
  }
}
