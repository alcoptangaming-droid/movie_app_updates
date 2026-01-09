// lib/series_detail_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:qasioun_tv/model/episode.dart';
import 'package:qasioun_tv/model/movie_model.dart';
import 'package:qasioun_tv/video_player/video_player_screen.dart';
import 'package:qasioun_tv/Screen/HomePage.dart';
import 'package:qasioun_tv/live/live_page.dart';
import 'package:qasioun_tv/widgets/app_bottom_nav.dart';
import 'package:qasioun_tv/services/user_service.dart';
import 'package:qasioun_tv/Screen/account_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SeriesDetailPage extends StatefulWidget {
  final Movie series;
  // دالة Callback لتحديث قائمة المشاهدة في HomePage
  final Function(Movie, Duration) onEpisodeWatched;

  const SeriesDetailPage({
    super.key,
    required this.series,
    required this.onEpisodeWatched,
  });

  @override
  _SeriesDetailPageState createState() => _SeriesDetailPageState();
}

class _SeriesDetailPageState extends State<SeriesDetailPage> {
  final Color _backgroundColor = const Color(0xFF040C1A);
  final Color _accentColor = const Color(0xFFFDD835);
  final Color _appBarColor = const Color(0xFF081830);
  bool _isAdmin = false;

  Map<int, Duration> _episodeProgress = {};
  int? _lastWatchedEpisodeMovieId;
  Episode? _lastWatchedEpisode;
  bool _progressLoaded = false;
  List<Episode> _currentEpisodes = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeEpisodes();
        _loadEpisodeProgress();
      }
    });
    _initUserState();
  }

  Future<void> _initUserState() async {
    final v = await UserService.isAdmin();
    if (mounted) setState(() => _isAdmin = v);
  }

  // دالة منفصلة لتعيين الحلقات وفرزها
  void _initializeEpisodes() {
    _currentEpisodes =
        List<Episode>.from(widget.series.episodes?.cast<Episode>() ?? []);
    // فرز الحلقات حسب رقم الحلقة لضمان الترتيب الصحيح
    _currentEpisodes
        .sort((a, b) => (a.episodeNumber ?? 0).compareTo(b.episodeNumber ?? 0));
    if (mounted) setState(() {});
  }

  // --- دوال إدارة التقدم ---

  Future<void> _loadEpisodeProgress() async {
    if (!mounted) return;
    if (_currentEpisodes.isEmpty) {
      if (mounted) {
        setState(() {
          _progressLoaded = true;
        });
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final Map<int, Duration> loadedProgress = {};
    int? lastWatchedIdFromPrefs;

    if (widget.series.id != null) {
      lastWatchedIdFromPrefs =
          prefs.getInt('last_watched_episode_${widget.series.id}');
    } else {
      print(
          "Warning: Series ID is null for '${widget.series.title}'. Cannot load last watched episode ID.");
    }

    Episode? tempLastEpisode;
    bool foundLastWatched = false;

    // المرور على الحلقات لتحميل تقدم كل واحدة وتحديد آخر حلقة تمت مشاهدتها
    for (var episode in _currentEpisodes) {
      if (episode.episodeNumber == null) {
        continue;
      }

      final episodeMovieIdResult = _getEpisodeMovieId(episode);
      if (episodeMovieIdResult == null) {
        continue;
      }
      final episodeMovieId = episodeMovieIdResult;

      final int? savedPositionMillis =
          prefs.getInt('playback_position_$episodeMovieId');
      final int? totalDurationMillis =
          prefs.getInt('playback_duration_$episodeMovieId');

      if (savedPositionMillis != null &&
          totalDurationMillis != null &&
          totalDurationMillis > 0) {
        final progressPercent = savedPositionMillis / totalDurationMillis;

        // ⭐️ فحص اكتمال المشاهدة (أكثر من 95%)
        if (progressPercent > 0.95) {
          // إذا كانت مكتملة، نحذفها ونستمر
          await prefs.remove('playback_position_$episodeMovieId');
          await prefs.remove('playback_duration_$episodeMovieId');
          continue;
        }

        loadedProgress[episodeMovieId] =
            Duration(milliseconds: savedPositionMillis);
      }

      // تحديد آخر حلقة تمت مشاهدتها بناءً على ID المحفوظ
      if (lastWatchedIdFromPrefs != null &&
          episodeMovieId == lastWatchedIdFromPrefs) {
        tempLastEpisode = episode;
        foundLastWatched = true;
      }
    }

    // إذا لم نجد الحلقة المحفوظة (ربما تم حذفها لأنها اكتملت)، نختار الحلقة الأولى
    if (!foundLastWatched && _currentEpisodes.isNotEmpty) {
      // نبحث عن أول حلقة غير مكتملة، وإلا نعود للأولى
      tempLastEpisode = _currentEpisodes.firstWhere(
          (e) => loadedProgress[_getEpisodeMovieId(e)] != null,
          orElse: () => _currentEpisodes.first);
    }

    if (!mounted) return;

    setState(() {
      _episodeProgress = loadedProgress;
      // لا نعتمد على lastWatchedIdFromPrefs إذا لم يتم العثور على الحلقة فعلياً
      _lastWatchedEpisode = tempLastEpisode;
      // نعتمد على ID آخر حلقة تم تعيينها في النهاية
      _lastWatchedEpisodeMovieId =
          _lastWatchedEpisode != null ? _getEpisodeMovieId(_lastWatchedEpisode!) : null;
      _progressLoaded = true;
    });
  }

  // حفظ ID آخر حلقة تمت مشاهدتها لهذا المسلسل
  Future<void> _saveLastWatchedEpisode(int episodeMovieId) async {
    if (widget.series.id == null) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        'last_watched_episode_${widget.series.id}', episodeMovieId);
  }

  // 🔁 دالة Callback لتحديث التقدم
  void _updateProgressForEpisode(Episode episode, Duration newPosition) {
    if (!mounted) return;
    final episodeMovieIdResult = _getEpisodeMovieId(episode);
    if (episodeMovieIdResult == null) {
      return;
    }
    final episodeMovieId = episodeMovieIdResult;

    // ⭐️ إنشاء كائن Movie للحلقة قبل تحديث التقدم
    final Movie tempMovie = _createMovieFromEpisode(episode);
    final totalDuration = parseDuration(tempMovie.duration ?? '0m');
    final progressPercent = totalDuration.inMilliseconds > 0
        ? newPosition.inMilliseconds / totalDuration.inMilliseconds
        : 0.0;

    // ⭐️ إذا تمت المشاهدة بالكامل، نحذف التقدم
    if (progressPercent > 0.95) {
      _episodeProgress.remove(episodeMovieId);
      // لكي يتم حذفها من قائمة المشاهدة في الـ HomePage
      widget.onEpisodeWatched(tempMovie, Duration.zero);
      // نحتاج لإعادة تحميل التقدم لتحديث الواجهة وحذفها من SharedPreferences
      _loadEpisodeProgress();
      return;
    }

    // تحديث التقدم إذا كان هناك تقدم
    setState(() {
      _episodeProgress[episodeMovieId] = newPosition;
      _lastWatchedEpisodeMovieId = episodeMovieId;
      _lastWatchedEpisode = episode;
    });

    // حفظ آخر حلقة تم مشاهدتها للمسلسل
    _saveLastWatchedEpisode(episodeMovieId);

    // ❗️ تحديث قائمة المشاهدة في HomePage (بما أن هذا مسلسل/حلقة)
    if (tempMovie.id != null) {
      widget.onEpisodeWatched(tempMovie, newPosition); // ⭐️ تمرير التقدم الفعلي
    }
  }

  void _onBottomNavTapped(int index) async {
    if (index == 0) {
      // الرجوع إلى الصفحة الرئيسية وتحديثها
      Navigator.popUntil(context, (route) => route.isFirst);
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
    } else if (index == 2) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LivePage()));
    } else if (index == 3) {
      // contact
      await AppBottomNav.openWhatsApp();
    } else if (index == 4) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const AccountPage()));
    }
  }

  // دالة لحساب معرف فريد للحلقة
  int? _getEpisodeMovieId(Episode episode) {
    final seriesId = widget.series.id;
    final episodeNumber = episode.episodeNumber;

    if (seriesId == null || seriesId == 0) {
      // ⭐️ إذا كان ID المسلسل غير صالح، يجب أن يكون ID الحلقة هو رقم عشوائي كبير لعدم التضارب
      if (episodeNumber != null) {
        return 9999000 + episodeNumber;
      }
      return null;
    }
    if (episodeNumber == null) {
      return null;
    }
    // صيغة فريدة للحلقة: (Series ID * 1000) + Episode Number
    return seriesId * 1000 + episodeNumber;
  }

  // دالة لتحويل كائن الحلقة إلى كائن Movie مؤقت للتشغيل أو للـ Callback
  Movie _createMovieFromEpisode(Episode episode) {
    final int? episodeMovieId = _getEpisodeMovieId(episode);

    String defaultTitle = 'Episode ${episode.episodeNumber ?? '?'}';
    if (episode.title != null) {
      if (episode.title!.contains('.')) {
        defaultTitle = episode.title!.split('.').first.trim();
      } else {
        defaultTitle = episode.title!;
      }
    }

    // ⭐️ تحديد أفضل صورة
    final String bestImage = _getBestImageForEpisode(episode);
    final bool isAsset = _isAssetImage(bestImage);

    return Movie(
      id: episodeMovieId ?? 0,
      title: "${widget.series.title} - $defaultTitle",
      name: "${widget.series.title} - $defaultTitle",
      year: widget.series.year,
      description: episode.overview ?? widget.series.description,
      category: widget.series.category,
      duration: episode.duration ?? widget.series.duration,
      type: 'episode', // ⭐️ تحديد النوع كـ 'episode' هنا مهم لحفظ التقدم
      imageAsset: isAsset ? bestImage : '',
      imageUrl: !isAsset ? bestImage : '',
      videoUrl: episode.videoUrl ?? '',
      overview: widget.series.overview,
      posterPath: widget.series.posterPath,
      backdropPath: widget.series.backdropPath,
      releaseDate: widget.series.releaseDate,
      voteAverage: widget.series.voteAverage,
      rating: widget.series.rating,
      episodes: null,
    );
  }

  // ⭐️ دالة محسنة لتحديد أفضل صورة للحلقة
  String _getBestImageForEpisode(Episode episode) {
    if (episode.imageUrl != null && episode.imageUrl!.isNotEmpty) {
      return episode.imageUrl!;
    }
    // إذا لم يكن هناك imageUrl، استخدام صورة المسلسل
    return _getBestImageForSeries();
  }

  // ⭐️ دالة محسنة للحصول على أفضل صورة للمسلسل
  String _getBestImageForSeries() {
    if (widget.series.backdropPath != null &&
        widget.series.backdropPath!.isNotEmpty) {
      return widget.series.backdropPath!;
    }
    if (widget.series.posterPath != null &&
        widget.series.posterPath!.isNotEmpty) {
      return widget.series.posterPath!;
    }
    if (widget.series.imageUrl.isNotEmpty) {
      return widget.series.imageUrl;
    }
    if (widget.series.imageAsset.isNotEmpty) {
      return widget.series.imageAsset;
    }
    if (widget.series.displayImage.isNotEmpty) {
      return widget.series.displayImage;
    }
    return 'assets/placeholder_image.jpg';
  }

  // ⭐️ دالة محسنة للتحقق مما إذا كانت الصورة من نوع Asset
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

  // --- دالة تشغيل الحلقة عند الضغط ---
  void _onEpisodeTapped(Episode episode) async {
    if (episode.episodeNumber == null ||
        episode.videoUrl == null ||
        episode.videoUrl!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('بيانات الحلقة غير متوفرة للتشغيل.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final episodeMovieIdResult = _getEpisodeMovieId(episode);
    if (episodeMovieIdResult == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يمكن تشغيل الحلقة بسبب عدم وجود معرف للمسلسل.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    final episodeMovieId = episodeMovieIdResult;

    final Duration startAt = _episodeProgress[episodeMovieId] ?? Duration.zero;

    // 🚀 إنشاء كائن Movie مؤقت للحلقة
    final Movie episodeMovie = _createMovieFromEpisode(episode);

    // 🚀 الانتقال إلى VideoPlayerFullScreen
    if (!mounted) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerFullScreen(
          videoUrl: episodeMovie.videoUrl!,
          title: episodeMovie.title,
          movie: episodeMovie, // ⭐️ تمرير كائن الحلقة (Movie type = 'episode')
          startAt: startAt,
          currentEpisode: episode,
          seriesEpisodes: _currentEpisodes,
          onNextEpisode: (nextEp) {
            print("Request to play next episode: ${nextEp.title}");
            if (mounted) Navigator.pop(context);
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _onEpisodeTapped(nextEp);
            });
          },
        ),
      ),
    );

    // تحديث التقدم بعد العودة من المشغل
    if (result is Duration && mounted) {
      // 🔁 استخدام دالة تحديث التقدم الموجودة
      _updateProgressForEpisode(episode, result);
    } else if (result is Map<String, dynamic> && mounted) {
      final Duration? finalPosition = result['position'] as Duration?;
      if (finalPosition != null) {
        _updateProgressForEpisode(episode, finalPosition);
      }
    }
  }

  // --- دوال بناء الواجهة ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            _buildSeriesInfo(),
            _buildEpisodeList(),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        backgroundColor: _appBarColor,
        selectedItemColor: _accentColor,
        unselectedItemColor: Colors.white,
        onTap: _onBottomNavTapped,
        isAdmin: _isAdmin,
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final String backdropImage = _getBestImageForSeries();
    final bool isAsset = _isAssetImage(backdropImage);

    return SliverAppBar(
      expandedHeight: 250.0,
      pinned: true,
      backgroundColor: _backgroundColor,
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.zero,
        centerTitle: false,
        title: Padding(
          padding: const EdgeInsets.only(left: 60.0, bottom: 12.0),
          child: Text(
            widget.series.title,
            style: const TextStyle(
                fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            _buildImageWidget(
              imageUrl: backdropImage,
              isAsset: isAsset,
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    _backgroundColor,
                    Colors.transparent,
                    Colors.transparent
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _backgroundColor.withOpacity(0.4),
                    Colors.transparent
                  ],
                  stops: const [0.0, 0.3],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeriesInfo() {
    Episode? episodeToPlay = _lastWatchedEpisode ??
        (_currentEpisodes.isNotEmpty ? _currentEpisodes.first : null);
    String buttonText = "Loading...";
    final bool hasEpisodes = _currentEpisodes.isNotEmpty;
    final bool canPlay = _progressLoaded &&
        hasEpisodes &&
        episodeToPlay != null &&
        episodeToPlay.videoUrl != null &&
        episodeToPlay.videoUrl!.isNotEmpty;

    // ⭐️ تحديد حالة التقدم لأول أو آخر حلقة
    double progressPercent = 0.0;
    if (_progressLoaded && episodeToPlay != null) {
      final episodeMovieIdResult = _getEpisodeMovieId(episodeToPlay);
      if (episodeMovieIdResult != null) {
        final progressDuration =
            _episodeProgress[episodeMovieIdResult] ?? Duration.zero;
        final totalDuration = parseDuration(
            episodeToPlay.duration ?? widget.series.duration ?? '0m');
        progressPercent = totalDuration.inMilliseconds > 0
            ? progressDuration.inMilliseconds / totalDuration.inMilliseconds
            : 0.0;
        // التأكد من عدم تجاوز الـ 95%
        progressPercent = progressPercent.clamp(0.0, 0.95);
      }
    }

    if (!_progressLoaded) {
      buttonText = "Loading...";
    } else {
      if (episodeToPlay != null) {
        final season = episodeToPlay.seasonNumber ?? 1;
        final episodeNum = episodeToPlay.episodeNumber ?? '?';

        if (progressPercent > 0.0) {
          buttonText = "متابعة S$season E$episodeNum";
        } else if (canPlay) {
          buttonText = "تشغيل S$season E$episodeNum";
        } else {
          buttonText = "لا توجد حلقات قابلة للتشغيل";
        }
      } else if (!hasEpisodes) {
        buttonText = "لا توجد حلقات متاحة";
      } else {
        buttonText = "لا توجد حلقات قابلة للتشغيل";
      }
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.series.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "${widget.series.year ?? 'N/A'} | ${widget.series.duration ?? 'N/A'} | ${widget.series.category ?? 'N/A'} | ⭐ ${widget.series.rating?.toStringAsFixed(1) ?? 'N/A'}",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),

            // ⭐️ زر التشغيل الرئيسي
            ElevatedButton.icon(
              onPressed:
                  canPlay ? () => _onEpisodeTapped(episodeToPlay!) : null,
              icon: const Icon(Icons.play_arrow, color: Colors.black),
              label: Text(buttonText,
                  style: const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                disabledBackgroundColor: Colors.grey[800],
              ),
            ),
            // ⭐️ شريط التقدم أسفل زر التشغيل الرئيسي (لآخر حلقة أو أول حلقة غير مكتملة)
            if (progressPercent > 0.0)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: LinearProgressIndicator(
                  value: progressPercent,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
                  minHeight: 6,
                ),
              ),

            const SizedBox(height: 16),
            Text(
              widget.series.description ?? 'No description available.',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.4,
              ),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const SizedBox(height: 8),
            const Text(
              "الحلقات",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEpisodeList() {
    if (!_progressLoaded) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(color: Color(0xFFFDD835)),
          ),
        ),
      );
    }

    if (_currentEpisodes.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 32.0),
            child: Text("لا توجد حلقات متاحة لهذا المسلسل.",
                style: TextStyle(color: Colors.white70)),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 20.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final episode = _currentEpisodes[index];
            if (episode.episodeNumber != null) {
              return _buildEpisodeListItem(context, episode);
            }
            return const SizedBox.shrink();
          },
          childCount: _currentEpisodes.length,
        ),
      ),
    );
  }

  Widget _buildEpisodeListItem(BuildContext context, Episode episode) {
    final episodeMovieIdResult = _getEpisodeMovieId(episode);
    final Duration progressDuration = (episodeMovieIdResult != null)
        ? (_episodeProgress[episodeMovieIdResult] ?? Duration.zero)
        : Duration.zero;

    final totalDuration =
        parseDuration(episode.duration ?? widget.series.duration ?? '');
    final progressPercent = (totalDuration.inMilliseconds > 0)
        ? (progressDuration.inMilliseconds / totalDuration.inMilliseconds)
        : 0.0;

    final String imageUrl = episode.imageUrl.isNotEmpty
        ? episode.imageUrl
        : _getBestImageForSeries();

    final bool isAsset = _isAssetImage(imageUrl);
    final bool isPlayable =
        episode.videoUrl != null && episode.videoUrl!.isNotEmpty;

    final bool isFullyWatched = progressPercent > 0.95; // ⭐️ تم تحديث النسبة
    final bool isPartiallyWatched =
        progressPercent > 0.0 && progressPercent <= 0.95; // ⭐️ تم تحديث النسبة

    return InkWell(
      onTap: isPlayable ? () => _onEpisodeTapped(episode) : null,
      child: Opacity(
        opacity: isPlayable ? 1.0 : 0.5,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            border: isFullyWatched
                ? Border.all(color: _accentColor, width: 2.0)
                : (isPartiallyWatched
                    ? Border.all(
                        color: _accentColor.withOpacity(0.6), width: 1.5)
                    : null),
            borderRadius: BorderRadius.circular(8.0),
            color: isFullyWatched
                ? _accentColor.withOpacity(0.1)
                : (isPartiallyWatched
                    ? _accentColor.withOpacity(0.05)
                    : Colors.transparent),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- صورة الحلقة ---
                Stack(
                  children: [
                    SizedBox(
                      width: 140,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 80,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4.0),
                              child: _buildImageWidget(
                                imageUrl: imageUrl,
                                isAsset: isAsset,
                                height: 80,
                                width: 140,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          // ⭐️ شريط التقدم على الحلقة نفسها
                          if (_progressLoaded &&
                              episodeMovieIdResult != null &&
                              isPartiallyWatched)
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              width: double.infinity,
                              child: LinearProgressIndicator(
                                value: progressPercent.clamp(0.0, 1.0),
                                backgroundColor: Colors.white.withOpacity(0.3),
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(_accentColor),
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            )
                          else
                            const SizedBox(height: 8),
                        ],
                      ),
                    ),

                    // مؤشر "تمت المشاهدة"
                    if (isFullyWatched)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: _accentColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.black,
                            size: 14,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 12),

                // --- تفاصيل الحلقة ---
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isFullyWatched
                                  ? _accentColor
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              isPlayable
                                  ? Icons.play_arrow_rounded
                                  : Icons.videocam_off_outlined,
                              color: isFullyWatched
                                  ? Colors.black
                                  : Colors.white.withOpacity(0.8),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'S${episode.seasonNumber ?? 1} E${episode.episodeNumber ?? '?'} - ${episode.title ?? ''}',
                              style: TextStyle(
                                color: isFullyWatched
                                    ? _accentColor
                                    : Colors.white,
                                fontSize: 15,
                                fontWeight: isFullyWatched
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 30.0),
                        child: Row(
                          children: [
                            if (isFullyWatched)
                              Row(
                                children: [
                                  Icon(Icons.check_circle,
                                      color: _accentColor, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    'تمت المشاهدة',
                                    style: TextStyle(
                                      color: _accentColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              )
                            else if (isPartiallyWatched)
                              Row(
                                children: [
                                  Icon(Icons.play_circle_filled,
                                      color: _accentColor, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    'جاري المشاهدة',
                                    style: TextStyle(
                                      color: _accentColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ),
                            Text(
                              episode.duration ?? 'N/A',
                              style: TextStyle(
                                color: isFullyWatched
                                    ? _accentColor.withOpacity(0.8)
                                    : Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (isPartiallyWatched) // ⭐️ إظهار نسبة التقدم فقط إذا كانت جزئية
                        Padding(
                          padding: const EdgeInsets.only(left: 30.0, top: 6),
                          child: Text(
                            '${(progressPercent * 100).toStringAsFixed(0)}% مكتمل',
                            style: TextStyle(
                              color: _accentColor,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ دالة محسنة لعرض الصور
  Widget _buildImageWidget({
    required String imageUrl,
    required bool isAsset,
    required double height,
    required double width,
    required BoxFit fit,
  }) {
    if (imageUrl.isEmpty ||
        imageUrl == 'null' ||
        imageUrl.contains('placeholder_image.jpg')) {
      return _buildPlaceholder(h: height, w: width);
    }

    // إذا كانت الصورة من الإنترنت (غير asset)
    if (!isAsset) {
      try {
        return CachedNetworkImage(
          imageUrl: imageUrl,
          fit: fit,
          placeholder: (context, url) =>
              _buildLoadingPlaceholder(h: height, w: width),
          errorWidget: (context, url, error) {
            // إذا فشل تحميل الصورة من الإنترنت، جرب كـ asset
            try {
              return Image.asset(
                imageUrl,
                fit: fit,
                errorBuilder: (context, error, stackTrace) =>
                    _buildPlaceholder(h: height, w: width),
              );
            } catch (e) {
              return _buildPlaceholder(h: height, w: width);
            }
          },
        );
      } catch (e) {
        // إذا فشل CachedNetworkImage، جرب كـ asset
        try {
          return Image.asset(
            imageUrl,
            fit: fit,
            errorBuilder: (context, error, stackTrace) =>
                _buildPlaceholder(h: height, w: width),
          );
        } catch (e) {
          return _buildPlaceholder(h: height, w: width);
        }
      }
    }

    // إذا كانت الصورة من نوع asset
    try {
      return Image.asset(
        imageUrl,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          // إذا فشل كـ asset، جرب كـ صورة من الإنترنت
          try {
            return CachedNetworkImage(
              imageUrl: imageUrl,
              fit: fit,
              placeholder: (context, url) =>
                  _buildLoadingPlaceholder(h: height, w: width),
              errorWidget: (context, url, error) =>
                  _buildPlaceholder(h: height, w: width),
            );
          } catch (e) {
            return _buildPlaceholder(h: height, w: width);
          }
        },
      );
    } catch (e) {
      return _buildPlaceholder(h: height, w: width);
    }
  }

  // --- دوال مساعدة ---

  // تحليل مدة الحلقة من نص
  Duration parseDuration(String durationString) {
    int hours = 0;
    int minutes = 0;
    int seconds = 0;

    if (durationString.isEmpty ||
        durationString == 'N/A' ||
        durationString == '...') {
      return Duration.zero;
    }

    try {
      final hourMatch = RegExp(r'(\d+)\s*h').firstMatch(durationString);
      if (hourMatch != null) hours = int.parse(hourMatch.group(1)!);

      final minuteMatch =
          RegExp(r'(\d+)\s*(?:m|min|دقيقة)').firstMatch(durationString);
      if (minuteMatch != null) minutes = int.parse(minuteMatch.group(1)!);

      if (durationString.contains(':')) {
        List<String> timeParts = durationString.split(':');
        if (timeParts.length == 3) {
          hours = int.tryParse(timeParts[0]) ?? hours;
          minutes = int.tryParse(timeParts[1]) ?? minutes;
          seconds = int.tryParse(timeParts[2]) ?? seconds;
        } else if (timeParts.length == 2) {
          minutes = int.tryParse(timeParts[0]) ?? minutes;
          seconds = int.tryParse(timeParts[1]) ?? seconds;
        }
      } else if (minutes == 0 &&
          !durationString.contains(':') &&
          !durationString.contains('h')) {
        minutes =
            int.tryParse(durationString.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      }
    } catch (e) {
      print("Error parsing duration '$durationString': $e");
      return Duration.zero;
    }

    return Duration(
        hours: hours.abs(), minutes: minutes.abs(), seconds: seconds.abs());
  }

  // واجهة مؤقتة للتحميل
  Widget _buildLoadingPlaceholder({double? h, double? w}) {
    return Container(
      height: h,
      width: w,
      color: _appBarColor,
      child: Center(
        child: CircularProgressIndicator(
          color: _accentColor.withOpacity(0.5),
          strokeWidth: 2,
        ),
      ),
    );
  }

  // واجهة بديلة عند فشل تحميل الصورة
  Widget _buildPlaceholder({double? h, double? w}) {
    return Container(
      height: h,
      width: w,
      color: _appBarColor,
      child: Center(
        child: Icon(Icons.tv_off_outlined,
            color: Colors.white38, size: (h ?? 70) * 0.4),
      ),
    );
  }
} // نهاية _SeriesDetailPageState