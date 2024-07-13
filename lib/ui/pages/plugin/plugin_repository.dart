import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hive/hive.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';

import '../../../api/plugin_api.dart';
import '../../../bean/plugin.dart';
import '../../../utils/extensions/context_extension.dart';
import '../../bind_auth_page.dart';
import '../rfw/rfw_container_page.dart';
import '../rfw/rfw_listview_page.dart';
import '../../widgets/toast.dart';

class PluginRepositoryPage extends StatefulWidget {
  const PluginRepositoryPage({super.key});

  @override
  State<PluginRepositoryPage> createState() => _PluginRepositoryPageState();
}

class _PluginRepositoryPageState extends State<PluginRepositoryPage>
    with SingleTickerProviderStateMixin {
  final RefreshController _refreshController =
      RefreshController(initialRefresh: true);
  final List<Plugin> _localPlugins = [];
  final List<Plugin> _repositoryPlugins = [];
  late final TabController _tabController =
      TabController(length: 2, vsync: this);
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _loadLocalPlugins();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('插件管理'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              context.to((context) => const BindAuthPage());
            },
            label: const Text('认证设置'),
            icon: const Icon(Icons.security),
          ),
          TextButton.icon(
            onPressed: () async {
              bool res = await _onImport();
              if (res && mounted) {
                setState(() {});
              }
            },
            label: const Text('导入'),
            icon: const Icon(Icons.cloud_download_rounded),
          ),
        ],
        bottom: TabBar(
            controller: _tabController,
            tabs: const [Tab(text: '本地插件'), Tab(text: '插件仓库')]),
      ),
      body: TabBarView(controller: _tabController, children: [
        _buildLocalPluginListView(),
        _buildRepositoryPluginListView()
      ]),
    );
  }

  Widget _buildLocalPluginListView() {
    if (_localPlugins.isEmpty) {
      return Center(
          child: Text(
        '还没有本地插件哦\n导入一份或者去仓库里找一找吧',
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).hintColor),
      ));
    }
    return ListView.separated(
      itemBuilder: (c, i) {
        var plugin = _localPlugins[i];
        return Slidable(
          endActionPane: ActionPane(
            extentRatio: 0.3,
            openThreshold: 0.2,
            motion: const ScrollMotion(),
            children: [
              SlidableAction(
                onPressed: (_) async {
                  Box<String> pluginBox = await Hive.openBox('plugin');
                  _localPlugins.remove(plugin);
                  pluginBox.delete(plugin.name);
                  setState(() {});
                },
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
                icon: Icons.delete,
                label: '删除',
              ),
            ],
          ),
          child: ListTile(
            title: Text(plugin.name),
            subtitle: Text(plugin.description),
            onTap: () {
              _onLocalPluginTap(plugin);
            },
          ),
        );
      },
      itemCount: _localPlugins.length,
      separatorBuilder: (c, i) => const Divider(
        indent: 12,
        endIndent: 12,
        thickness: 0.5,
        height: 1,
      ),
    );
  }

  Widget _buildRepositoryPluginListView() {
    return SmartRefresher(
      controller: _refreshController,
      onRefresh: _refresh,
      onLoading: _loadMore,
      child: ListView.separated(
        itemBuilder: (c, i) {
          var plugin = _repositoryPlugins[i];
          if (plugin.hide) {
            return const SizedBox.shrink();
          }
          return ListTile(
            title: Text(plugin.name),
            subtitle: Text(plugin.description),
            onTap: () {
              _onRemotePluginTap(plugin);
            },
          );
        },
        itemCount: _repositoryPlugins.length,
        separatorBuilder: (c, i) => const Divider(
          indent: 12,
          endIndent: 12,
          thickness: 0.5,
          height: 1,
        ),
      ),
    );
  }

  Future<void> _loadLocalPlugins() async {
    Box<String> pluginBox = await Hive.openBox('plugin');
    for (var key in pluginBox.keys) {
      _localPlugins.add(Plugin.fromJson(jsonDecode(pluginBox.get(key)!)));
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _refresh() async {
    var res = await PluginAPI.plugins(page: 1);
    if (res.success && res.data!.isNotEmpty) {
      _refreshController.refreshCompleted(resetFooterState: true);
      if (mounted) {
        setState(() {
          _page = 1;
          _repositoryPlugins.clear();
          _repositoryPlugins.addAll(res.data!);
        });
      }
    } else {
      _refreshController.refreshFailed();
    }
  }

  Future<void> _loadMore() async {
    // var res = await PluginAPI.plugins(page: ++_page);
    // if (res.isEmpty) {
    //   _refreshController.loadNoData();
    // } else {
    //   _refreshController.loadComplete();
    //   if (mounted) {
    //     _repositoryPlugins.addAll(res);
    //     setState(() {});
    //   }
    // }
    _refreshController.loadNoData();
  }

  void _onLocalPluginTap(Plugin plugin) {
    switch (plugin.type) {
      case 'listview':
        context.to((_) => RfwListViewPage(plugin: plugin));
        break;
      case 'container':
        context.to((_) => RfwContainerPage(plugin: plugin));
        break;
      default:
        break;
    }
  }

  void _onRemotePluginTap(Plugin plugin) async {
    Box<String> pluginBox = await Hive.openBox('plugin');
    pluginBox.put(plugin.name, jsonEncode(plugin));
    _addLocalPlugin(plugin);
    if (mounted) {
      setState(() {});
    }
    _onLocalPluginTap(plugin);
  }

  Future<bool> _onImport() async {
    try {
      const XTypeGroup typeGroup = XTypeGroup(
        label: 'javascript',
        extensions: <String>['js'],
      );
      final XFile? file =
          await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
      if (file == null) {
        return false;
      }
      String code = await file.readAsString();
      Box<String> pluginBox = await Hive.openBox('plugin');
      Plugin plugin = await _getPluginInfo(code, file.path);
      pluginBox.put(plugin.name, jsonEncode(plugin));
      if (_addLocalPlugin(plugin)) {
        Toast.show('导入成功');
      }
      if (mounted) {
        setState(() {});
      }
    } catch (e, stackTrace) {
      debugPrintStack(label: e.toString(), stackTrace: stackTrace);
      Toast.show('文件不合法或已损坏');
      return false;
    }
    return true;
  }

  Future<Plugin> _getPluginInfo(String pluginCode, String filePath) async {
    JavascriptRuntime runtime = getJavascriptRuntime();
    String wrapper =
        await rootBundle.loadString('assets/js/wrapper.js', cache: true);
    pluginCode = '$pluginCode\n$wrapper\n__wrapper(`info`);';
    JsEvalResult asyncResult = await runtime.evaluateAsync(pluginCode);
    runtime.executePendingJob();
    final promiseResolved = await runtime.handlePromise(asyncResult);
    Map<String, dynamic> jsonMap = jsonDecode(promiseResolved.stringResult);
    jsonMap['url'] = Uri(scheme: 'file', path: filePath).toString();
    return Plugin.fromJson(jsonMap);
  }

  bool _addLocalPlugin(Plugin plugin) {
    if (_localPlugins
        .any((p) => p.name == plugin.name && p.version == plugin.version)) {
      return false;
    }
    _localPlugins.add(plugin);
    return true;
  }
}
