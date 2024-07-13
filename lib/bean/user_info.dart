class UserInfo {
  String username;

  UserInfo({
    required this.username,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
    };
  }

  factory UserInfo.fromJson(Map<String, dynamic> map) {
    return UserInfo(
      username: map['username'] as String,
    );
  }
}
