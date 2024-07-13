import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../../bean/plugin.dart';
import '../../../utils/store_utils.dart';

class PluginSettingPage extends StatefulWidget {
  final Plugin plugin;

  const PluginSettingPage({super.key, required this.plugin});

  @override
  State<PluginSettingPage> createState() => _PluginSettingPageState();
}

class _PluginSettingPageState extends State<PluginSettingPage> {
  final Box<String> _permissionBox = Store.pluginPermissionBox;
  final List<PluginPermission> _permissions = [];

  @override
  void initState() {
    super.initState();
    List list =
        jsonDecode(_permissionBox.get(widget.plugin.name, defaultValue: '[]')!);
    _permissions.addAll(list.map((e) => PluginPermission.fromJson(e)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('插件设置'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_permissions.isEmpty) {
      return Center(
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '该插件没有需要的权限',
            style: TextStyle(color: Theme.of(context).disabledColor),
          ),
          TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('返回'))
        ],
      ));
    } else {
      return ListView(
        children: [
          ..._permissions.map((permission) => CheckboxListTile(
                value: permission.state == PermissionStatus.granted,
                onChanged: (value) {
                  _changePermission(permission, value);
                },
                title: Text(permission.name),
                subtitle: Text(permission.description),
              ))
        ],
      );
    }
  }

  void _changePermission(PluginPermission permission, bool? granted) {
    String state;
    if (granted == null) {
      state = PermissionStatus.prompt;
    } else if (granted) {
      state = PermissionStatus.granted;
    } else {
      state = PermissionStatus.denied;
    }
    setState(() {
      permission.state = state;
    });
    _permissionBox.put(widget.plugin.name, jsonEncode(_permissions));
  }
}
