import 'package:flutter/material.dart';
import 'package:icampus/ui/widgets/toast.dart';
import 'package:icampus/utils/extensions/context_extension.dart';

import '../api/edu_api.dart';
import '../api/grade_api.dart';
import '../bean/grade.dart';


class GradePage extends StatefulWidget {
  const GradePage({super.key});

  @override
  State<GradePage> createState() => _GradePageState();
}

class _GradePageState extends State<GradePage> {
  late final List<String> _semesters = generateSemesters();
  final List<Grade> _grades = [];
  bool _loading = true;
  int _selectSemester = 0;

  @override
  void initState() {
    super.initState();
    initData();
  }

  Future<void> initData() async {
    await _initTerm();
    await _fetchTermGrade();
  }

  Future<void> _initTerm() async {
    String? term = await EduAPI().curTerm();
    if (term != null) {
      _selectSemester = _semesters.indexOf(term);
      if (_selectSemester < 0) {
        _selectSemester = 0;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('成绩查询'),
          actions: const [],
        ),
        body: buildBody());
  }

  Widget buildBody() {
    Widget child;
    if (_loading) {
      child = const Center(child: CircularProgressIndicator());
    } else if (_grades.isEmpty) {
      child = Center(
          child: Text(
        '暂无数据',
        style: TextStyle(color: context.theme.disabledColor),
      ));
    } else {
      child = ListView.builder(
        itemBuilder: (context, index) {
          return GradeCard(grade: _grades[index]);
        },
        itemCount: _grades.length,
      );
    }
    return Column(
      children: [
        Expanded(child: child),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('第 ${_semesters[_selectSemester]} 学期'),
                TextButton(
                    onPressed: () {
                      chooseSemester(context);
                    },
                    child: const Text('更换学期')),
              ],
            ),
          ),
        )
      ],
    );
  }

  List<String> generateSemesters() {
    List<String> semesters = [];
    DateTime now = DateTime.now();
    for (int i = 5; i >= 0; i--) {
      int year = now.year - i;
      semesters.add('$year-${year + 1}-1');
      semesters.add('$year-${year + 1}-2');
      semesters.add('$year-${year + 1}-3');
    }
    //todo 根据当前月份选取学期
    _selectSemester = 0;
    return semesters.reversed.toList();
  }

  Future<void> chooseSemester(BuildContext context) async {
    int semesterBack = _selectSemester;
    await showModalBottomSheet(
        context: context,
        builder: (context) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                    child: Text(
                  '更换学期',
                  style: context.theme.textTheme.headlineSmall,
                )),
              ),
              Expanded(
                  child: ListView.builder(
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_semesters[index]),
                    onTap: () {
                      _selectSemester = index;
                      Navigator.pop(context);
                    },
                  );
                },
                itemCount: _semesters.length,
              )),
            ],
          );
        });
    if (semesterBack != _selectSemester) {
      _fetchTermGrade();
    }
  }

  Future<void> _fetchTermGrade() async {
    setState(() {
      _loading = true;
    });
    var res = await GradeAPI().grades(_semesters[_selectSemester]);
    _grades.clear();
    if (res.success) {
      _grades.addAll(res.data!);
    } else {
      Toast.show(res.message);
    }
    if (mounted) {
      _loading = false;
      setState(() {});
    }
  }

}

class GradeCard extends StatelessWidget {
  final Grade grade;

  const GradeCard({super.key, required this.grade});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Card(
          elevation: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                //课程名 分数
                Row(
                  children: <Widget>[
                    Expanded(
                      flex: 1,
                      child: Text(
                        grade.courseName,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    Text(
                      grade.totalScore,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // 绩点 等级
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      flex: 1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          const Expanded(
                            flex: 1,
                            child: Text(
                              '绩点',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                          Text(
                            grade.gpa,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 16,
                    ),
                    Expanded(
                      flex: 1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          const Expanded(
                            flex: 1,
                            child: Text(
                              '等级',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                          Text(
                            grade.level,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // 学分 科目类型
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      flex: 1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          const Expanded(
                            flex: 1,
                            child: Text(
                              '学分',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                          Text(
                            grade.credit,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 16,
                    ),
                    Expanded(
                      flex: 1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          const Expanded(
                            flex: 1,
                            child: Text(
                              '类型',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                          Text(
                            grade.type,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // 平时成绩 期末成绩
                if (grade.dailyScore.isNotEmpty || grade.examScore.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        flex: 1,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            const Expanded(
                              flex: 1,
                              child: Text(
                                '平时成绩',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            Text(
                              grade.dailyScore,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 16,
                      ),
                      Expanded(
                        flex: 1,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            const Expanded(
                              flex: 1,
                              child: Text(
                                '期末成绩',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            Text(
                              grade.examScore,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          )),
    );
  }
}
