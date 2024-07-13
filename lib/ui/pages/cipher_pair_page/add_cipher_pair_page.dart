import 'package:flutter/material.dart';

import '../../../api/cipher_pair_api.dart';
import '../../../bean/cipher_pair.dart';
import '../../widgets/toast.dart';

class AddCipherPairPage extends StatefulWidget {
  const AddCipherPairPage({super.key});

  @override
  State<AddCipherPairPage> createState() => _AddCipherPairPageState();
}

class _AddCipherPairPageState extends State<AddCipherPairPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加密钥对'),
        actions: [
          TextButton(
              onPressed: () {
                CipherPairAPI()
                    .add(CipherPair(
                        id: 0,
                        name: _nameController.text,
                        password: _passwordController.text,
                        key: _keyController.text))
                    .then((value) {
                  if (value.success) {
                    Navigator.of(context).pop();
                  } else {
                    Toast.show(value.message);
                  }
                });
              },
              child: const Text('保存'))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '密钥用户名(必需*)',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '密钥密码(必需*)',
                ),
                obscureText: true,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _keyController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '密钥Key值(可选)',
                ),
                // obscureText: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
