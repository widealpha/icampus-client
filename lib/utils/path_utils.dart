import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class PathUtils {
  static Future<String> getStoragePath() async {
    if (Platform.isAndroid){
      return (await getExternalStorageDirectory())!.path;
    } else {
      return (await getApplicationDocumentsDirectory()).path;
    }
  }

  ///内部存储路径
  static Future<String> dataPath() async {
    return (await getApplicationDocumentsDirectory()).path;
  }

  ///缓存目录
  static Future<String> cachePath() async {
    return (await getTemporaryDirectory()).path;
  }

  static Future<String> downloadPath() async {
    String value = join(await getStoragePath(), 'download');
    if (!Directory(value).existsSync()) {
      Directory(value).createSync(recursive: true);
    }
    return value;
  }

  static Future<String> downloadImagePath() async {
    String value = join(await getStoragePath(), 'images');
    if (!Directory(value).existsSync()) {
      Directory(value).createSync(recursive: true);
    }
    return value;
  }
}