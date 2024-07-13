import 'package:flutter/material.dart';
import 'timetable_page.dart';

import 'function_page.dart';
import 'reset_user_page.dart';

class SubHomePage extends StatefulWidget {
  const SubHomePage({super.key});

  @override
  State<SubHomePage> createState() => _SubHomePageState();
}

class _SubHomePageState extends State<SubHomePage> {
  final List<Widget> _pages = const [
    TimeTablePage(),
    FunctionPage(),
    ResetUserPage(),
  ];
  late int _pageIndex = 0;
  bool loading = true;
  bool userExist = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(builder: (context) {
        // if (loading) {
        //   return Scaffold(
        //     appBar: AppBar(),
        //     body: const Center(child: CircularProgressIndicator()),
        //   );
        // }
        return IndexedStack(
          index: _pageIndex,
          children: _pages,
        );
      }),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _pageIndex,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_4x4_rounded),
            label: '课程表',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz_rounded),
            label: '其他',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_circle_rounded),
            label: '账户',
          ),
        ],
        onDestinationSelected: (int index) {
          _pageIndex = index % _pages.length;
          setState(() {});
        },
      ),
    );
  }
}
