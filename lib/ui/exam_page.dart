import 'package:flutter/material.dart';
import 'widgets/toast.dart';
import '../utils/extensions/context_extension.dart';


import '../api/exam_api.dart';
import '../bean/exam.dart';

class ExamPage extends StatefulWidget {
  const ExamPage({super.key});

  @override
  State<ExamPage> createState() => _ExamPageState();
}

class _ExamPageState extends State<ExamPage> {
  final List<Exam> _exams = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    initData();
  }

  Future<void> initData({bool useCache = true}) async {
    var res = await ExamAPI().exams(useCache: useCache);
    if (res.success) {
      _exams.clear();
      List<Exam> data = res.data!;
      _exams.addAll(data);
      // _exams.sort((a, b) {
      //   DateTime now = DateTime.now();
      //   DateTime aStartTime = DateTime.parse(a.time.split('~')[0].trim());
      //   DateTime bStartTime = DateTime.parse(b.time.split('~')[0].trim());
      //   if (aStartTime.isAfter(now) && bStartTime.isAfter(now)) {
      //     return aStartTime.compareTo(bStartTime);
      //   } else if (aStartTime.isAfter(now)) {
      //     return -1;
      //   } else if (bStartTime.isAfter(now)) {
      //     return 1;
      //   } else {
      //     return aStartTime.compareTo(bStartTime);
      //   }
      // });
    } else {
      Toast.show(res.message);
    }
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
    });
    initData(useCache: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('考试安排'),
        actions: [
          IconButton(
              onPressed: _refresh, icon: const Icon(Icons.refresh_rounded))
        ],
      ),
      body: buildBody(),
    );
  }

  Widget buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else if (_exams.isEmpty) {
      return Center(
        child: Text(
          '暂无考试安排',
          style: TextStyle(color: context.theme.disabledColor),
        ),
      );
    } else {
      return ListView.builder(
        itemBuilder: (c, i) {
          Exam exam = _exams[i];
          return ExamCard(exam: exam);
        },
        itemCount: _exams.length,
      );
    }
  }
}

class ExamCard extends StatelessWidget {
  final Exam exam;

  const ExamCard({super.key, required this.exam});

  @override
  Widget build(BuildContext context) {
    Color? nameColor;
    // DateTime startTime = DateTime.parse(exam.time.split('~')[0].trim());
    // if (startTime.isBefore(DateTime.now())) {
    //   nameColor = context.theme.disabledColor;
    // } else {
    //   nameColor = context.theme.colorScheme.primary;
    // }

    return Card(
      child: Container(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    exam.courseName,
                    style: TextStyle(
                        fontSize: 16.0,
                        color: nameColor,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(exam.method, style: const TextStyle(fontSize: 16))
                ],
              ),
              const Divider(),
              _buildRow(
                  context, '日期', exam.time.split(' ')[0], Icons.date_range),
              const Divider(),
              _buildRow(
                  context, '时间', exam.time.split(' ')[1], Icons.access_time),
              const Divider(),
              _buildRow(context, '地点', exam.location, Icons.location_on),
            ],
          )),
    );
  }

  Widget _buildRow(
      BuildContext context, String title, String info, IconData icon) {
    return Container(
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: context.theme.colorScheme.primary),
            const SizedBox(width: 4),
            Text(title, style: const TextStyle(fontSize: 16.0)),
            const Spacer(),
            Text(info, textAlign: TextAlign.right)
          ],
        ));
  }
}
