class Exam {
  String courseId;
  String courseName;
  String campus;
  String method;
  String location;
  String time;
  String seat;

  Exam({
    required this.courseId,
    required this.courseName,
    required this.campus,
    required this.method,
    required this.location,
    required this.time,
    required this.seat,
  });

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'courseName': courseName,
      'campus': campus,
      'method': method,
      'location': location,
      'time': time,
      'seat': seat,
    };
  }

  factory Exam.fromJson(Map<String, dynamic> map) {
    return Exam(
      courseId: map['courseId'] ?? '',
      courseName: map['courseName'] ?? '',
      campus: map['campus'] ?? '',
      method: map['method'] ?? '',
      location: map['location'] ?? '',
      time: map['time'] ?? '',
      seat: map['seat'] ?? '',
    );
  }
}
