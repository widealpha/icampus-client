import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:rfw/rfw.dart';

import '../../../bean/plugin.dart';
import '../../../utils/extensions/context_extension.dart';
import 'plugin_logic.dart';
import 'plugin_setting_page.dart';
import 'rfw_log_page.dart';

class RfwContainerPage extends StatefulWidget {
  final Plugin plugin;

  const RfwContainerPage({
    super.key,
    required this.plugin,
  });

  @override
  State<RfwContainerPage> createState() => _RfwContainerPageState();
}

class _RfwContainerPageState extends State<RfwContainerPage> {
  late final RfwLogic _rfwLogic = RfwLogic(context, widget.plugin, debug: true);
  bool _loading = true;

  Map<String, dynamic> get _info => _rfwLogic.info;

  String get _title => _rfwLogic.title;

  @override
  void initState() {
    super.initState();
    _rfwLogic.init(defaultRfwLibrary: defaultRfwLibrary).then((success) {
      if (success && mounted) {
        setState(() {
          _loading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: _buildAppbarActions(),
      ),
      // endDrawer: PluginLogPage(stream: _rfwLogic.logStream),
      body: SafeArea(
        child: Builder(builder: (context) {
          if (_loading) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return RemoteWidget(
              runtime: _rfwLogic.runtime,
              data: _rfwLogic.data,
              widget: const FullyQualifiedWidgetName(
                  LibraryName(<String>['main']), 'root'),
              onEvent: _rfwLogic.onEvent,
            );
          }
        }),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _rfwLogic.dispose();
  }

  List<Widget> _buildAppbarActions() {
    List<Widget> actions = [];
    if (!_loading) {
      if (_info.isNotEmpty) {
        actions.add(IconButton(
            onPressed: () => _showInfoDialog(),
            icon: const Icon(Icons.info_outline_rounded)));
      }

    }
    actions.add(IconButton(
        onPressed: () {
          context.to((_) => PluginSettingPage(plugin: widget.plugin));
        },
        icon: const Icon(Icons.settings_rounded)));
    if (kDebugMode) {
      actions.add(IconButton(
          onPressed: () {
            context.to((_) => PluginLogPage(stream: _rfwLogic.logStream));
          },
          icon: const Icon(Icons.developer_mode)));
    }

    return actions;
  }

  Future<void> _showInfoDialog() {
    return showDialog(
      context: context,
      builder: (c) => SimpleDialog(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        title: const Text('插件信息'),
        children: _info.keys.map((key) {
          return Row(
            children: [
              Text(key),
              const Spacer(),
              Text(_info[key].toString()),
            ],
          );
        }).toList(),
      ),
    );
  }

  String get defaultRfwLibrary {
    return '''
import core.widgets;
import core.material;

widget root = Center(
  child: Text(text: ["Empty"]),
);
''';
  }
}
