import 'package:equatable/equatable.dart';

import '../api/base.dart';

class Plugin extends Equatable {
  final String name;
  final String description;
  final String url;
  final List<String> creator;
  final DateTime updateTime;
  final DateTime createTime;
  final String version;
  final bool hide;
  final String type;

  const Plugin({
    required this.name,
    required this.description,
    required this.url,
    required this.creator,
    required this.updateTime,
    required this.createTime,
    required this.version,
    required this.hide,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': name,
      'description': description,
      'content': url,
      'creator': creator,
      'update_at': updateTime.toString(),
      'create_at': createTime.toString(),
      'version': version,
      'hide': hide,
      'type': type,
      'tag': type,
    };
  }

  factory Plugin.fromJson(Map<String, dynamic> map) {
    return Plugin(
      name: map['title'] as String,
      description: map['description'] ?? '',
      // url: '${Server.baseUrl}/extension/get-by-title?title=${map['title']}',
      url: map['content'] ?? '',
      creator: map['creator']?.cast<String>() ?? [],
      updateTime: DateTime.parse(map['update_at'] ?? DateTime.now().toString()),
      createTime: DateTime.parse(map['create_at'] ?? DateTime.now().toString()),
      version: map['version'] ?? '1.0.0',
      hide: !'${map['tag']}'.contains('container') &&
          !'${map['tag']}'.contains('listview'),
      type: map['tag'] ?? '',
    );
  }

  @override
  List<Object> get props => [
        name,
        description,
        url,
        creator,
        updateTime,
        createTime,
        version,
        hide,
        type,
      ];

  Plugin copyWith({
    String? name,
    String? description,
    String? url,
    List<String>? creator,
    DateTime? updateTime,
    DateTime? createTime,
    String? version,
    bool? hide,
    String? type,
  }) {
    return Plugin(
      name: name ?? this.name,
      description: description ?? this.description,
      url: url ?? this.url,
      creator: creator ?? this.creator,
      updateTime: updateTime ?? this.updateTime,
      createTime: createTime ?? this.createTime,
      version: version ?? this.version,
      hide: hide ?? this.hide,
      type: type ?? this.type,
    );
  }
}

class PluginPermission {
  String key;
  String name;
  String description;
  String value;
  bool required;
  String state;

  PluginPermission({
    String? key,
    required this.name,
    required this.description,
    required this.value,
    required this.required,
    required this.state,
  }) : key = key ?? '$name-$value';

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'name': name,
      'description': description,
      'value': value,
      'required': required,
      'state': state
    };
  }

  factory PluginPermission.fromJson(Map<String, dynamic> map) {
    return PluginPermission(
        key: map['key'],
        name: map['name'] ?? '',
        description: map['description'] ?? '',
        value: map['value'] ?? '',
        required: map['required'] ?? false,
        state: map['state'] ?? PermissionStatus.prompt);
  }

  PluginPermission copyWith(
      {String? key,
      String? name,
      String? description,
      String? value,
      bool? required,
      String? state}) {
    return PluginPermission(
        key: key ?? this.key,
        name: name ?? this.name,
        description: description ?? this.description,
        value: value ?? this.value,
        required: required ?? this.required,
        state: state ?? this.state);
  }
}

class PermissionStatus {
  static const String granted = 'granted';
  static const String denied = 'denied';
  static const String prompt = 'prompt';
}
