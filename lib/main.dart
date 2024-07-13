import 'dart:convert';
import 'dart:ui';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'route/route_config.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';

import 'api/base.dart';
import 'bean/user_info.dart';
import 'model/user_model.dart';
import 'provider/theme_provider.dart';
import 'utils/http_utils.dart';
import 'utils/package_info_utils.dart';
import 'utils/sp_utils.dart';
import 'utils/store_utils.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PackageInfoUtils.initialize();
  await SPUtils.initialize();
  await Store.initialize();
  HttpUtils.config(baseUrl: Server.baseUrl);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  //不能是Future去报串行执行初始化
  void initSetting(BuildContext context) {
    if (SPUtils.boolWithDefault(SPEnum.init, defaultValue: false)) {
      return;
    } else {
      SPUtils.setBool(SPEnum.init, true);
      SPUtils.setBool(SPEnum.themeModeFollowSystem, true);
      SPUtils.setBool(SPEnum.darkThemeMode, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    initSetting(context);
    ColorScheme? colorScheme;
    int? colorSeed = SPUtils.getInt(SPEnum.themeColor);
    if (colorSeed != null) {
      colorScheme = ColorScheme.fromSeed(seedColor: Color(colorSeed));
    }
    ThemeMode themeMode = ThemeMode.system;
    if (SPUtils.boolWithDefault(SPEnum.themeModeFollowSystem,
        defaultValue: true)) {
      themeMode = ThemeMode.system;
    } else if (SPUtils.boolWithDefault(SPEnum.darkThemeMode,
        defaultValue: false)) {
      themeMode = ThemeMode.dark;
    } else {
      themeMode = ThemeMode.light;
    }
    ThemeProvider provider = ThemeProvider();
    provider.themeMode = themeMode;
    provider.theme = ThemeData(colorScheme: colorScheme, useMaterial3: true);
    provider.darkTheme = ThemeData.dark(useMaterial3: true);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserModel()),
      ],
      // listenable: provider,
      builder: (context, child) {
        return MaterialApp.router(
          key: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'ICampus',
          theme: provider.theme,
          darkTheme: provider.darkTheme,
          themeMode: provider.themeMode,
          //添加国际化支持
          localizationsDelegates: const [
            // SmartRefresh国际化支持
            RefreshLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate
          ],
          supportedLocales: const [
            Locale('zh', 'CN'),
            Locale('en', 'US'),
          ],
          locale: const Locale('zh', 'CN'),
          scrollBehavior: CustomScrollBehavior(),
          routerConfig: Routes.routers,
          builder: BotToastInit(),
        );
      },
    );
  }

  ThemeMode get themeMode =>
      SPUtils.boolWithDefault(SPEnum.themeModeFollowSystem)
          ? ThemeMode.system
          : SPUtils.boolWithDefault(SPEnum.darkThemeMode)
              ? ThemeMode.dark
              : ThemeMode.light;
}

class CustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        // 手机触摸屏
        PointerDeviceKind.touch,
        // 鼠标拖动
        PointerDeviceKind.mouse,
        // 笔记本触摸板
        PointerDeviceKind.trackpad,
      };
}
