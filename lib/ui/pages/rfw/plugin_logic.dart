import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_js/extensions/fetch.dart';
import 'package:flutter_js/extensions/xhr.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as path;
import 'package:rfw/formats.dart';
import 'package:rfw/rfw.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../auth/auth_manager.dart';
import '../../../auth/sdu_auth_manager.dart';
import '../../../bean/plugin.dart';
import '../../../utils/cache_utils.dart';
import '../../../utils/clipboard_utils.dart';
import '../../../utils/extensions/context_extension.dart';
import '../../../utils/http_utils.dart';
import '../../../utils/path_utils.dart';
import '../../../utils/platform_utils.dart';
import '../../../utils/store_utils.dart';
import '../../widgets/image_view.dart';
import '../../widgets/safe_stateful_builder.dart';
import '../../widgets/toast.dart';
import 'custom_widget_library.dart';
import 'rfw_container_page.dart';
import 'rfw_listview_page.dart';

class RfwLogic {
  final String routeArguments = '__routeArgs';
  final String infoArguments = '__info';
  final String cacheArguments = '__cache';
  final String authArguments = '__cookie';
  final Runtime _runtime = Runtime();
  final DynamicContent _data = DynamicContent();
  final AuthManager _authManager;
  final Plugin plugin;
  final BuildContext context;
  final String cacheKey;
  late final JavascriptRuntime _logicRuntime;
  late final String _logicCode;
  final Map<String, dynamic> _dataMap = {};
  final bool debug;
  final Box<String> _permissionBox = Store.pluginPermissionBox;
  final List<PluginPermission> _permissions = [];
  final StreamOutput _streamOutput = StreamOutput();
  late final _logger = Logger(printer: PrettyPrinter());

  RfwLogic(this.context, this.plugin, {this.debug = false})
      : _authManager = SduAuthManager(debug: debug),
        cacheKey = 'rfw-${plugin.name}';

  Runtime get runtime => _runtime;

  DynamicContent get data => _data;

  Stream<List<String>> get logStream => _streamOutput.stream.asBroadcastStream();

  Map<String, dynamic> get info {
    if (_dataMap.containsKey(infoArguments) &&
        _dataMap[infoArguments] is Map<String, dynamic>) {
      return _dataMap[infoArguments];
    } else {
      return {};
    }
  }

  String get title {
    return info['name'] ?? plugin.name;
  }

  Future<bool> init(
      {String defaultTitle = '', String? defaultRfwLibrary}) async {
    try {
      _data.subscribe([], _onDataChanged);
      _runtime.update(
          const LibraryName(<String>['core', 'widgets']), createCoreWidgets());
      _runtime.update(const LibraryName(<String>['core', 'material']),
          createMaterialWidgets());
      _runtime.update(
          const LibraryName(<String>['core', 'custom']), createCustomWidgets());
      _logicRuntime = getJavascriptRuntime();
      await _logicRuntime.enableFetch();
      _registerMessageChannel();
      await _prepareLogicCode();
      // _logicCode = const Utf8Codec().decode(await _cacheOrDownload(logicUrl));
      String? rfwCode = await callFunction('__build');
      if (rfwCode == null || rfwCode == 'null') {
        rfwCode = defaultRfwLibrary ?? placeHoldRfwLibrary;
      } else {
        rfwCode = jsonDecode(rfwCode);
      }
      //将CRLF转化为LF
      rfwCode = rfwCode!.replaceAll('\r\n', '\n');
      RemoteWidgetLibrary library = parseLibraryFile(rfwCode);
      _runtime.update(const LibraryName(<String>['main']), library);
      _data.update(cacheArguments, await _loadCache());
      _data.update(routeArguments, _loadRouteArguments());
      _data.update(infoArguments, await _initializeInfo());
      await _initPermissions();
      updateData(await callFunction('__init'));
      return true;
    } catch (e, stackTrace) {
      _logger.e(e, stackTrace: stackTrace);
      return false;
    }
  }

