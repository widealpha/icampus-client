import 'dart:io';

import 'package:flutter/material.dart';
import 'package:icampus/utils/extensions/context_extension.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../../ui/widgets/choose_panel.dart';
import '../../utils/clipboard_utils.dart';
import '../api/cipher_pair_api.dart';
import '../api/course_api.dart';
import '../api/edu_api.dart';
import '../bean/course.dart';
import '../utils/path_utils.dart';
import 'widgets/toast.dart';

enum MenuItem {
  changeBackground,
}

class TimeTablePage extends StatefulWidget {
  const TimeTablePage({super.key});

  @override
  State<TimeTablePage> createState() => _TimeTablePageState();
}

class _TimeTablePageState extends State<TimeTablePage> {
  static const maxWeek = 20;
  static const weekdayInWeek = 7;
  static const maxOrder = 5;
  ImageProvider? _bgImageProvider;
  late PageController _pageController;
  late DateTime _termStartTime;

  //储存所有课程
  final List<Course> _courses = [];

  //用于ui的转换课程
  List<List<List<List<Course>>>> _timetableCourses = [];
  bool _loading = true;
  final _selectedWeek = ValueNotifier(0);
  int _curWeek = 0;
  int _curDay = 0;

  final bool _userExist = CipherPairAPI().hasDefaultCipherPair;

  @override
  void initState() {
    super.initState();
    _initBgImage();
    _initData();
  }

  Future<bool> _initData({bool useCache = true}) async {
    if (!_userExist) {
      setState(() {
        _loading = false;
      });
      return false;
    }
    _termStartTime = await EduAPI().firstWeekday(useCache: useCache);
    var res = await CourseAPI().courses(useCache: useCache);
    if (res.success) {
      _courses.clear();
      _courses.addAll(res.data!);
      _courses.addAll(await CourseAPI().customCourses());
      _generateTimetableCourse();
      DateTime time = DateTime.now();
      _curWeek = time.difference(_termStartTime).inDays ~/ 7;
      _curDay = time.weekday;
      _selectedWeek.value = _curWeek;
      _pageController = PageController(initialPage: _curWeek);
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
      return true;
    } else {
      Toast.show(res.message);
      return false;
    }
  }

  Future<void> _initBgImage() async {
    String path = p.join((await PathUtils.dataPath()), '.cave.background.jpg');
    File file = File(path);
    if (await file.exists()) {
      _bgImageProvider = MemoryImage(await file.readAsBytes());
    } else {
      _bgImageProvider = null;
    }
    if (mounted) {
      setState(() {});
    }
  }

