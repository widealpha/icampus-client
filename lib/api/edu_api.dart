import '../utils/cache_utils.dart';
import '../utils/http_utils.dart';
import 'base.dart';

class EduAPI {
  static EduAPI? instance;
  final String _weekdayCacheKey = 'weekdayCache';
  final String _firstWeekday = '${Server.edu}/weekday';

  EduAPI._();

  factory EduAPI() {
    instance ??= EduAPI._();
    return instance!;
  }

  Future<DateTime> firstWeekday({bool useCache = true}) async {
    if (useCache) {
      String? cache = await CacheUtils.loadText(_weekdayCacheKey);
      if (cache != null) {
        return DateTime.parse(cache);
      }
    }
    // var response = await HttpUtils.get(_firstWeekday);
    DateTime time = DateTime(2024, 2, 26);
    CacheUtils.cacheText(_weekdayCacheKey, time.toString());
    return time;
  }

  Future<String?> curTerm() async {
    // var response = await HttpUtils.get(_firstWeekday);
    return '2024春季学期';
  }
}
