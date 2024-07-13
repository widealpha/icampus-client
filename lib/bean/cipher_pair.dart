class CipherPair {
  ///密钥id
  int id;

  ///用户名
  String name;

  ///密码
  String password;

  ///其他认证字段
  String key;

  CipherPair({
    required this.id,
    required this.name,
    required this.password,
    required this.key,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'pwd': password,
      'key': key,
    };
  }

  factory CipherPair.fromJson(Map<String, dynamic> map) {
    return CipherPair(
      name: map['name'] as String,
      password: map['pwd'] as String,
      key: map['key'] as String,
      id: map['id'] as int,
    );
  }
}
