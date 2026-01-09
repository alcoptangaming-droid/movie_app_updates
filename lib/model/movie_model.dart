// lib/model/movie_model.dart

import 'episode.dart'; // تأكد أن هذا الملف موجود وبه كلاس Episode مع fromJson/toJson

class Movie {
  final int? id; // معرف الفيلم/المسلسل
  final String title; // العنوان الأساسي
  final String name; // الاسم (قد يكون نفس العنوان)
  final String? year; // سنة الإنتاج
  final String description; // الوصف
  final String category; // التصنيف
  final String? duration; // المدة
  final String? type; // النوع: 'movie', 'series', 'live'
  final String imageAsset; // مسار الصورة المحلية
  final String imageUrl; // رابط الصورة من الشبكة
  final String? videoUrl; // رابط الفيديو المباشر
  final String overview; // نظرة عامة
  final String? posterPath; // مسار/رابط البوستر
  final String? backdropPath; // مسار/رابط صورة الخلفية
  final String? releaseDate; // تاريخ الإصدار
  final double? voteAverage; // متوسط التقييم
  final double? rating; // التقييم
  final bool isFavorite; // هل هو في المفضلة؟
  final List<Episode>? episodes; // قائمة الحلقات
  final bool isLocalImage;
  final String quality; // ⭐️ جودة البث (HD, SD, إلخ)
  final bool isHD; // ⭐️ هل الجودة عالية؟

  Movie({
    this.id,
    required this.title,
    String? name,
    this.year,
    required this.description,
    required this.category,
    this.duration,
    this.type,
    this.imageAsset = '',
    this.imageUrl = '',
    this.videoUrl,
    String? overview,
    this.posterPath,
    this.backdropPath,
    this.releaseDate,
    this.voteAverage,
    this.rating,
    this.isFavorite = false,
    this.episodes,
    bool? isLocalImage,
    this.quality = 'HD', // ✅ قيمة افتراضية
    this.isHD = true, // ✅ قيمة افتراضية
  })  : name = name ?? title,
        overview = overview ?? description,
        isLocalImage = isLocalImage ?? (imageAsset.isNotEmpty && imageUrl.isEmpty && (posterPath == null || posterPath!.isEmpty));

  // دالة مساعدة للحصول على الصورة المناسبة للعرض
  String get displayImage {
    if (imageUrl.isNotEmpty) return imageUrl;
    if (posterPath != null && posterPath!.isNotEmpty) return posterPath!;
    if (imageAsset.isNotEmpty) return imageAsset;
    return 'assets/placeholder_image.jpg'; // صورة افتراضية إذا لم يوجد شيء
  }

