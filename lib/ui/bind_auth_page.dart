import 'dart:convert';

import 'package:flutter/material.dart';

import '../utils/store_utils.dart';

class BindAuthPage extends StatefulWidget {
  const BindAuthPage({super.key});

  @override
  State<BindAuthPage> createState() => _BindAuthPageState();
}

class _BindAuthPageState extends State<BindAuthPage> {
  final String _bindKey = 'pluginBindAuth';
  final Map<String, String> _bindMap = {};
  final List<String> _bindingKeys = ['课程表', '考试安排', '成绩查询', '图书馆'];

  @override
  void initState() {
    super.initState();
    String s = Store.get(_bindKey, defaultValue: '{}')!;
    _bindMap.addAll(jsonDecode(s).cast<String, String>());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('绑定认证脚本'),
      ),
      body: ListView(
        children: _buildChildren(),
      ),
    );
  }

  List<Widget> _buildChildren() {
    List<Widget> children = [];
    children.addAll(_bindingKeys.map((key) => ListTile(
          title: Text(key),
          trailing: Text(_bindMap[key] ?? '无'),
          onTap: () async {
            String? binding = await _selectAuthScript();
            updateBind(key, binding);
          },
        )));
    return children;
  }

  Future<String?> _selectAuthScript() {
    final List<String> auths = ['中国科学院大学', '山东大学', ''];
    return showDialog(
        context: context,
        builder: (ctx) {
          return SimpleDialog(
            title: const Text('设置认证脚本'),
            children: [
              ...auths.map((e) => SimpleDialogOption(
                    child: Text(e.isEmpty ? '无' : e),
                    onPressed: () {
                      Navigator.pop(context, e);
                    },
                  ))
            ],
          );
        });
  }

  void updateBind(String key, String? value) {
    if (value == null) {
      return;
    } else if (value.isEmpty) {
      _bindMap.remove(key);
    } else {
      _bindMap[key] = value;
    }
    Store.set(_bindKey, jsonEncode(_bindMap));
    setState(() {});
  }
}
