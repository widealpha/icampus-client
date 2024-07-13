import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:go_router/go_router.dart';
import 'pages/onboarding/onboarding_page.dart';
import 'package:provider/provider.dart';

import '../api/base.dart';
import '../api/user_api.dart';
import '../entity/result.dart';
import '../model/user_model.dart';
import '../route/route_config.dart';
import '../utils/extensions/context_extension.dart';
import '../utils/store_utils.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final List<TermOfService> termOfServices = [
    TermOfService(
        id: 'privacy',
        mandatory: true,
        initialValue: false,
        text: '隐私政策',
        linkUrl: '${Server.host}/static/privacy-policy.html',
        validationErrorMessage: '需要同意隐私政策以继续注册'),
  ];
  final Map<String, bool> _termsOfServiceValue = {};
  bool useXueXin = false;

  @override
  void initState() {
    super.initState();
    // UpdateUtils.checkUpdate(context, showDetail: false);
  }

  Future<String?> _authUser(LoginData data) async {
    var result =
        await UserAPI().login(username: data.name, password: data.password);
    if (result.success) {
      var userInfoResult = await UserAPI().userInfo();
      if (userInfoResult.success) {
        if (mounted) {
          Provider.of<UserModel>(context, listen: false).userInfo = userInfoResult.data;
          context.to((_) => const OnboardingPage());
        }
      }

      return null;
    } else {
      return result.message;
    }
  }

  Future<String?> _signupUser(SignupData data) async {
    ResultEntity result = await UserAPI().register(
      username: data.name ?? '',
      password: data.password ?? '',
    );
    if (result.success) {
      return null;
    }
    return result.message;
  }

  @override
  Widget build(BuildContext context) {
    return FlutterLogin(
      // logo: 'assets/images/logo.png',
      savedEmail: 'kmh@example.com',
      savedPassword: '123456',
      title: 'ICampus',
      messages: LoginMessages(
          userHint: '邮箱',
          passwordHint: '密码',
          confirmPasswordHint: '确认密码',
          confirmPasswordError: '两次输入的密码不一致',
          loginButton: '登录',
          signupButton: '注册',
          forgotPasswordButton: '',
          goBackButton: '返回',
          flushbarTitleError: '错误',
          flushbarTitleSuccess: '成功',
          recoverPasswordButton: '恢复',
          recoverPasswordIntro: '恢复密码',
          recoverCodePasswordDescription: '请注意保护好您的个人信息',
          recoveryCodeHint: '恢复密码',
          confirmRecoverIntro: '',
          setPasswordButton: '设置密码'),
      userType: LoginUserType.email,
      termsOfService: termOfServices,
      loginAfterSignUp: true,
      userValidator: (String? username) {
        return null;
      },
      passwordValidator: (String? password) {
        if (password == null || password.isEmpty) {
          return '密码不能为空';
        } else if (password.length < 6) {
          return '密码太短';
        }
        return null;
      },
      onLogin: _authUser,
      onSubmitAnimationCompleted: () {
        context.to((_) => const OnboardingPage());
      },
      // onConfirmRecover: (u,d){
      //   return null;
      // },
      onRecoverPassword: (String username) {
        return null;
      },
      onSignup: _signupUser,
    );
  }
}
