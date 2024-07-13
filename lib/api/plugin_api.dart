import 'package:dio/dio.dart';

import '../bean/plugin.dart';
import '../entity/result.dart';
import '../utils/extensions/response_extension.dart';
import '../utils/http_utils.dart';
import '../utils/store_utils.dart';

class PluginAPI {
  static Future<ResultEntity<List<Plugin>>> plugins(
      {int page = 1, int pageSize = 20}) async {
    var response = await HttpUtils.get('/extension/list',
        options: Options(headers: {'Authorization': Store.get('token')}));
    if (response.ok) {
      List list = response.data['data'];
      return ResultEntity.succeed(
          data: list.map((e) => Plugin.fromJson(e)).toList());
    } else {
      return ResultEntity.error(message: response.data['message']);
    }
    // return [
    //   Plugin(
    //       name: '软件学院新闻',
    //       creator: ['Coder'],
    //       description: '一个爬取软件学院新闻网页并显示的示例插件',
    //       updateTime: updateTime,
    //       createTime: createTime,
    //       url: 'https://widealpha.top/rfw/software_news.js',
    //       version: '1.0.0',
    //       type: 'listview',
    //       hide: false),
    //   Plugin(
    //     name: '山大可信证件',
    //     creator: ['Coder'],
    //     description: '山大电子证件平台',
    //     updateTime: updateTime,
    //     createTime: createTime,
    //     url: 'https://widealpha.top/rfw/pki.js',
    //     version: '1.0.0',
    //     type: 'container',
    //     hide: false,
    //   ),
    //   Plugin(
    //     name: '计算器',
    //     creator: ['Coder'],
    //     description: '一个什么也干不了的计算器',
    //     updateTime: updateTime,
    //     createTime: createTime,
    //     url: 'https://widealpha.top/rfw/calculator.js',
    //     version: '1.0.0',
    //     type: 'container',
    //     hide: false,
    //   ),
    //   Plugin(
    //     name: '累加器',
    //     creator: ['Coder'],
    //     description: '一个只能累加的累加器',
    //     updateTime: updateTime,
    //     createTime: createTime,
    //     url: 'https://widealpha.top/rfw/accumulator.js',
    //     version: '1.0.0',
    //     type: 'container',
    //     hide: false,
    //   ),
    //   Plugin(
    //     name: 'hello world',
    //     creator: ['Coder'],
    //     description: 'hello world!',
    //     updateTime: updateTime,
    //     createTime: createTime,
    //     url: 'https://widealpha.top/rfw/helloworld.js',
    //     version: '1.0.0',
    //     type: 'container',
    //     hide: false,
    //   ),
    // ];
  }

  static Future<ResultEntity<Plugin>> getByTitle(String title) async {
    return ResultEntity.succeed(
        data: Plugin.fromJson(
            const {'title': '中国科学院大学', 'content': 'https://widealpha.top/rfw/ucas.js'}));
    var response = await HttpUtils.get('/extension/get-by-title',
        params: {'title': title},
        options: Options(headers: {'Authorization': Store.get('token')}));
    if (response.ok) {
      var plugin = Plugin.fromJson(response.data['data']);
      return ResultEntity.succeed(data: plugin);
    } else {
      return ResultEntity.error(message: response.data['message']);
    }
  }
}