  ///根据获取的数组生成课表对应的四维数组
  void _generateTimetableCourse() {
    _timetableCourses = List.generate(
        maxWeek,
        (_) => List.generate(
            weekdayInWeek, (_) => List.generate(maxOrder, (_) => [])));
    for (var course in _courses) {
      for (var week in course.courseWeeks) {
        //确保数据不会溢出
        if (week <= maxWeek &&
            course.courseWeekday <= weekdayInWeek &&
            course.courseOrder <= maxOrder) {
          //转化从1开始的数据到从0开始的数组里
          _timetableCourses[week - 1][course.courseWeekday - 1]
                  [course.courseOrder - 1]
              .add(course);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userExist) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: GestureDetector(
              onTap: () {
                _chooseWeek(context);
              },
              child: ListenableBuilder(
                listenable: _selectedWeek,
                builder: (BuildContext context, Widget? child) {
                  return Text(
                    '第${_selectedWeek.value + 1}周',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  );
                },
              )),
          actions: [
            TextButton.icon(
                onPressed: () async {
                  Toast.show('正在刷新...');
                  if (await _initData(useCache: false)) {
                    Toast.show('刷新完成');
                  }
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('刷新')),
            PopupMenuButton(
              itemBuilder: (BuildContext context) => <PopupMenuEntry<MenuItem>>[
                PopupMenuItem<MenuItem>(
                  value: MenuItem.changeBackground,
                  child: Text(_bgImageProvider == null ? '更换背景' : '清除背景'),
                ),
              ],
              onSelected: (item) {
                switch (item) {
                  case MenuItem.changeBackground:
                    if (_bgImageProvider == null) {
                      _changeBgImage();
                    } else {
                      _removeBgImage();
                    }
                }
              },
            )
          ],
        ),
        body: _buildBody(),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('未登录'),
        ),
        body: Center(
          child: Text(
            '未保存统一身份认证账户',
            style: TextStyle(color: context.theme.disabledColor),
          ),
        ),
      );
    }
  }

  Widget _buildBody() {
    Widget child;
    if (_loading) {
      child = const Center(
        child: CircularProgressIndicator(),
      );
    } else {
      child = PageView.builder(
        controller: _pageController,
        itemBuilder: (c, i) {
          return _buildTimetable(i);
        },
        itemCount: maxWeek,
        onPageChanged: (i) {
          _selectedWeek.value = i;
        },
      );
    }
    return Container(
      decoration: _bgImageProvider != null
          ? BoxDecoration(
              image:
                  DecorationImage(image: _bgImageProvider!, fit: BoxFit.cover))
          : null,
      child: child,
    );
  }

  Widget _buildTimetable(int week) {
    return Column(
      children: [
        ///表头行
        IntrinsicHeight(
            child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _buildTableHeader(week),
        )),
        Expanded(
          child: Row(
            children: [
              _buildSidebar(),
              Expanded(child: _buildCourseTable(week))
            ],
          ),
        )
      ],
    );
  }

  ///课表侧边栏
  Widget _buildSidebar() {
    final List<String> courseStartTime = [
      '08:00',
      '10:10',
      '14:00',
      '16:10',
      '19:00'
    ];
    final List<String> courseEndTime = [
      '09:50',
      '12:00',
      '15:50',
      '18:00',
      '20:50'
    ];
    return GestureDetector(
      child: SizedBox(
        width: 28,
        child: Column(
          children: List.generate(maxOrder, (i) {
            return Expanded(
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: _applySidebarOpacity(
                        context.theme.colorScheme.background),
                    border: const Border(
                        top: BorderSide(color: Colors.black12, width: 0.25),
                        right: BorderSide(color: Colors.black12, width: 0.25))),
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(
                      text: '${courseStartTime[i]}\n',
                      style: TextStyle(
                          fontSize: 8, color: context.theme.disabledColor),
                    ),
                    TextSpan(
                      text: '${i + 1}',
                      style: TextStyle(
                          fontSize: 14,
                          color: context.theme.colorScheme.onBackground,
                          fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: '\n${courseEndTime[i]}',
                      style: TextStyle(
                          fontSize: 8, color: context.theme.disabledColor),
                    ),
                  ]),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  ///课表顶部栏
  List<Widget> _buildTableHeader(int week) {
    final weekDays = ['一', '二', '三', '四', '五', '六', '日'];
    var tableHeaders = <Widget>[
      Container(
        width: 28,
        padding: const EdgeInsets.only(top: 2, bottom: 2),
        decoration: BoxDecoration(
          color: _applySidebarOpacity(context.theme.colorScheme.background),
        ),
        child: GestureDetector(
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(
                Icons.ac_unit_rounded,
                size: 15,
              ),
            ],
          ),
        ),
      ),
    ];
    for (var i = 0; i < weekdayInWeek; i++) {
      tableHeaders.add(Expanded(
        flex: 1,
        child: GestureDetector(
          child: Container(
            decoration: BoxDecoration(
              color: week == _curWeek && i == _curDay - 1
                  ? _applySidebarOpacity(
                      context.theme.colorScheme.secondaryContainer)
                  : _applySidebarOpacity(context.theme.colorScheme.background),
            ),
            padding: const EdgeInsets.only(top: 2, bottom: 2),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  '周${weekDays[i]}',
                  style: TextStyle(
                      fontSize: 10,
                      color: week == _curWeek && i == _curDay - 1
                          ? context.theme.colorScheme.onSecondaryContainer
                          : context.theme.colorScheme.onBackground,
                      fontWeight: week == _curWeek && i == _curDay - 1
                          ? FontWeight.bold
                          : FontWeight.normal),
                ),
                Text(
                  weekdayDateString(week, i),
                  style: TextStyle(
                      fontSize: 8,
                      color: week == _curWeek && i == _curDay - 1
                          ? context.theme.colorScheme.onSecondaryContainer
                          : context.theme.colorScheme.onBackground,
                      fontWeight: week == _curWeek && i == _curDay - 1
                          ? FontWeight.bold
                          : FontWeight.normal),
                )
              ],
            ),
          ),
          onDoubleTap: () {
            if (_curWeek != _selectedWeek.value) {
              setState(() {
                //出于性能原因不适用动画跳转
                _pageController.jumpToPage(_curWeek);
                _selectedWeek.value = _curWeek;
              });
            }
          },
        ),
      ));
    }
    return tableHeaders;
  }

  String weekdayDateString(int week, int dayInWeek) {
    return _termStartTime
        .add(Duration(days: 7 * week + dayInWeek))
        .toString()
        .substring(5, 10)
        .replaceAll('-', '/');
  }

  Widget _buildCourseTable(int week) {
    return Row(children: [
      ...List.generate(weekdayInWeek, (index) {
        return Expanded(child: _buildTimetableDay(week, index));
      }),
    ]);
  }

  Widget _buildTimetableDay(int week, int weekday) {
    return Column(
      children: List.generate(maxOrder, (index) {
        return Expanded(child: _buildCourseCell(week, weekday, index));
      }),
    );
  }

  Widget _buildCourseCell(int week, int weekday, int order) {
    List<Course> courses = _timetableCourses[week][weekday][order];
    Widget child;
    if (courses.isEmpty) {
      child = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () async {
          List<Course> newCourses = await _showAddCourseSheet(weekday, [order]);
          for (var course in newCourses) {
            CourseAPI().addCustomCourse(course);
            _courses.add(course);
          }
          _generateTimetableCourse();
          setState(() {});
        },
        child: const SizedBox.expand(),
      );
    } else {
      child = Column(
        children: [
          ...courses.map((course) => Expanded(
                  child: CourseCard(
                course: course,
                onDelete: (course) {
                  CourseAPI().removeCustomCourse(course.id);
                  _courses.removeWhere((c) => c.id == course.id);
                  _generateTimetableCourse();
                  setState(() {});
                },
              )))
        ],
      );
    }
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.black12, width: 0.2),
          top: BorderSide(color: Colors.black12, width: 0.2),
        ),
      ),
      child: child,
    );
  }

  void _chooseWeek(context) {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Column(
            children: [
              if (_selectedWeek.value != _curWeek)
                ListTile(
                  title: Text('返回当前周 / 第 ${_curWeek + 1} 周',
                      textAlign: TextAlign.center),
                  onTap: () {
                    _pageController.jumpToPage(_curWeek);
                    Navigator.pop(context);
                  },
                ),
              Expanded(
                  child: ListView.builder(
                      itemCount: maxWeek,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(
                            '第 ${index + 1} 周',
                            textAlign: TextAlign.center,
                            style: (index == _selectedWeek.value)
                                ? TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold)
                                : null,
                          ),
                          onTap: () {
                            _pageController.jumpToPage(index);
                            Navigator.pop(context);
                          },
                        );
                      }))
            ],
          );
        });
  }

  Color _applySidebarOpacity(Color background) {
    if (_bgImageProvider == null) {
      return background;
    } else {
      return background.withOpacity(0.3);
    }
  }

  Future<void> _changeBgImage() async {
    String path = p.join((await PathUtils.dataPath()), '.cave.background.jpg');
    var result = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (result != null) {
      await result.saveTo(path);
    }
    _initBgImage();
  }

  Future<void> _removeBgImage() async {
    String path = p.join((await PathUtils.dataPath()), '.cave.background.jpg');
    File file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    _initBgImage();
  }

  ///周几上课以及哪一节上课
  ///[weekday] 1~[maxWeek], order 1~[maxOrder]
  ///[choiceOrders]长度不为0
  Future<List<Course>> _showAddCourseSheet(
      int weekday, List<int> choiceOrders) async {
    assert(choiceOrders.isNotEmpty);
    var teacherController = TextEditingController();
    var courseNameController = TextEditingController();
    var courseLocationController = TextEditingController();
    var chooseWeekController = ChoosePanelController<int>();
    var chooseWeekdayController = ChoosePanelController<int>();
    var chooseOrderController = ChoosePanelController<int>();

    //确定有哪些周该节次是空的
    Map<int, List<int>> freeWeeks = {};
    for (var order in choiceOrders) {
      freeWeeks[order] = [];
      List.generate(maxWeek, (week) {
        if (_timetableCourses[week][weekday][order].isEmpty) {
          freeWeeks[order]!.add(week + 1);
        }
      });
    }
    int selectedOrder = choiceOrders[0];
    final List<int> oddWeeks =
        List.generate(maxWeek ~/ 2, (index) => 2 * index + 1);
    final List<int> evenWeeks =
        List.generate(maxWeek ~/ 2, (index) => 2 * index + 2);

    List<Course>? result = await showModalBottomSheet(
        useSafeArea: true,
        context: context,
        isScrollControlled: true,
        builder: (BuildContext context) {
          return FractionallySizedBox(
            heightFactor: 0.9,
            child: Scaffold(
              appBar: AppBar(
                title: const Text(
                  '添加课程',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                actions: [
                  TextButton.icon(
                      onPressed: () {
                        if (courseNameController.text.isEmpty) {
                          Toast.show('课程名不能为空');
                          return;
                        }
                        List<int> courseWeeks = chooseWeekController.selected;
                        if (courseWeeks.isEmpty) {
                          Toast.show('请至少选择一周上课');
                          return;
                        }

                        List<int> courseOrders = chooseOrderController.selected;
                        if (courseOrders.isEmpty) {
                          Toast.show('请至少选择一节上课');
                          return;
                        }
                        List<int> weekdays = chooseWeekdayController.selected;
                        if (weekdays.isEmpty) {
                          Toast.show('请至少选择一个周几上课');
                          return;
                        }
                        List<Course> result = [];
                        int id = DateTime.now().millisecondsSinceEpoch;
                        for (var order in courseOrders) {
                          for (var weekday in weekdays) {
                            Course c = Course.empty()
                              ..id = id
                              ..courseWeeks = courseWeeks
                              ..courseWeekday = weekday
                              ..courseOrder = order
                              ..courseName = courseNameController.text
                              ..courseTeacher = teacherController.text
                              ..courseLocation = courseLocationController.text
                              ..userCourse = true;
                            result.add(c);
                          }
                        }
                        Navigator.of(context).pop(result);
                      },
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('确认'))
                ],
              ),
              body: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  children: [
                    _buildInputWidget('课程名', courseNameController, false),
                    _buildInputWidget('上课地点', courseLocationController, true),
                    _buildInputWidget('教师', teacherController, true),
                    const Divider(),
                    Row(
                      children: [
                        const Text('选择上课周'),
                        Expanded(
                            child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                reverse: true,
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Row(children: [
                                  TextButton(
                                    onPressed: () {
                                      chooseWeekController.selected = oddWeeks;
                                    },
                                    child: const Text('奇数周'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      chooseWeekController.selected = evenWeeks;
                                    },
                                    child: const Text('偶数周'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      chooseWeekController.selected =
                                          freeWeeks[selectedOrder]!;
                                    },
                                    child: const Text('无课周'),
                                  )
                                ]))),
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    ChoosePanel<int>(
                      controller: chooseWeekController,
                      defaultSelected: [_selectedWeek.value + 1],
                      choices: List.generate(maxWeek, (i) => i + 1),
                    ),
                    const Divider(),
                    const Row(
                      children: [
                        Text('选择星期 (周几上课)'),
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    ChoosePanel<int>(
                      controller: chooseWeekdayController,
                      defaultSelected: [weekday + 1],
                      choices: List.generate(weekdayInWeek, (i) => i + 1),
                    ),
                    const Divider(),
                    const Row(
                      children: [
                        Text('选择节次 (第几节上课)'),
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    ChoosePanel<int>(
                      controller: chooseOrderController,
                      defaultSelected:
                          choiceOrders.map((order) => order + 1).toList(),
                      choices: List.generate(maxOrder, (i) => i + 1),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
    return result ?? [];
  }

  ///绘制添加课程的输入框组件
  Widget _buildInputWidget(
      String hintText, TextEditingController controller, bool canNull) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
            hintText: hintText,
            isDense: true,
            suffix: Text(canNull ? '选填' : '必填'),
            border: const OutlineInputBorder(),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
      ),
    );
  }
}

class CourseCard extends StatelessWidget {
  final List<Color> _courseColors = const [
    Colors.red,
    Colors.purple,
    Colors.blue,
    Colors.green,
    Colors.orange
  ];
  final Course course;
  final void Function(Course course)? onDelete;

  const CourseCard({super.key, required this.course, this.onDelete});

  @override
  Widget build(BuildContext context) {
    Color color =
        _courseColors[course.courseName.hashCode % _courseColors.length];
    return GestureDetector(
      onTap: () {
        _showCourseDetailDialog(context);
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
            color: Color.alphaBlend(color.withOpacity(0.1), Colors.white10),
            borderRadius: BorderRadius.circular(8)),
        child: Text.rich(
          TextSpan(children: [
            TextSpan(
              text: '${course.courseName}\n',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(
              text: '@${course.courseLocation}',
            )
          ]),
          style: TextStyle(color: color, fontSize: 10),
        ),
      ),
    );
  }

  Future<void> _showCourseDetailDialog(BuildContext context) {
    bool expandDialog = false;
    return showDialog(
      context: context,
      builder: (_) {
        Color? leadingColor = context.theme.disabledColor;
        Color? contentColor;
        return AlertDialog(
          titlePadding: const EdgeInsets.only(top: 8, right: 12),
          title: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Colors.transparent,
              title: const Text('课程信息'),
              actions: [
                if (course.userCourse)
                  IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                        showDeleteDialog(context);
                      },
                      icon: const Icon(Icons.delete_forever_rounded))
              ]),
          contentPadding: EdgeInsets.zero,
          content: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('课程: ', style: TextStyle(color: leadingColor)),
                      Expanded(
                        child: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            course.courseName,
                            style: TextStyle(color: contentColor),
                            softWrap: true,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(0.0),
                        height: 30.0,
                        width: 30.0,
                        child: IconButton(
                          onPressed: () async {
                            await ClipboardUtils.copy(course.courseName);
                            Toast.show('复制成功');
                          },
                          icon: const Icon(Icons.copy, size: 16),
                          iconSize: 16,
                        ),
                      )
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('教师：', style: TextStyle(color: leadingColor)),
                      Expanded(
                        child: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            course.courseTeacher,
                            style: TextStyle(color: contentColor),
                            softWrap: true,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(0.0),
                        height: 30.0,
                        width: 30.0,
                        child: IconButton(
                          onPressed: () async {
                            await ClipboardUtils.copy(course.courseTeacher);
                            Toast.show('复制成功');
                          },
                          icon: const Icon(Icons.copy, size: 16),
                          iconSize: 16,
                        ),
                      )
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('地点：', style: TextStyle(color: leadingColor)),
                      Expanded(
                        child: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            course.courseLocation,
                            style: TextStyle(color: contentColor),
                            softWrap: true,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(0.0),
                        height: 30.0,
                        width: 30.0,
                        child: IconButton(
                          onPressed: () async {
                            await ClipboardUtils.copy(course.courseLocation);
                            Toast.show('复制成功');
                          },
                          icon: const Icon(Icons.copy, size: 16),
                          iconSize: 16,
                        ),
                      )
                    ],
                  ),
                  StatefulBuilder(builder: (ctx, reloadState) {
                    return AnimatedCrossFade(
                        firstChild: Builder(builder: (ctx) {
                          if (course.userCourse) {
                            return Column(
                              children: [
                                const Divider(),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('开课周：',
                                        style: TextStyle(color: leadingColor)),
                                    Expanded(
                                      child: Container(
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(left: 8),
                                        child: Text(
                                          getSimplifiedCourseWeeks(
                                              course.courseWeeks),
                                          style: TextStyle(color: contentColor),
                                          softWrap: true,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                const Divider(),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('课程号：',
                                        style: TextStyle(color: leadingColor)),
                                    Expanded(
                                      child: Container(
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(left: 8),
                                        child: Text(
                                          course.courseId,
                                          style: TextStyle(color: contentColor),
                                          softWrap: true,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(0.0),
                                      height: 30.0,
                                      width: 30.0,
                                      child: IconButton(
                                        onPressed: () async {
                                          await ClipboardUtils.copy(
                                              course.courseId);
                                          Toast.show('复制成功');
                                        },
                                        icon: const Icon(Icons.copy, size: 16),
                                        iconSize: 16,
                                      ),
                                    )
                                  ],
                                ),
                                const Divider(),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('课序号：',
                                        style: TextStyle(color: leadingColor)),
                                    Expanded(
                                      child: Container(
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(left: 8),
                                        child: Text(
                                          '${course.courseIndex}',
                                          style: TextStyle(color: contentColor),
                                          softWrap: true,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (course.credit != 0) ...[
                                  const Divider(),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('学分：',
                                          style:
                                              TextStyle(color: leadingColor)),
                                      Expanded(
                                        child: Container(
                                          alignment: Alignment.centerRight,
                                          padding:
                                              const EdgeInsets.only(left: 8),
                                          child: Text(
                                            '${course.credit}',
                                            style:
                                                TextStyle(color: contentColor),
                                            softWrap: true,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (course.examType.isNotEmpty) ...[
                                  const Divider(),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('考察方式：',
                                          style:
                                              TextStyle(color: leadingColor)),
                                      Expanded(
                                        child: Container(
                                          alignment: Alignment.centerRight,
                                          padding:
                                              const EdgeInsets.only(left: 8),
                                          child: Text(
                                            course.examType,
                                            style:
                                                TextStyle(color: contentColor),
                                            softWrap: true,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const Divider(),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('开课周：',
                                        style: TextStyle(color: leadingColor)),
                                    Expanded(
                                      child: Container(
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(left: 8),
                                        child: Text(
                                          getSimplifiedCourseWeeks(
                                              course.courseWeeks),
                                          style: TextStyle(color: contentColor),
                                          softWrap: true,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],
                            );
                          }
                        }),
                        secondChild: Padding(
                          padding: const EdgeInsets.only(top: 8.0, bottom: 4),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                                onPressed: () {
                                  reloadState(() {
                                    expandDialog = true;
                                  });
                                },
                                child: const Text('展开 ↓')),
                          ),
                        ),
                        crossFadeState: expandDialog
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                        duration: const Duration(milliseconds: 200));
                  })
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  //返回简化后的开课周
  String getSimplifiedCourseWeeks(List<int> courseWeeks) {
    if (courseWeeks.isEmpty) {
      return '无开课周';
    }
    if (courseWeeks.length == 1) {
      return '第${courseWeeks.first}周开课';
    } else if (courseWeeks.length == 2) {
      return '第${courseWeeks.first},${courseWeeks.last}周开课';
    }
    //排序周数
    courseWeeks.sort();
    //最大最小周
    int weekMin = courseWeeks.first;
    int weekMax = courseWeeks.last;
    //判断是否为连续奇数/偶数序列
    if ((weekMax + weekMin) / 2 == courseWeeks.length - 1) {
      bool oddFlag = true;
      bool evenFlag = true;
      for (var week in courseWeeks) {
        //如果所有的课程数都是偶/奇数,且最大最小的差的一半为序列长度-1,序列为连续偶/奇数序列
        oddFlag = oddFlag & (week % 2 == 1);
        evenFlag = evenFlag & (week % 2 == 0);
      }
      if (oddFlag) {
        return '$weekMin~$weekMax周双周开课';
      } else if (evenFlag) {
        return '$weekMin~$weekMax周单周开课';
      }
    }
    //连续周的起始周
    int continueStart = courseWeeks.first;
    StringBuffer buff = StringBuffer('第');
    //遍历周数
    for (int i = 1; i < courseWeeks.length; ++i) {
      //当前周
      int week = courseWeeks[i];
      //前一周
      int previousWeek = courseWeeks[i - 1];
      //判断当前周是否仍然连续
      if (courseWeeks[i] != previousWeek + 1) {
        int interval = previousWeek - continueStart;
        if (interval == 0) {
          // 1连续直接输出当前周
          buff.write('$continueStart,');
        } else if (interval == 1) {
          //2连续输出两周以,分割
          buff.write('$continueStart,$previousWeek,');
        } else {
          //多连续输出开始周结束周,~连接
          buff.write('$continueStart~$previousWeek,');
        }
        continueStart = week;
      }
    }
    //最后一个元素单独输出
    int interval = courseWeeks.last - continueStart;
    if (interval == 0) {
      buff.write('$continueStart');
    } else if (interval == 1) {
      buff.write('$continueStart,${courseWeeks.last}');
    } else {
      buff.write('$continueStart~${courseWeeks.last}');
    }
    buff.write('周开课');
    return buff.toString();
  }

  Future<void> showDeleteDialog(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('删除课程'),
            content: const Text('确定要删除这门课程吗?'),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('取消')),
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onDelete?.call(course);
                  },
                  child: const Text('确定')),
            ],
          );
        });
  }
}