  // ⭐️ Factory constructor لتحويل JSON إلى كائن Movie
  factory Movie.fromJson(Map<String, dynamic> json) {
    try {
      // ⭐️ معالجة episodes إذا كانت موجودة
      List<Episode>? episodesList;
      if (json['episodes'] != null && json['episodes'] is List) {
        try {
          final episodesData = json['episodes'] as List;
          episodesList = episodesData
              .whereType<Map<String, dynamic>>()
              .map<Episode>((episodeJson) => Episode.fromJson(episodeJson))
              .toList();
        } catch (e) {
          print("Error parsing episodes from JSON: $e");
          episodesList = [];
        }
      }

      // ⭐️ معالجة القيم الأساسية
      final id = json['id'] != null 
          ? (json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()))
          : null;
      
      final title = json['title']?.toString() ?? 'No Title';
      final description = json['description']?.toString() ?? '';
      final category = json['category']?.toString() ?? 'General';
      
      // ⭐️ معالجة الصور
      final imageAsset = json['imageAsset']?.toString() ?? '';
      final imageUrl = json['imageUrl']?.toString() ?? '';
      final posterPath = json['posterPath']?.toString();
      final backdropPath = json['backdropPath']?.toString();
      
      // ⭐️ تحديد isLocalImage
      final bool isLocalImg = json['isLocalImage'] as bool? ?? 
          (imageAsset.isNotEmpty && imageUrl.isEmpty && (posterPath == null || posterPath!.isEmpty));

      // ⭐️ معالجة جودة البث
      final quality = json['quality']?.toString() ?? 'HD';
      final isHD = json['isHD'] as bool? ?? 
          (quality.toLowerCase().contains('hd') || 
           quality.toLowerCase().contains('عالية') ||
           quality.toLowerCase().contains('high') ||
           quality.toLowerCase().contains('1080') ||
           quality.toLowerCase().contains('720'));

      return Movie(
        id: id,
        title: title,
        name: json['name']?.toString() ?? title,
        year: json['year']?.toString(),
        description: description,
        category: category,
        duration: json['duration']?.toString(),
        type: json['type']?.toString() ?? 'movie',
        imageAsset: imageAsset,
        imageUrl: imageUrl,
        videoUrl: json['videoUrl']?.toString(),
        overview: json['overview']?.toString() ?? description,
        posterPath: posterPath,
        backdropPath: backdropPath,
        releaseDate: json['releaseDate']?.toString(),
        voteAverage: _parseDouble(json['voteAverage']),
        rating: _parseDouble(json['rating']),
        isFavorite: json['isFavorite'] == true,
        episodes: episodesList,
        isLocalImage: isLocalImg,
        quality: quality,
        isHD: isHD,
      );
    } catch (e) {
      print("Error creating Movie from JSON: $e");
      print("JSON data: $json");
      // ⭐️ إرجاع فيلم افتراضي في حالة الخطأ
      return Movie(
        id: 0,
        title: 'Error Movie',
        description: 'Failed to load movie data',
        category: 'Error',
        quality: 'HD',
        isHD: false,
      );
    }
  }

  // ⭐️ دالة مساعدة لتحويل القيم إلى double
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  // ⭐️ دالة لتحويل كائن Movie إلى JSON
  Map<String, dynamic> toJson() {
    try {
      final Map<String, dynamic> json = {
        'id': id,
        'title': title,
        'name': name,
        'year': year,
        'description': description,
        'category': category,
        'duration': duration,
        'type': type,
        'imageAsset': imageAsset,
        'imageUrl': imageUrl,
        'videoUrl': videoUrl,
        'overview': overview,
        'posterPath': posterPath,
        'backdropPath': backdropPath,
        'releaseDate': releaseDate,
        'voteAverage': voteAverage,
        'rating': rating,
        'isFavorite': isFavorite,
        'isLocalImage': isLocalImage,
        'quality': quality, // ✅ حفظ جودة البث
        'isHD': isHD, // ✅ حفظ حالة HD
      };

      // ⭐️ إضافة episodes إذا كانت موجودة
      if (episodes != null && episodes!.isNotEmpty) {
        try {
          json['episodes'] = episodes!.map((e) => e.toJson()).toList();
        } catch (e) {
          print("Error encoding episodes to JSON: $e");
          json['episodes'] = [];
        }
      }

      return json;
    } catch (e) {
      print("Error converting Movie to JSON: $e");
      return {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'isLocalImage': isLocalImage,
        'quality': quality,
        'isHD': isHD,
      };
    }
  }

  // ⭐️ دالة لنسخ الكائن مع تعديل بعض الخصائص
  Movie copyWith({
    int? id,
    String? title,
    String? name,
    String? year,
    String? description,
    String? category,
    String? duration,
    String? type,
    String? imageAsset,
    String? imageUrl,
    String? videoUrl,
    String? overview,
    String? posterPath,
    String? backdropPath,
    String? releaseDate,
    double? voteAverage,
    double? rating,
    bool? isFavorite,
    List<Episode>? episodes,
    bool? isLocalImage,
    String? quality,
    bool? isHD,
  }) {
    return Movie(
      id: id ?? this.id,
      title: title ?? this.title,
      name: name ?? this.name,
      year: year ?? this.year,
      description: description ?? this.description,
      category: category ?? this.category,
      duration: duration ?? this.duration,
      type: type ?? this.type,
      imageAsset: imageAsset ?? this.imageAsset,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      overview: overview ?? this.overview,
      posterPath: posterPath ?? this.posterPath,
      backdropPath: backdropPath ?? this.backdropPath,
      releaseDate: releaseDate ?? this.releaseDate,
      voteAverage: voteAverage ?? this.voteAverage,
      rating: rating ?? this.rating,
      isFavorite: isFavorite ?? this.isFavorite,
      episodes: episodes ?? this.episodes,
      isLocalImage: isLocalImage ?? this.isLocalImage,
      quality: quality ?? this.quality,
      isHD: isHD ?? this.isHD,
    );
  }

  // ⭐️ دالة للمقارنة بين كائنين Movie
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Movie && 
           other.id == id && 
           other.title == title &&
           other.type == type &&
           other.quality == quality;
  }

  @override
  int get hashCode => id.hashCode ^ title.hashCode ^ type.hashCode ^ quality.hashCode;

  // ⭐️ دالة لتحويل الكائن إلى String للمساعدة في debugging
  @override
  String toString() {
    return 'Movie(id: $id, title: "$title", type: "$type", category: "$category", quality: "$quality", isHD: $isHD)';
  }
}