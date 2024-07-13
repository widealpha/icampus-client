import 'dart:async';

import 'package:flutter/material.dart';

class PluginLogPage extends StatefulWidget {
  final Stream<List<String>> stream;

  const PluginLogPage({super.key, required this.stream});

  @override
  State<PluginLogPage> createState() => _PluginLogPageState();
}

class _PluginLogPageState extends State<PluginLogPage> {
  final List<String> logData = [];
  late final StreamSubscription<List<String>> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.stream.listen(_onLogEvent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log'),
      ),
      body: _buildBody(),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _subscription.cancel();
  }

  void _onLogEvent(List<String> newLog) {
    setState(() {
      logData.addAll(newLog);
    });
  }

  Widget _buildBody() {
    return ListView.builder(
      itemBuilder: (c, i) {
        return Text(logData[i]);
      },
      itemCount: logData.length,
    );
  }
}
