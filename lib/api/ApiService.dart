import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:qasioun_tv/model/movie_model.dart';

class ApiService {
  // ✅ روابط الأقسام العربية
  static const String moviesApiUrl =
      'https://api.npoint.io/5b7128a45d775d19a493';
  static const String arabicSeriesApiUrl =
      'https://api.npoint.io/05a92c3c7b6149e05d26';

  // ✅ الروابط الأجنبية وديزني
  static const String foreignMoviesApiUrl =
      'https://api.npoint.io/a67e6086bd8ab4d2d775';
  static const String foreignSeriesApiUrl =
      'https://api.npoint.io/5bb89b9dc5901f6f3fbb';
  static const String disneyMoviesApiUrl =
      'https://api.npoint.io/6c8825569553e4c569ce';

  // ✅ قسم المسلسلات التركية الجديد
  static const String turkishSeriesApiUrl =
      'https://api.npoint.io/a8709b43187b9f242518';

  // 🔴 رابط البث المباشر (Live TV)
  static const String liveChannelsApiUrl =
      'https://api.npoint.io/f575068a82f14f5bf05d';

  // 🔹 جلب الأفلام العربية
  static Future<List<Movie>> getMovies() async =>
      _fetchData(moviesApiUrl);

  // 🔹 جلب المسلسلات العربية
  static Future<List<Movie>> getArabicSeries() async =>
      _fetchData(arabicSeriesApiUrl);

  // 🔹 جلب الأفلام الأجنبية
  static Future<List<Movie>> getForeignMovies() async =>
      _fetchData(foreignMoviesApiUrl);

  // 🔹 جلب المسلسلات الأجنبية
  static Future<List<Movie>> getForeignSeries() async =>
      _fetchData(foreignSeriesApiUrl);

  // 🔹 جلب أفلام ديزني وأنمي
  static Future<List<Movie>> getDisneyMovies() async =>
      _fetchData(disneyMoviesApiUrl);

  // 🔹 جلب المسلسلات التركية (الجديدة)
  static Future<List<Movie>> getTurkishSeries() async =>
      _fetchData(turkishSeriesApiUrl);

  // 🔴 جلب القنوات المباشرة
  static Future<List<Movie>> getLiveChannels() async =>
      _fetchData(liveChannelsApiUrl);

  // 🔍 البحث في جميع الأقسام
  static Future<List<Movie>> searchContent(String query) async {
    if (query.isEmpty) return [];

    final allFutures = await Future.wait([
      getMovies(),
      getArabicSeries(),
      getForeignMovies(),
      getForeignSeries(),
      getDisneyMovies(),
      getTurkishSeries(), // إضافة المسلسلات التركية للبحث
      getLiveChannels(),
    ]);

    final allContent = allFutures.expand((list) => list).toList();

    return allContent
        .where((item) =>
            item.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // 🔧 دالة عامة لجلب البيانات من أي رابط
  static Future<List<Movie>> _fetchData(String url) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Movie.fromJson(json)).toList();
      } else {
        print('❌ Error: Failed to load data from $url (${response.statusCode})');
        return [];
      }
    } catch (e) {
      print('❌ Exception: $e');
      return [];
    }
  }
}