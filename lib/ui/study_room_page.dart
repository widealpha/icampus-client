import 'dart:math';

import 'package:flutter/material.dart';
import '../api/studyroom_api.dart';
import '../utils/cache_utils.dart';
import '../utils/extensions/context_extension.dart';

import '../bean/studyroom.dart';
import 'widgets/toast.dart';

class StudyRoomPage extends StatefulWidget {
  const StudyRoomPage({super.key});

  @override
  State<StudyRoomPage> createState() => _StudyRoomPageState();
}

class _StudyRoomPageState extends State<StudyRoomPage> {
  final List<String> _campusNames = [
    '中心校区',
    '洪家楼校区',
    '趵突泉校区',
    '软件园校区',
    '兴隆山校区',
    '千佛山校区',
    '青岛校区',
    '威海校区'
  ];

  final Map<String, List<String>> _buildingCache = {};
  final String _historyKey = 'studyRoomCampusHistory';
  String? _initialOpenCampus;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    for (var campus in _campusNames) {
      _buildingCache[campus] = [];
    }
    String? historyCampus = await CacheUtils.loadText(_historyKey);
    if (historyCampus != null) {
      int index = _campusNames.indexOf(historyCampus);
      if (index >= 0) {
        _initialOpenCampus = historyCampus;
        _campusNames[index] = _campusNames[0];
        _campusNames[0] = historyCampus;
        _fetchCampusBuildings(historyCampus).then((value) {
          if (mounted) {
            setState(() {});
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('自习室'),
      ),
      body: SingleChildScrollView(
          child: Column(
        children: [
          ..._campusNames.map((campus) => ExpansionTile(
                title: Text(campus),
                initiallyExpanded: campus == _initialOpenCampus,
                onExpansionChanged: (isOpen) async {
                  await _fetchCampusBuildings(campus);
                  if (mounted) {
                    setState(() {});
                  }
                  if (isOpen) {
                    CacheUtils.cacheText(_historyKey, campus);
                  }
                },
                children: [
                  if (_buildingCache[campus]!.isEmpty)
                    const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ..._buildingCache[campus]!.map((building) => ListTile(
                        leading: const Icon(Icons.room_rounded),
                        title: Text(building),
                        onTap: () {
                          context.to((_) => StudyRoomDataPage(
                              campus: campus, building: building));
                        },
                      )),
                ],
              ))
        ],
      )),
    );
  }

  Future<void> _fetchCampusBuildings(String campus) async {
    if (_buildingCache[campus]!.isEmpty) {
      List<String> building = await StudyRoomAPI().studyRoomBuildings(campus);
      _buildingCache[campus] = building;
    }
  }
}

class StudyRoomDataPage extends StatefulWidget {
  final String campus;
  final String building;

  const StudyRoomDataPage(
      {super.key, required this.campus, required this.building});

  @override
  State<StudyRoomDataPage> createState() => _StudyRoomDataPageState();
}

class _StudyRoomDataPageState extends State<StudyRoomDataPage> {
  final List<StudyRoom> _rooms = [];
  final List<StudyRoom> _modifiedRooms = [];
  DateTime _date = DateTime.now();
  bool _loading = true;
  bool _onlyShowFree = false;

  @override
  void initState() {
    super.initState();
    initData();
  }

  Future<void> initData() async {
    setState(() {
      _loading = true;
    });
    _rooms.clear();
    _rooms.addAll(await StudyRoomAPI()
        .getStudyRoomData(widget.campus, widget.building, _dateString));
    _doModifyRooms();
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.building),
        actions: [
          TextButton.icon(
              onPressed: () async {
                var date = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 2)));
                if (date != null) {
                  _date = date;
                  await initData();
                }
              },
              icon: const Icon(Icons.calendar_month_rounded),
              label: Text(_dateString))
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
    } else if (_rooms.isEmpty) {
      return Center(
          child: Text(
        '暂时没有数据',
        style: TextStyle(color: context.theme.disabledColor),
      ));
    } else {
      double firstColumnWidth = min(context.width / 8, 100);
      return Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                    child: SwitchListTile(
                  value: _onlyShowFree,
                  onChanged: (bool value) {
                    _onlyShowFree = value;
                    _doModifyRooms();
                    setState(() {});
                  },
                  title: const Text('只显示当前空闲'),
                )),
              ],
            ),
            Row(
              children: [
                Container(
                  alignment: Alignment.center,
                  width: firstColumnWidth,
                  child: const Text('节次/\n教室'),
                ),
                Expanded(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(child: Center(child: Text('上午'))),
                        VerticalDivider(),
                        Expanded(child: Center(child: Text('下午'))),
                        VerticalDivider(),
                        Expanded(child: Center(child: Text('晚上'))),
                      ],
                    ),
                  ),
                  Row(
                    children: List.generate(
                        12,
                        (index) => Expanded(
                              child: Center(
                                child: Text('${index + 1}'),
                              ),
                            )),
                  )
                ])),
              ],
            ),
            Expanded(
                child: ListView.builder(
              itemBuilder: (c, i) {
                var room = _modifiedRooms[i];
                return Row(
                  children: [
                    Container(
                        alignment: Alignment.center,
                        width: firstColumnWidth,
                        child: Text(
                          room.classroom,
                          textAlign: TextAlign.center,
                        )),
                    ...room.free.map((f) => Expanded(
                          child: GestureDetector(
                            child: StudyRoomCell(
                                color: f
                                    ? Colors.green.withOpacity(0.8)
                                    : const Color(0xcccccccc),
                                size: const Size.square(24)),
                            onTap: () {
                              Toast.show(
                                  '${room.classroom} ${f ? '空闲' : '占用'}');
                            },
                          ),
                        ))
                  ],
                );
              },
              itemCount: _modifiedRooms.length,
            )),
          ],
        ),
      );
    }
  }

  void _doModifyRooms() {
    List<StudyRoom> rooms = [..._rooms];
    rooms.sort((a, b) => a.classroom.compareTo(b.classroom));
    if (_onlyShowFree) {
      DateTime now = DateTime.now();
      DateTime baseline = now.copyWith(hour: 0, minute: 0, second: 0);

      List<DateTime> threshold = [
        baseline.add(const Duration(hours: 7, minutes: 30)),
        baseline.add(const Duration(hours: 9, minutes: 50)),
        baseline.add(const Duration(hours: 12, minutes: 00)),
        baseline.add(const Duration(hours: 15, minutes: 50)),
        baseline.add(const Duration(hours: 18, minutes: 00)),
        baseline.add(const Duration(hours: 20, minutes: 50)),
        baseline.add(const Duration(hours: 22, minutes: 50)),
      ];
      int? index;
      for (int i = 1; i < threshold.length; i++) {
        if (now.isAfter(threshold[i - 1]) && now.isBefore(threshold[i])) {
          index = i - 1;
        }
      }
      rooms = rooms.where((room) {
        if (index == null) {
          return true;
        }
        return room.free[2 * index] & room.free[2 * index + 1];
      }).toList();
    }
    _modifiedRooms.clear();
    _modifiedRooms.addAll(rooms);
  }

  String get _dateString => _date.toString().substring(0, 10);
}

class StudyRoomCell extends StatelessWidget {
  final Color color;
  final Size size;

  const StudyRoomCell({super.key, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width,
      height: size.height,
      constraints: BoxConstraints(maxWidth: size.width, maxHeight: size.height),
      padding: const EdgeInsets.all(2),
      margin: const EdgeInsets.all(2),
      decoration:
          BoxDecoration(borderRadius: BorderRadius.circular(4), color: color),
    );
  }
}
