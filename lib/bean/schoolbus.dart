/// 校车
class SchoolBus {
  /// 始发站
  final String from;

  /// 终点站
  final String to;

  /// 途径
  final String pass;

  /// 时间
  final String time;

  SchoolBus({
    required this.from,
    required this.to,
    required this.pass,
    required this.time,
  });

  factory SchoolBus.fromJson(Map<String, dynamic> json) {
    return SchoolBus(
      from: json["s"] ?? '',
      to: json["e"] ?? '',
      pass: json["p"] ?? '',
      time: json["t"] ?? '',
    );
  }
}
