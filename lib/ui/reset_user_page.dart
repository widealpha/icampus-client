import 'package:flutter/material.dart';
import '../api/cipher_pair_api.dart';
import '../api/sdu_user.dart';
import 'sub_home_page.dart';
import '../utils/extensions/context_extension.dart';

import 'widgets/toast.dart';

class ResetUserPage extends StatefulWidget {
  const ResetUserPage({super.key});

  @override
  State<ResetUserPage> createState() => _ResetUserPageState();
}

class _ResetUserPageState extends State<ResetUserPage> {
  static const String _placeHoldPassword = '•••••••••••';
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    CipherPairAPI().defaultCipherPair().then((result) {
      if (result.success) {
        _usernameController.text = result.data!.name;
        _passwordController.text = _placeHoldPassword;
        _keyController.text = _placeHoldPassword;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '设置身份认证账号',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), labelText: '身份认证账号'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _passwordController,
                keyboardType: TextInputType.visiblePassword,
                obscureText: true,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), labelText: '身份认证密码'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _keyController,
                keyboardType: TextInputType.visiblePassword,
                obscureText: true,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), labelText: '身份认证Key'),
              ),
            ),
            ElevatedButton(
                onPressed: () async {
                  String username = _usernameController.text.trim();
                  String password = _passwordController.text;
                  if (username.isEmpty || password.isEmpty) {
                    Toast.show('用户名密码不能置空');
                    return;
                  }
                  if (password.contains('•')) {
                    Toast.show('请完整的重输密码');
                    _passwordController.clear();
                    return;
                  }
                  if (password.contains('&') || username.contains('&')) {
                    Toast.show('用户名密码包含&可能会导致部分功能不可用');
                    return;
                  }
                  await SduUserAPI()
                      .saveUser(username, _passwordController.text);
                  Toast.show('保存成功');
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    // SduAuthManager().clearCookies();
                    context.to((_) => const SubHomePage());
                  }
                },
                child: const Text('保存'))
          ],
        ),
      ),
    );
  }
}
