import 'package:flutter/material.dart';
import 'package:icampus/ui/exam_page.dart';
import 'package:icampus/ui/js_page.dart';
import 'package:icampus/ui/schoolbus_page.dart';
import 'package:icampus/ui/grade_page.dart';
import 'package:icampus/ui/study_room_page.dart';
import 'package:icampus/utils/extensions/context_extension.dart';
import 'package:icampus/utils/sp_utils.dart';

import '../api/library_api.dart';
import 'pages/library/library_page.dart';
import 'pages/plugin/plugin_repository.dart';

class FunctionPage extends StatefulWidget {
  const FunctionPage({super.key});

  @override
  State<FunctionPage> createState() => _FunctionPageState();
}

class _FunctionPageState extends State<FunctionPage> {
  int level = -1;

  @override
  void initState() {
    super.initState();
    initData();
  }

  Future<void> initData() async {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('更多功能'),
      ),
      body: Wrap(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FilledButton.icon(
                onPressed: () {
                  context.to((_) => const SchoolBusPage());
                },
                icon: const Icon(Icons.directions_bus_filled_rounded),
                label: const Text('校车')),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FilledButton.icon(
                onPressed: () {
                  context.to((_) => const StudyRoomPage());
                },
                icon: const Icon(Icons.home_work_rounded),
                label: const Text('自习室')),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FilledButton.icon(
                onPressed: () {
                  context.to((_) => const ExamPage());
                },
                icon: const Icon(Icons.list_alt_rounded),
                label: const Text('考试安排')),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FilledButton.icon(
                onPressed: () {
                  context.to((_) => const GradePage());
                },
                icon: const Icon(Icons.grade_rounded),
                label: const Text('成绩查询')),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FilledButton.icon(
                onPressed: () {
                  context.to((_) => const LibraryPage());
                },
                icon: const Icon(Icons.grade_rounded),
                label: const Text('图书馆')),
          ),
          if (SPUtils.boolWithDefault(SPEnum.developMode,
              defaultValue: true)) ...[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: FilledButton.icon(
                  onPressed: () {
                    context.to((_) => const JSPage());
                  },
                  icon: const Icon(Icons.javascript_rounded),
                  label: const Text('JS')),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: FilledButton.icon(
                  onPressed: () {
                    context.to((_) => const PluginRepositoryPage());
                  },
                  icon: const Icon(Icons.dynamic_form_rounded),
                  label: const Text('插件管理')),
            ),
          ]
        ],
      ),
    );
  }

// Future<dynamic> goPage(int levelLimitation, Widget page) async {
//   if (level >= levelLimitation) {
//     return context.to((_) => page);
//   } else {
//     return Toast.show('仅支持LV$levelLimitation以上用户使用');
//   }
// }
}
