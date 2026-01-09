import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:qasioun_tv/model/movie_model.dart';
import 'package:qasioun_tv/video_player/video_player_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MovieDetailPage extends StatefulWidget {
  final Movie movie;
  const MovieDetailPage({super.key, required this.movie});

  @override
  _MovieDetailPageState createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  double _progressPercent = 0.0;
  int _savedPosition = 0;
  int _totalDuration = 0;

  final Color _accentColor = const Color(0xFFFDD835);
  final Color _backgroundColor = const Color(0xFF040C1A);

  @override
  void initState() {
    super.initState();
    _loadSavedProgress();
  }

  Future<void> _loadSavedProgress() async {
    if (widget.movie.id == null) return;
    final prefs = await SharedPreferences.getInstance();
    
    // ⭐️ قراءة مدة التشغيل الكلية المحفوظة (إذا تم حفظها من قبل)
    final total = prefs.getInt('playback_duration_${widget.movie.id}') ?? 0;
    
    // ⭐️ قراءة نقطة التوقف المحفوظة
    final pos = prefs.getInt('playback_position_${widget.movie.id}') ?? 0;
    
    // ⭐️ التحقق من نسبة المشاهدة لمنع ظهور شريط التقدم إذا تمت المشاهدة بالكامل
    double calculatedProgressPercent = (total > 0) ? (pos / total) : 0.0;
    
    if (calculatedProgressPercent > 0.95) {
        // إذا كان مكتملًا، لا نعرض شريط التقدم
        calculatedProgressPercent = 0.0;
        await prefs.remove('playback_position_${widget.movie.id}');
    }

    setState(() {
      _savedPosition = pos;
      _totalDuration = total;
      _progressPercent = calculatedProgressPercent;
    });
  }

  Future<void> _playMovie(BuildContext context) async {
    final startAt = Duration(milliseconds: _savedPosition);
    final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerFullScreen(
            movie: widget.movie,
            videoUrl: widget.movie.videoUrl ?? '',
            title: widget.movie.title,
            startAt: startAt,
            // ⭐️ يتم تمرير الفيلم هنا كنوع "movie" ولن يتم حفظ تقدمه في المشغل
          ),
        ));

    // ⭐️ عند العودة، نعيد تحميل التقدم لتحديث الواجهة في حالة تمت المشاهدة بالكامل
    if (result is Duration) {
      await _loadSavedProgress();
    }
  }

  // ⭐️ دالة للتحقق مما إذا كانت الصورة من نوع Asset
  bool _isAssetImage(String imageUrl) {
    if (imageUrl.isEmpty) return false;

    // قائمة واضحة لروابط الإنترنت
    final internetIndicators = [
      'http://',
      'https://',
      'ftp://',
      'www.',
      '.com/',
      '.net/',
      '.org/',
      '.io/',
      '.tv/',
      '.me/',
      '.info/',
      '.biz/',
      '.edu/',
      '.gov/'
    ];

    // إذا كان الرابط يحتوي على أي من مؤشرات الإنترنت
    for (var indicator in internetIndicators) {
      if (imageUrl.contains(indicator)) {
        return false;
      }
    }

    // إذا كان يحتوي على امتداد صورة مع معاملات (علامات استفهام)
    if (imageUrl.contains('?')) {
      final beforeQuery = imageUrl.split('?')[0];
      if (beforeQuery.toLowerCase().endsWith('.jpg') ||
          beforeQuery.toLowerCase().endsWith('.jpeg') ||
          beforeQuery.toLowerCase().endsWith('.png') ||
          beforeQuery.toLowerCase().endsWith('.gif') ||
          beforeQuery.toLowerCase().endsWith('.webp')) {
        return false;
      }
    }

    // روابط Asset واضحة
    if (imageUrl.startsWith('assets/') ||
        imageUrl.startsWith('asset/') ||
        imageUrl.startsWith('lib/assets/') ||
        (imageUrl.startsWith('images/') && !imageUrl.contains('://'))) {
      return true;
    }

    // في حالة عدم اليقين، افترض أنها من الإنترنت
    // (هذا أفضل لأن معظم الصور في التطبيقات تكون من الإنترنت)
    return false;
  }

  // ⭐️ دالة للحصول على أفضل صورة للفيلم
  String _getBestImageForMovie(Movie movie) {
    if (movie.displayImage.isNotEmpty && movie.displayImage != 'null') {
      return movie.displayImage;
    }
    if (movie.imageUrl.isNotEmpty && movie.imageUrl != 'null') {
      return movie.imageUrl;
    }
    if (movie.imageAsset.isNotEmpty && movie.imageAsset != 'null') {
      return movie.imageAsset;
    }
    if (movie.posterPath != null && movie.posterPath!.isNotEmpty) {
      return movie.posterPath!;
    }
    if (movie.backdropPath != null && movie.backdropPath!.isNotEmpty) {
      return movie.backdropPath!;
    }
    return 'assets/placeholder_image.jpg';
  }

  // ⭐️ دالة محسنة لعرض الصور
  Widget _buildImageWidget({
    required String imageUrl,
    required BoxFit fit,
  }) {
    // الحصول على أفضل صورة
    final String bestImage = _getBestImageForMovie(widget.movie);
    final bool isAsset = _isAssetImage(bestImage);

    if (bestImage.isEmpty ||
        bestImage == 'null' ||
        bestImage.contains('placeholder_image.jpg')) {
      return _buildPlaceholder();
    }

    // إذا كانت الصورة من الإنترنت (غير asset)
    if (!isAsset) {
      try {
        return CachedNetworkImage(
          imageUrl: bestImage,
          fit: fit,
          placeholder: (context, url) => _buildLoadingPlaceholder(),
          errorWidget: (context, url, error) {
            // إذا فشل تحميل الصورة من الإنترنت، جرب كـ asset
            try {
              return Image.asset(
                bestImage,
                fit: fit,
                errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
              );
            } catch (e) {
              return _buildPlaceholder();
            }
          },
        );
      } catch (e) {
        // إذا فشل CachedNetworkImage، جرب كـ asset
        try {
          return Image.asset(
            bestImage,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
          );
        } catch (e) {
          return _buildPlaceholder();
        }
      }
    }

    // إذا كانت الصورة من نوع asset
    try {
      return Image.asset(
        bestImage,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          // إذا فشل كـ asset، جرب كـ صورة من الإنترنت
          try {
            return CachedNetworkImage(
              imageUrl: bestImage,
              fit: fit,
              placeholder: (context, url) => _buildLoadingPlaceholder(),
              errorWidget: (context, url, error) => _buildPlaceholder(),
            );
          } catch (e) {
            return _buildPlaceholder();
          }
        },
      );
    } catch (e) {
      return _buildPlaceholder();
    }
  }
  
  // ⭐️ دوال مساعدة للـ Placeholder
  Widget _buildLoadingPlaceholder() {
    return Container(
      color: Colors.black.withOpacity(0.2),
      child: Center(
        child: CircularProgressIndicator(
          color: _accentColor.withOpacity(0.5),
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.black.withOpacity(0.2),
      child: const Center(
          child: Icon(Icons.broken_image_outlined,
              color: Colors.white24, size: 40)),
    );
  }


  @override
  Widget build(BuildContext context) {
    // ⭐️ تحديد النص بناءً على حالة المشاهدة
    final String playButtonText = (_progressPercent > 0) ? 'متابعة المشاهدة' : 'تشغيل';
    
    // ⭐️ التحقق مما إذا كان الفيلم مكتمل المشاهدة (بناءً على _loadSavedProgress)
    final bool isFullyWatched = _progressPercent == 0.0 && _savedPosition > 0;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Large image with play overlay
            SizedBox(
              height: 260,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // ⭐️ استخدام دالة عرض الصورة المعدلة
                  _buildImageWidget(fit: BoxFit.cover, imageUrl: ''),
                  
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                        stops: const [0.0, 0.6],
                      ),
                    ),
                  ),
                  Center(
                    child: GestureDetector(
                      onTap: () => _playMovie(context),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow, color: Colors.white, size: 48),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 12,
                    child: Text(
                      widget.movie.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // ⭐️ زر الرجوع
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 8,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'رجوع',
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    // ⭐️ يمكن إضافة تقييم إذا كان متاحاً
                    '${widget.movie.year ?? 'N/A'} | ${widget.movie.duration ?? 'N/A'} | ${widget.movie.category} ${widget.movie.rating != null && widget.movie.rating! > 0 ? '| ⭐ ${widget.movie.rating!.toStringAsFixed(1)}' : ''}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  
                  // ⭐️ شريط التقدم الأصفر
                  if (_progressPercent > 0.0) ...[
                    LinearProgressIndicator(
                      value: _progressPercent.clamp(0.0, 1.0),
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
                      minHeight: 6,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'شاهدت ${(_progressPercent * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // ⭐️ مؤشر تمت المشاهدة (إذا كان مكتملًا)
                  if (isFullyWatched) ...[
                      Row(
                        children: [
                            Icon(Icons.check_circle, color: _accentColor, size: 20),
                            const SizedBox(width: 8),
                            Text(
                                'تمت المشاهدة بالكامل',
                                style: TextStyle(color: _accentColor, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                  ],
                  
                  ElevatedButton.icon(
                    onPressed: () => _playMovie(context),
                    icon: const Icon(Icons.play_arrow, color: Colors.black),
                    label: Text(
                      playButtonText, // ⭐️ استخدام النص المحدث
                      style: const TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(widget.movie.description,
                      style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}