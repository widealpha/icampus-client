import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';

import '../../../api/cipher_pair_api.dart';
import '../../../bean/cipher_pair.dart';
import '../../../model/user_model.dart';
import '../../../utils/extensions/context_extension.dart';
import '../../../utils/store_utils.dart';
import '../../sub_home_page.dart';
import '../cipher_pair_page/add_cipher_pair_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final RefreshController _controller = RefreshController();
  final List<CipherPair> _cipherPairs = [];
  int _selectIndex = -1;

  @override
  void initState() {
    super.initState();

    _initData();
  }

  Future<void> _initData() async {
    var res = await CipherPairAPI().list();
    if (res.success) {
      _cipherPairs.clear();
      _cipherPairs.addAll(res.data!);
    }
    setState(() {});
    var defaultCipherPair = await CipherPairAPI().defaultCipherPair();
    if (mounted &&
        CipherPairAPI().hasDefaultCipherPair &&
        defaultCipherPair.data != null) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('请选择默认密钥'),
        actions: [
          TextButton(
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (ctx) {
                    return AlertDialog(
                      title: const Text('警告'),
                      content: const Text('确认退出登录吗'),
                      actions: [
                        TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('取消')),
                        TextButton(
                            onPressed: () {
                              Provider.of<UserModel>(context, listen: false)
                                  .logout();
                              context.go('/');
                            },
                            child: const Text('确认')),
                      ],
                    );
                  });
            },
            child: const Text('退出登录'),
          ),
          TextButton(
              onPressed: _selectIndex >= 0
                  ? () {
                      CipherPairAPI().setDefaultCipherPair(
                          cipherPairId: _cipherPairs[_selectIndex].id);
                      context.go('/home');
                    }
                  : null,
              child: const Text('确认')),
        ],
      ),
      body: SmartRefresher(
        controller: _controller,
        onRefresh: () async {
          await _initData();
          _controller.refreshCompleted();
        },
        child: ListView.builder(
          itemBuilder: (ctx, i) {
            if (i == _cipherPairs.length) {
              return TextButton(
                  onPressed: () async {
                    await context.to((_) => const AddCipherPairPage());
                    _controller.requestRefresh();
                  },
                  child: const Text('添加其他密钥'));
            }
            var pair = _cipherPairs[i];
            return ListTile(
              selected: _selectIndex == i,
              title: Text(pair.name),
              subtitle: Text('包含密码 ${pair.key.isEmpty ? '不' : ''}包含Key'),
              trailing: _selectIndex == i
                  ? const Icon(Icons.radio_button_checked_rounded)
                  : const Icon(Icons.radio_button_off_rounded),
              onTap: () {
                setState(() {
                  _selectIndex = i;
                });
              },
            );
          },
          itemCount: _cipherPairs.length + 1,
        ),
      ),
    );
  }
}