  void updateData(String? data) {
    if (data != null && data != 'null') {
      var jsonMap = jsonDecode(data);
      if (jsonMap is Map<String, dynamic>) {
        jsonMap.removeWhere((key, value) {
          return key.toString().startsWith('__') || value == null;
        });
        _data.updateAll(jsonMap.cast());
      }
    }
  }

  Future<void> onEvent(String name, Map<String, dynamic> arguments) async {
    updateData(await callFunction('__$name', arguments: arguments));
  }

  void dispose() {
    _data.unsubscribe([], _onDataChanged);
    _streamOutput.destroy();
    _logicRuntime.clearXhrPendingCalls();
    _logicRuntime.dispose();
  }

  Future<String?> callFunction(String functionName,
      {Map<String, dynamic> arguments = const {}}) async {
    try {
      String functionCall = await _genFunctionCall(functionName, arguments);
      JsEvalResult asyncResult =
          await _logicRuntime.evaluateAsync(functionCall);
      _logicRuntime.executePendingJob();
      final promiseResolved = await _logicRuntime.handlePromise(asyncResult);
      _logicRuntime.convertValue(promiseResolved);
      if (promiseResolved.isError) {
        _logger.e(promiseResolved.stringResult);
        return null;
      }
      return promiseResolved.stringResult;
    } catch (e, stackTrace) {
      _logger.e(e, stackTrace: stackTrace);
      return null;
    }
  }

  Future<String> _genFunctionCall(
      String functionName, Map<String, dynamic> arguments) async {
    List<String> params = [];
    params.add(jsonEncode(_dataMap));
    params.add(jsonEncode(arguments));
    String code = _logicCode;
    StringBuffer paramBuff = StringBuffer();
    for (var param in params) {
      paramBuff.write(param);
    }
    String paramString = params.join('`,String.raw`');
    if (paramString.isNotEmpty) {
      paramString = 'String.raw`$paramString`';
    }
    String dependency =
        await rootBundle.loadString('assets/js/base.js', cache: true);
    if (functionName.startsWith('__')) {
      String functionWrapper =
          await rootBundle.loadString('assets/js/wrapper.js', cache: true);
      paramString = '`${functionName.substring(2)}`, $paramString';
      String functionCall = '$functionWrapper\n__wrapper($paramString);\n';
      return '$code\n$dependency\n$functionCall';
    } else {
      String functionCall = '$functionName($paramString);\n';
      return '$code\n$dependency\n$functionCall';
    }
  }

  Future<void> _prepareLogicCode() async {
    final code = const Utf8Codec().decode(await _cacheOrDownload(plugin.url));
    _logicCode = code;
  }

  Future<Map<String, dynamic>> _loadCache() async {
    try {
      String? cache = await CacheUtils.loadText(cacheKey);
      Map<String, dynamic> cacheMap;
      if (cache == null) {
        cacheMap = {};
      } else {
        cacheMap = jsonDecode(cache);
      }
      return cacheMap;
    } catch (e, stackTrace) {
      _logger.e(e, stackTrace: stackTrace);
      return {};
    }
  }

