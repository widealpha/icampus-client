import 'package:package_info_plus/package_info_plus.dart';

import 'platform_utils.dart';

class PackageInfoUtils {
  static late String _packageName;
  static late String _appName;
  static late String _version;
  static late String _buildNumber;
  static late int _versionCode;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    PackageInfo packageInfo;
    packageInfo = await PackageInfo.fromPlatform();
    _packageName = packageInfo.packageName;
    _appName = packageInfo.appName;
    _version = packageInfo.version;
    _buildNumber = packageInfo.buildNumber;

    _versionCode = int.parse(packageInfo.buildNumber);

    ///android由于存在不同的abi打包时候会有密度系数的存在
    ///默认密度系数为1000
    ///因此需要单独取模
    ///参考[https://developer.android.com/studio/build/configure-apk-splits?hl=zh-cn#configure-APK-versions]
    ///如果versionCode超过1000引发错误,将此处改成10000即可
    if (PlatformUtils.isAndroid) {
      _versionCode %= 1000;
    }
    _initialized = true;
  }

  static int get versionCode => _versionCode;

  static String get buildNumber => _buildNumber;

  static String get version => _version;

  static String get appName => _appName;

  static String get packageName => _packageName;

  static FlavorEnum get flavor {
    ///This constructor is only guaranteed to work when invoked as `const`.
    const String flavorName =
        String.fromEnvironment('flavor', defaultValue: '');
    if (flavorName.isEmpty) {
      switch (_packageName.split('.').last.toLowerCase()) {
        case 'alpha':
          return FlavorEnum.alpha;
        case 'beta':
          return FlavorEnum.beta;
        case 'nightly':
          return FlavorEnum.nightly;
        default:
          return FlavorEnum.prod;
      }
    } else {
      switch (flavorName) {
        case 'alpha':
          return FlavorEnum.alpha;
        case 'beta':
          return FlavorEnum.beta;
        case 'nightly':
          return FlavorEnum.nightly;
        case 'prod':
        default:
          return FlavorEnum.prod;
      }
    }
  }
}

enum FlavorEnum {
  alpha("alpha"),
  beta("beta"),
  prod("prod"),
  nightly("nightly");

  const FlavorEnum(this.value);

  final String value;
}
