import 'dart:io';
import 'package:flutter/foundation.dart';

///跨平台判断平台的util
class PlatformUtils {
  static String get platformName {
    if (kIsWeb) {
      return 'Web';
    } else {
      String s = Platform.operatingSystem;
      return '${s[0].toUpperCase()}${s.substring(1)}';
    }
  }

  static bool get isAndroid => Platform.isAndroid;

  static bool get isDesktop =>
      Platform.isWindows ||
      Platform.isLinux ||
      Platform.isMacOS ||
      Platform.isFuchsia;

  static bool get isMobile => Platform.isAndroid || Platform.isIOS;

  static bool get hasWeb => Platform.isAndroid || Platform.isIOS || kIsWeb;

  static bool get hasCamera => Platform.isAndroid || Platform.isIOS || kIsWeb;
}
