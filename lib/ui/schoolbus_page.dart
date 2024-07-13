import 'package:flutter/material.dart';

import '../api/schoolbus_api.dart';
import '../bean/schoolbus.dart';
import '../utils/cache_utils.dart';
import '../utils/extensions/context_extension.dart';

class SchoolBusPage extends StatefulWidget {
  const SchoolBusPage({super.key});

  @override
  State<SchoolBusPage> createState() => _SchoolBusPageState();
}

class _SchoolBusPageState extends State<SchoolBusPage> {
  final _fromKey = 'busFrom';
  final _toKey = 'busTo';
  final List<String> _campusNames = [
    '中心校区',
    '洪家楼校区',
    '趵突泉校区',
    '软件园校区',
    '兴隆山校区',
    '千佛山校区'
  ];
  String _from = '';
  String _to = '';

  @override
  void initState() {
    super.initState();
  }

  Future<void> initData() async {
    _from = await CacheUtils.loadText(_fromKey) ?? _campusNames[0];
    _to = await CacheUtils.loadText(_toKey) ?? _campusNames[1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('校车'),
      ),
      body: Column(
        children: [
          ListTile(
            leading: const Text('始发站: '),
            title: Text(_from),
            trailing: TextButton(
                onPressed: () async {
                  String? s = await chooseCampus();
                  if (s != null) {
                    setState(() {
                      _from = s;
                    });
                  }
                },
                child: const Text('更改')),
          ),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: InkWell(
                    onTap: () {
                      String temp = _from;
                      _from = _to;
                      _to = temp;
                      setState(() {});
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.0),
                      child: Icon(Icons.swap_vert_rounded),
                    )),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          ListTile(
            leading: const Text('终点站: '),
            title: Text(_to),
            trailing: TextButton(
                onPressed: () async {
                  String? s = await chooseCampus();
                  if (s != null) {
                    setState(() {
                      _to = s;
                    });
                  }
                },
                child: const Text('更改')),
          ),
          const SizedBox(
            height: 8,
          ),
          ElevatedButton(
              onPressed: () {
                CacheUtils.cacheText(_fromKey, _from);
                CacheUtils.cacheText(_toKey, _to);
                context.to((_) => SchoolBusResultPage(_from, _to));
              },
              child: const Text('查询'))
        ],
      ),
    );
  }

  Future<String?> chooseCampus() {
    return showDialog<String>(
        context: context,
        builder: (c) {
          return SimpleDialog(
            children: [
              ..._campusNames.map((campus) => SimpleDialogOption(
                    child: Text(campus),
                    onPressed: () {
                      Navigator.of(context).pop(campus);
                    },
                  )),
            ],
          );
        });
  }
}

class SchoolBusResultPage extends StatefulWidget {
  final String from;
  final String to;

  const SchoolBusResultPage(this.from, this.to, {super.key});

  @override
  State createState() => _SchoolBusResultState();
}

class _SchoolBusResultState extends State<SchoolBusResultPage>
    with SingleTickerProviderStateMixin {
  late String from = widget.from;
  late String to = widget.to;
  var weekDayList = <SchoolBus>[];
  var weekendList = <SchoolBus>[];
  bool isLoading = true;

  late final TabController _controller = TabController(length: 2, vsync: this);

  Future<void> search() async {
    setState(() {
      isLoading = true;
    });
    weekDayList = await SchoolBusAPI().searchSchoolBus(from, to, false);
    weekendList = await SchoolBusAPI().searchSchoolBus(from, to, true);

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    search();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          child: Text('$from -> $to'),
          onTap: () {
            var temp = from;
            from = to;
            to = temp;
            search();
          },
        ),
        actions: [
          IconButton(
              onPressed: () {
                var temp = from;
                from = to;
                to = temp;
                search();
              },
              icon: const Icon(Icons.swap_horiz_rounded))
        ],
        bottom: TabBar(
          tabs: const <Widget>[
            Tab(
              text: '工作日',
            ),
            Tab(
              text: '非工作日',
            )
          ],
          controller: _controller,
        ),
      ),
      body: TabBarView(
        controller: _controller,
        children: <Widget>[weekDayTab(), weekendTab()],
      ),
    );
  }

  Widget weekDayTab() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else if (weekDayList.isEmpty) {
      return Center(
        child: Center(
          child: Text(
            '未查询到信息',
            style: TextStyle(color: context.theme.disabledColor, fontSize: 18),
          ),
        ),
      );
    } else {
      return ListView.builder(
        itemCount: weekDayList.length,
        itemBuilder: (context, index) {
          return _buildCard(weekDayList[index]);
        },
      );
    }
  }

  Widget weekendTab() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else if (weekendList.isEmpty) {
      return Center(
        child: Center(
          child: Text(
            '未查询到信息',
            style: TextStyle(color: context.theme.disabledColor, fontSize: 18),
          ),
        ),
      );
    } else {
      return ListView.builder(
        itemCount: weekendList.length,
        itemBuilder: (context, index) {
          return _buildCard(weekendList[index]);
        },
      );
    }
  }

  Widget _buildCard(SchoolBus bus) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '发车时间: ${bus.time}',
              style: TextStyle(
                  color: context.theme.colorScheme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            Container(
              height: 4,
            ),
            Text.rich(TextSpan(children: <TextSpan>[
              TextSpan(
                  text: '始${' ' * 8}',
                  style: TextStyle(color: context.theme.disabledColor)),
              TextSpan(
                  text: bus.from,
                  style: TextStyle(color: context.theme.colorScheme.onSurface))
            ])),
            Text.rich(TextSpan(children: <TextSpan>[
              TextSpan(
                  text: '经${' ' * 8}',
                  style: TextStyle(color: context.theme.disabledColor)),
              TextSpan(
                  text: bus.pass,
                  style: TextStyle(color: context.theme.colorScheme.onSurface))
            ])),
            Text.rich(TextSpan(children: <TextSpan>[
              TextSpan(
                  text: '终${' ' * 8}',
                  style: TextStyle(color: context.theme.disabledColor)),
              TextSpan(
                  text: bus.to,
                  style: TextStyle(color: context.theme.colorScheme.onSurface))
            ])),
          ],
        ),
      ),
    );
  }
}
