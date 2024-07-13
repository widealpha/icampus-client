import 'package:bot_toast/bot_toast.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../model/user_model.dart';
import '../ui/login_page.dart';
import '../ui/pages/onboarding/onboarding_page.dart';
import '../ui/sub_home_page.dart';

class Routes {
  static const String root = '/';
  static const String chat = 'chat';
  static const String home = 'home';
  static const String login = 'login';
  static const String postDetail = 'post_detail';
  static const String post = 'post';

  static final _routers = GoRouter(
    navigatorKey: Get.key,
    observers: [BotToastNavigatorObserver(), GetObserver()],
    routes: [
      GoRoute(
        name: root,
        path: '/',
        redirect: _loginRedirect,
        builder: (context, state) {
          return const OnboardingPage();
        },
      ),
      GoRoute(
        name: login,
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        name: home,
        path: '/home',
        builder: (context, state) => const SubHomePage(),
      ),
    ],
  );

  static get routers => _routers;

  static String? _loginRedirect(context, state) {
    var provider = Provider.of<UserModel>(context);
    return provider.isLogin ? null : '/login';
  }
}