  Map<String, dynamic> _loadRouteArguments() {
    var args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic>) {
      return args;
    }
    return {};
  }

  Future<Map<String, dynamic>> _initializeInfo() async {
    String? infoJson = await callFunction('__info');
    if (infoJson != null && infoJson != 'null') {
      Map<String, dynamic> info = jsonDecode(infoJson);
      return info;
    }
    return {};
  }

  Future<void> _initPermissions() async {
    final List<PluginPermission> requiredPermissions = [];
    const String authorityKey = 'authorities';
    List<String> sites = [];
    //获取插件需要的权限信息
    Map<String, dynamic> permissionMap = info['permissions'] ?? {};
    for (var permission in permissionMap.entries) {
      if (permission.key == authorityKey) {
        List authorities = (permission.value ?? []);
        for (var authority in authorities) {
          var pluginPermission = PluginPermission(
              key: '${permission.key}-${authority['value']}',
              name: '登录 ${authority['value']}',
              value: authority['value'] ?? '',
              description: authority['description'] ?? '',
              required: authority['required'] ?? false,
              state: PermissionStatus.prompt);
          requiredPermissions.add(pluginPermission);
        }
      } else {
        PluginPermission? pluginPermission = PluginPermission(
            key: permission.key,
            name: '',
            value: permission.value['value'] ?? '',
            description: permission.value['description'] ?? '',
            required: permission.value['required'] ?? false,
            state: PermissionStatus.prompt);
        switch (permission.key) {
          case 'autoStart':
            pluginPermission.name = '自启动';
            break;
          case 'user':
            pluginPermission.name = '用户信息';
            break;
          case 'download':
            pluginPermission.name = '下载';
            break;
          default:
            pluginPermission = null;
            break;
        }
        if (pluginPermission != null) {
          requiredPermissions.add(pluginPermission);
        }
      }
    }
    //不需要任何权限,或者所有权限都是非必须要的直接返回
    if (requiredPermissions.isEmpty ||
        requiredPermissions.every((permission) => !permission.required)) {
      return;
    }
    //获取已经操作保存过的权限信息
    String storePermissions =
        _permissionBox.get(info['name'], defaultValue: '[]')!;
    List list = jsonDecode(storePermissions);
    List<PluginPermission> savedPermissions =
        list.map((e) => PluginPermission.fromJson(e)).toList();
    for (var requiredPermission in requiredPermissions) {
      for (var savedPermission in savedPermissions) {
        if (requiredPermission.key == savedPermission.key) {
          requiredPermission.state = savedPermission.state;
        }
      }
      _permissions.add(requiredPermission);
    }
    //如果所有必要的权限都已经给予，不弹出权限申请
    if (requiredPermissions.any((permission) =>
        permission.required && permission.state != PermissionStatus.granted)) {
      await showModalBottomSheet(
          context: context,
          isDismissible: false,
          useSafeArea: true,
          enableDrag: false,
          builder: (context) {
            return PopScope(
                canPop: false,
                child: SafeStatefulBuilder(builder: (context, setState) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          CloseButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                          ),
                          const Spacer(),
                          TextButton(
                            child: const Text('确认授权'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
                      ...requiredPermissions.map((permission) =>
                          CheckboxListTile(
                            value: permission.state == PermissionStatus.granted,
                            onChanged: (granted) {
                              String state;
                              if (granted == null) {
                                state = PermissionStatus.prompt;
                              } else if (granted) {
                                state = PermissionStatus.granted;
                              } else {
                                state = PermissionStatus.denied;
                              }
                              setState(() {
                                permission.state = state;
                              });
                            },
                            title: Text(permission.name),
                            subtitle: Text(permission.description),
                          )),
                    ],
                  );
                }));
          });
      _permissionBox.put(info['name'], jsonEncode(_permissions));
    }
    //下面筛选获取到的authority然后登录
    for (var permission in requiredPermissions) {
      if (permission.state == PermissionStatus.granted &&
          permission.key.startsWith(authorityKey)) {
        sites.add(permission.value);
      }
    }
    Map<String, String> cookies = {};
    for (var site in sites) {
      String? cookie = await _authManager.cookie(site);
      if (cookie != null) {
        cookies[site] = cookie;
      }
    }
    _data.updateAll({authArguments: cookies});
  }

  Future<Uint8List> _cacheOrDownload(String url,
      {Duration expires = Duration.zero}) async {
    Uint8List? data = await CacheUtils.loadCacheFile(url);
    if (data != null) {
      return data;
    } else {
      Uri uri = Uri.parse(url);
      if (uri.scheme == 'file') {
        data = await XFile(uri.toFilePath()).readAsBytes();
      } else {
        var response = await HttpUtils.get(url,
            options: Options(responseType: ResponseType.bytes));
        data = response.data;
      }
      if (data != null) {
        CacheUtils.cacheFile(url, data, expires: expires);
        return data;
      }
    }
    return Uint8List.fromList([]);
  }

  void _registerMessageChannel() {
    _logicRuntime.onMessage('message', (args) {
      if (args is String) {
        Toast.show(args);
      } else if (args is Map<String, dynamic>) {
        Toast.show(args['content']);
      }
    });
    _logicRuntime.onMessage('open', (args) {
      Map<String, dynamic> arguments = args;
      launchUrlString(arguments['url'], mode: LaunchMode.externalApplication);
    });
    _logicRuntime.onMessage('share', (args) {
      Share.share(args['content']);
    });
    _logicRuntime.onMessage('copy', (args) {
      ClipboardUtils.copy(args['content']);
    });
    _logicRuntime.onMessage('cache', (args) async {
      Map<String, dynamic> cacheMap = await _loadCache();
      cacheMap[args['key']] = args['value'];
      await CacheUtils.cacheText(cacheKey, jsonEncode(cacheMap));
      _data.update(cacheArguments, cacheMap);
      if (args['showSuccessMessage'] ?? false) {
        Toast.show(args['successMessage'] ?? '缓存成功');
      }
    });
    _logicRuntime.onMessage('view', (args) {
      context.to((_) => ImageView.network(args['url']));
    });
    _logicRuntime.onMessage('download', (args) async {
      Map<String, dynamic> arguments = args;
      String suggestName =
          arguments['name'] ?? '${arguments['url']}'.split('/').last;
      bool download = await showDialog<bool>(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('确认下载'),
                  content: Text('确认要下载$suggestName吗'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('取消')),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('确认'))
                  ],
                );
              }) ??
          false;
      if (!download) {
        return;
      }
      String? savePath;

      if (PlatformUtils.isDesktop) {
        var location = await getSaveLocation(suggestedName: suggestName);
        savePath = location?.path;
      } else {
        savePath = path.join(await PathUtils.downloadPath(), suggestName);
      }
      if (savePath == null) {
        return;
      }
      Toast.show('$suggestName 下载中...');
      await HttpUtils.download(
        arguments['url'],
        savePath,
        options: Options(
          headers: {'cookie': arguments['cookie']},
        ),
        onReceiveProgress: (received, total) {
          if (total <= 0) return;
          if (received == total) {
            Toast.show('下载完成');
            if (PlatformUtils.isMobile) {
              OpenFilex.open(savePath);
            }
          }
        },
      );
    });
    _logicRuntime.onMessage('route', (args) {
      Map<String, dynamic> routeArgs;
      if (args != null) {
        if (args is Map<String, dynamic>) {
          routeArgs = args;
        } else if (args is String) {
          routeArgs = jsonDecode(args);
        } else {
          return;
        }
        String newUrl = routeArgs['url'];
        if (!path.isAbsolute(newUrl)) {
          Uri uri = Uri.parse(plugin.url);
          newUrl = uri.resolve(routeArgs['url']).toString();
        }
        Plugin childPlugin = Plugin.fromJson(routeArgs);
        childPlugin = childPlugin.copyWith(url: newUrl);
        if (routeArgs['type'] == 'listview') {
          context.to((_) => RfwListViewPage(plugin: childPlugin),
              arguments: routeArgs);
        } else if (routeArgs['type'] == 'container') {
          context.to((_) => RfwContainerPage(plugin: childPlugin),
              arguments: routeArgs);
        }
      }
    });
  }

  String get placeHoldRfwLibrary {
    return '''
import core.widgets;
import core.material;

widget root = Center(
  child: Text(text: ["Empty"]),
);
''';
  }

  void _onDataChanged(Object message) {
    if (message is Map<String, dynamic>) {
      _logger.d(message);
      _dataMap.addAll(message);
    }
  }
}
