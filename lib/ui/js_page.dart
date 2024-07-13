import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_js/extensions/fetch.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:icampus/ui/widgets/toast.dart';

class JSPage extends StatefulWidget {
  const JSPage({super.key});

  @override
  State<JSPage> createState() => _JSPageState();
}

class _JSPageState extends State<JSPage> {
  String? res;
  final TextEditingController _jsController = TextEditingController();
  final TextEditingController _functionController =
      TextEditingController(text: 'execute');
  final TextEditingController _paramController = TextEditingController();
  int time = 0;
  bool enableJsCore = false;
  XFile? file;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('js执行器')),
      body: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: TextField(
                    controller: _jsController,
                    minLines: 1,
                    maxLines: 10,
                    decoration: InputDecoration(
                        hintText:
                            file == null ? 'JS脚本' : '文件已加载: ${file!.name}'),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: TextButton.icon(
                    onPressed: () async {
                      const XTypeGroup typeGroup = XTypeGroup(
                        label: 'js',
                        extensions: <String>['js', 'javascript'],
                      );
                      file = await openFile(
                          acceptedTypeGroups: <XTypeGroup>[typeGroup]);
                      setState(() {});
                    },
                    icon: const Icon(Icons.file_copy_rounded),
                    label: const Text('从文件')),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextField(
              controller: _functionController,
              decoration: const InputDecoration(hintText: '函数名'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextField(
              controller: _paramController,
              decoration: const InputDecoration(hintText: '参数,用&分割'),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  value: enableJsCore,
                  onChanged: (v) {
                    setState(() {
                      enableJsCore = !enableJsCore;
                    });
                  },
                  title: const Text('是否使用JSCore引擎'),
                ),
              ),
              TextButton(
                  onPressed: () async {
                    setState(() {
                      res = '执行中...';
                    });
                    if (_jsController.text.isNotEmpty) {
                      runJs(_jsController.text);
                    } else if (file != null) {
                      runJs(await file!.readAsString());
                    } else {
                      Toast.show('代码不能为空');
                    }
                  },
                  child: const Text('执行'))
            ],
          ),
          Text('处理时间: $time ms'),
          const Divider(),
          Expanded(
              child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('结果: \n$res'),
            ),
          ))
        ],
      ),
    );
  }

  Future<void> runJs(String code) async {
    time = 0;
    int start = DateTime.now().millisecondsSinceEpoch;
    String base = await rootBundle.loadString('assets/js/base.js');
    var javascriptRuntime =
        getJavascriptRuntime(forceJavascriptCoreOnAndroid: enableJsCore);
    await javascriptRuntime.enableFetch();
    List<String> params = _paramController.text.split('&');
    StringBuffer paramBuff = StringBuffer();
    for (var param in params) {
      paramBuff.write(param);
    }
    String paramString = params.join('","');
    if (paramString.isNotEmpty) {
      paramString = '"$paramString"';
    }
    String functionCall = '${_functionController.text}($paramString);\n';
    try {
      JsEvalResult asyncResult =
          await javascriptRuntime.evaluateAsync('$base\n$code\n$functionCall');
      javascriptRuntime.executePendingJob();
      final promiseResolved =
          await javascriptRuntime.handlePromise(asyncResult);
      var result = promiseResolved.stringResult;
      int end = DateTime.now().millisecondsSinceEpoch;
      setState(() {
        time = end - start;
        res = result;
      });
    } catch (e) {
      setState(() {
        res = '执行出错: $e';
      });
    }
  }
}
