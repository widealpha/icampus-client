import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:icampus/utils/extensions/context_extension.dart';

import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:rfw/rfw.dart';

import '../../../bean/plugin.dart';
import 'plugin_logic.dart';
import 'plugin_setting_page.dart';


class RfwListViewPage extends StatefulWidget {
  final Plugin plugin;

  const RfwListViewPage({
    super.key,
    required this.plugin,
  });

  @override
  State<RfwListViewPage> createState() => _RfwListViewPageState();
}

class _RfwListViewPageState extends State<RfwListViewPage> {
  late final RfwLogic _rfwLogic = RfwLogic(context, widget.plugin);
  final RefreshController _controller = RefreshController(initialRefresh: true);
  final List<Map<String, dynamic>> _list = [];

  bool _loading = true;
  int _page = 1;

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
        actions: _loading
            ? null
            : [
                if (_info.isNotEmpty)
                  IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (c) => SimpleDialog(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
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
                      },
                      icon: const Icon(Icons.info_outline_rounded)),
                IconButton(
                    onPressed: () {
                      context.to((_) => PluginSettingPage(plugin: widget.plugin));
                    },
                    icon: const Icon(Icons.settings_rounded))
              ],
      ),
      body: buildBody(),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _rfwLogic.dispose();
  }

  Widget buildBody() {
    Widget child;
    if (_loading) {
      child = const Center(child: CircularProgressIndicator());
    } else {
      child = SmartRefresher(
        controller: _controller,
        enablePullUp: true,
        onRefresh: _refresh,
        onLoading: _loadMore,
        child: ListView.builder(
          itemBuilder: (c, i) {
            final DynamicContent content = DynamicContent();
            content.updateAll(_list[i]);
            return RemoteWidget(
              runtime: _rfwLogic.runtime,
              data: content,
              widget: const FullyQualifiedWidgetName(
                  LibraryName(<String>['main']), 'root'),
              onEvent: (String name, DynamicMap arguments) async {
                switch (name) {
                  case 'refresh':
                    _controller.refreshCompleted(resetFooterState: true);
                    break;
                  default:
                    _rfwLogic.onEvent(name, _list[i]);
                    break;
                }
              },
            );
          },
          itemCount: _list.length,
        ),
      );
    }
    return child;
  }

  Future<void> _refresh() async {
    String? result = await _rfwLogic.callFunction('__refresh');
    if (result == null) {
      _controller.refreshFailed();
    } else {
      List data = jsonDecode(result);
      _list.clear();
      _list.addAll(data.cast());
      _controller.refreshCompleted(resetFooterState: true);
      if (mounted) {
        _page = 1;
        setState(() {});
      }
    }
  }

  Future<void> _loadMore() async {
    String? result = await _rfwLogic
        .callFunction('__loadMore', arguments: {'page': ++_page});
    if (result == null) {
      _controller.loadFailed();
    } else {
      List data = jsonDecode(result);
      if (data.isEmpty) {
        _page--;
        _controller.loadNoData();
      } else {
        _list.addAll(data.cast());
        _controller.loadComplete();
        if (mounted) {
          setState(() {});
        }
      }
    }
  }

  String get defaultRfwLibrary {
    return '''
import core.widgets;
import core.material;

widget root = ListTile(
  title: Text(text: [data.title]),
  subtitle: Text(text: [data.subtitle]),
  trailing: Text(text: [data.trailing]),
  onTap: event "route" { arguments: [] },
);
''';
  }
}
