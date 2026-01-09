import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:qasioun_tv/Series/SeriesTurkishPage.dart';
import 'package:qasioun_tv/Series/foreing_page.dart';

import 'package:qasioun_tv/movies%20arapic/disney_page.dart';
import 'package:qasioun_tv/movies%20arapic/foreing_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qasioun_tv/Screen/search_page.dart';
import 'package:qasioun_tv/Series/series_arabic.dart';
import 'package:qasioun_tv/Series/series_detail_page.dart';
import 'package:qasioun_tv/api/ApiService.dart';
import 'package:qasioun_tv/widgets/app_bottom_nav.dart';
import 'package:qasioun_tv/widgets/bottom_nav_controller.dart';
import 'package:qasioun_tv/model/movie_model.dart';
import 'package:qasioun_tv/movies arapic/movies_arabic_page.dart';
import 'package:qasioun_tv/services/user_service.dart';
import 'package:qasioun_tv/Screen/login_page.dart';
import '../video_player/video_player_screen.dart';
import 'package:qasioun_tv/movies arapic/movie_detail_page.dart';
import '../live/live_page.dart';
import 'package:qasioun_tv/Screen/account_page.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _isAdmin = false;
  final Color _backgroundColor = const Color(0xFF040C1A);
  final Color _appBarColor = const Color(0xFF081830);
  final Color _accentColor = const Color(0xFFFDD835);
  final Color _unselectedColor = Colors.white;

  // ⭐️ قائمة الإعلانات من API
  List<Map<String, dynamic>> _banners = [];
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;
  final PageController _pageController = PageController();

  // ✅ تعريف المتغيرات لجلب البيانات
  late Future<List<Movie>> _liveChannelsFuture;
  late Future<List<Movie>> _arabicMoviesFuture;
  late Future<List<Movie>> _arabicSeriesFuture;
  late Future<List<Movie>> _foreignMoviesFuture;
  late Future<List<Movie>> _foreignSeriesFuture;
  late Future<List<Movie>> _disneyMoviesFuture;
  late Future<List<Movie>> _turkishSeriesFuture; // ✅ قسم المسلسلات التركية الجديد

  List<Movie> _continueWatchingList = [];
  final Map<int, Duration> _watchProgress = {};
  bool _isContinueWatchingLoaded = false;
  final StreamController<bool> _continueWatchingStreamController =
      StreamController<bool>.broadcast();

  @override
  void initState() {
    super.initState();
    BottomNavController.index.value = 0;

    // ✅ تحميل الإعلانات من GitHub API
    _loadBannersFromAPI();
    
    // ✅ تحميل البيانات من الـ API
    _liveChannelsFuture = _fetchLiveChannelsFromAPI();
    
    // ✅ طباعة البيانات للتحقق
    _liveChannelsFuture.then((channels) {
      print('📊 عدد القنوات المحملة: ${channels.length}');
      for (var channel in channels) {
        print('📺 القناة: ${channel.title} - ${channel.quality} - ${channel.videoUrl}');
      }
    }).catchError((error) {
      print('❌ خطأ في تحميل القنوات: $error');
    });
    
    _arabicMoviesFuture = ApiService.getMovies();
    _arabicSeriesFuture = ApiService.getArabicSeries();
    _foreignMoviesFuture = ApiService.getForeignMovies();
    _foreignSeriesFuture = ApiService.getForeignSeries();
    _disneyMoviesFuture = ApiService.getDisneyMovies();
    _turkishSeriesFuture = ApiService.getTurkishSeries(); // ✅ تحميل المسلسلات التركية

    _loadContinueWatchingData();

    _continueWatchingStreamController.stream.listen((_) {
      _loadContinueWatchingData();
    });
    _initUserState();
    _checkUserExpiration();
  }

  // ✅ دالة جديدة لجلب الإعلانات من GitHub API
  Future<void> _loadBannersFromAPI() async {
    try {
      const url = 'https://api.npoint.io/b768a9abb4b4affb9d52';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data is List) {
          List<Map<String, dynamic>> banners = [];
          for (var banner in data) {
            if (banner is Map<String, dynamic>) {
              banners.add(banner);
            }
          }
          
          if (mounted) {
            setState(() {
              _banners = banners;
            });
          }
          
          print('✅ تم تحميل ${banners.length} إعلان من API');
          
          // بدء التايمر للسلايدر إذا كان هناك أكثر من إعلان
          if (banners.length > 1) {
            _startBannerTimer();
          }
        } else {
          _loadDefaultBanners();
        }
      } else {
        _loadDefaultBanners();
      }
    } catch (e) {
      print('❌ خطأ في تحميل الإعلانات من API: $e');
      _loadDefaultBanners();
    }
  }

  // ✅ تحميل الإعلانات الافتراضية في حالة فشل API
  void _loadDefaultBanners() {
    if (mounted) {
      setState(() {
        _banners = [
          {
            "id": 1002,
            "title": "شركة سوا المتحدة للتصميم والبرمجة",
            "description": "نقدم خدمات التصميم والبرمجة والتطوير",
            "imageUrl":
                "https://images.unsplash.com/photo-1611224923853-80b023f02d71?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80",
            "link": "https://www.saway.store",
            "type": "static"
          },
          {
            "id": 1003,
            "title": "اشتراك إنترنت Qasioun Neet",
            "description": "استمتع بأقوى وأسرع شبكة إنترنت في سوريا",
            "imageUrl":
                "https://images.unsplash.com/photo-1519389950473-47ba0277781c?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80",
            "link": "https://www.qasioun1.net",
            "type": "static"
          }
        ];
      });
      
      if (_banners.length > 1) {
        _startBannerTimer();
      }
    }
  }

  // ✅ دالة جديدة لجلب القنوات المباشرة من API
  Future<List<Movie>> _fetchLiveChannelsFromAPI() async {
    try {
      const url = 'https://api.npoint.io/f575068a82f14f5bf05d';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // ✅ تحويل البيانات إلى List<Movie>
        List<Movie> channels = [];
        
        if (data is List) {
          for (var channelData in data) {
            try {
              // ✅ الحصول على جودة البث بأمان
              String quality = 'HD'; // القيمة الافتراضية
              if (channelData['quality'] != null && channelData['quality'] is String) {
                quality = channelData['quality'];
              } else if (channelData['resolution'] != null && channelData['resolution'] is String) {
                quality = channelData['resolution'];
              } else if (channelData['stream_quality'] != null && channelData['stream_quality'] is String) {
                quality = channelData['stream_quality'];
              }
              
              // ✅ تحديد إذا كانت الجودة HD
              bool isHD = false;
              String qualityLower = quality.toLowerCase();
              if (qualityLower.contains('hd') || 
                  qualityLower.contains('عالية') || 
                  qualityLower.contains('high') ||
                  qualityLower.contains('1080') ||
                  qualityLower.contains('720')) {
                isHD = true;
              }
              
              // ✅ إنشاء Movie من البيانات
              Movie channel = Movie(
                id: int.tryParse(channelData['id'].toString()) ?? 0,
                title: channelData['name']?.toString() ?? 
                       channelData['title']?.toString() ?? 
                       channelData['channel_name']?.toString() ?? 
                       'قناة مباشرة',
                imageUrl: channelData['image']?.toString() ?? 
                         channelData['thumbnail']?.toString() ?? 
                         channelData['logo']?.toString() ?? 
                         channelData['image_url']?.toString() ?? 
                         'https://images.unsplash.com/photo-1594909122845-11baa439b7bf?w=400&q=80',
                videoUrl: channelData['url']?.toString() ?? 
                         channelData['stream_url']?.toString() ?? 
                         channelData['video_url']?.toString() ?? 
                         channelData['stream']?.toString() ?? 
                         'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4',
                description: channelData['description']?.toString() ?? 'بث مباشر',
                duration: 'مباشر',
                type: 'live',
                category: 'live_channels',
                quality: quality,
                isHD: isHD,
              );
              
              channels.add(channel);
            } catch (e) {
              print('⚠️ خطأ في تحويل بيانات القناة: $e');
            }
          }
        }
        
        // ✅ إذا لم تكن هناك قنوات، نضيف قناة افتراضية للاختبار
        if (channels.isEmpty) {
          print('⚠️ لا توجد قنوات في الـ API، إضافة قناة افتراضية للاختبار');
          channels.add(Movie(
            id: 999,
            title: 'قناة تجريبية',
            imageUrl: 'https://images.unsplash.com/photo-1594909122845-11baa439b7bf?w=400&q=80',
            videoUrl: 'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4',
            description: 'قناة تجريبية لاختبار النظام',
            duration: 'مباشر',
            type: 'live',
            category: 'live_channels',
            quality: 'HD',
            isHD: true,
          ));
        }
        
        print('✅ تم تحميل ${channels.length} قناة');
        return channels;
      } else {
        print('❌ فشل في تحميل القنوات: ${response.statusCode}');
        // ✅ إرجاع قناة افتراضية في حالة فشل الاتصال
        return [
          Movie(
            id: 1000,
            title: 'قناة مباشرة',
            imageUrl: 'https://images.unsplash.com/photo-1594909122845-11baa439b7bf?w=400&q=80',
            videoUrl: 'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4',
            description: 'بث مباشر تجريبي',
            duration: 'مباشر',
            type: 'live',
            category: 'live_channels',
            quality: 'HD',
            isHD: true,
          )
        ];
      }
    } catch (e) {
      print('❌ خطأ في جلب القنوات المباشرة: $e');
      
      // ✅ إرجاع قناة افتراضية في حالة الخطأ
      return [
        Movie(
          id: 1001,
          title: 'قناة تجريبية',
          imageUrl: 'https://images.unsplash.com/photo-1594909122845-11baa439b7bf?w=400&q=80',
          videoUrl: 'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4',
          description: 'بث مباشر تجريبي',
          duration: 'مباشر',
          type: 'live',
          category: 'live_channels',
          quality: 'HD',
          isHD: true,
        )
      ];
    }
  }

  Future<void> _openBannerLink(String url) async {
    try {
      String finalUrl = url;
      LaunchMode launchMode = LaunchMode.platformDefault;

      if (url == 'whatsapp') {
        final msg = Uri.encodeComponent(
            'مرحباً فريق شركة سـوا الـمـتـحـدة\n\n'
            'أنا هنا لطلب تجديد اشتراكي في تطبيق qasioun.tv\n\n'
            'شـركـة ســوا الـمـتـحـدة لـلـتـصـمـيم والـبـرمـجـة www.saway.store');
        finalUrl = 'https://wa.me/963945245117?text=$msg';
        launchMode = LaunchMode.externalNonBrowserApplication;
      }

      final uri = Uri.parse(finalUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri,
            mode: launchMode,
            webViewConfiguration: const WebViewConfiguration(
                enableJavaScript: true, enableDomStorage: true));
      } else {
        if (mounted) _showUrlErrorSnackBar(finalUrl);
      }
    } catch (e) {
      if (mounted) _showUrlErrorSnackBar(url);
    }
  }

  void _showUrlErrorSnackBar(String url) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          url == 'whatsapp'
              ? 'تعذر فتح واتساب.'
              : 'تعذر فتح الرابط.',
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    if (_banners.length > 1) {
      _bannerTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
        if (mounted) {
          int nextIndex = (_currentBannerIndex + 1) % _banners.length;
          _pageController.animateToPage(
            nextIndex,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
          setState(() {
            _currentBannerIndex = nextIndex;
          });
        }
      });
    }
  }

  void _onPageChanged(int index) {
    if (mounted) {
      setState(() {
        _currentBannerIndex = index;
      });
    }
  }

  Future<void> _checkUserExpiration() async {
    final user = await UserService.getCurrentUser();
    if (user == null && mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginPage()));
    }
  }

  Future<void> _initUserState() async {
    final v = await UserService.isAdmin();
    if (mounted) setState(() => _isAdmin = v);
  }

  @override
  void dispose() {
    _continueWatchingStreamController.close();
    _bannerTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadContinueWatchingData() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedListJson =
        prefs.getStringList('continue_watching_list');
    _continueWatchingList = [];
    _watchProgress.clear();

    if (savedListJson != null) {
      for (var jsonString in savedListJson) {
        try {
          final movie = Movie.fromJson(json.decode(jsonString));
          if (movie.id != null) {
            final int? savedPositionMillis =
                prefs.getInt('playback_position_${movie.id}');
            final int? totalDurationMillis =
                prefs.getInt('playback_duration_${movie.id}');
            final double progressPercent =
                (totalDurationMillis != null && totalDurationMillis > 0)
                    ? (savedPositionMillis ?? 0) / totalDurationMillis
                    : 0.0;
            if (progressPercent > 0.95) continue;
            if (savedPositionMillis != null) {
              _watchProgress[movie.id!] =
                  Duration(milliseconds: savedPositionMillis);
              _continueWatchingList.add(movie);
            }
          }
        } catch (e) {
          print('⚠️ خطأ في تحميل بيانات الاستمرار بالمشاهدة: $e');
        }
      }
    }
    if (mounted) {
      setState(() {
        _isContinueWatchingLoaded = true;
      });
    }
    _saveContinueWatchingData();
  }

  Future<void> _saveContinueWatchingData() async {
    final prefs = await SharedPreferences.getInstance();
    if (_continueWatchingList.isNotEmpty) {
      final listToSave =
          _continueWatchingList.map((movie) => json.encode(movie.toJson())).toList();
      await prefs.setStringList('continue_watching_list', listToSave);
    } else {
      await prefs.remove('continue_watching_list');
    }
  }

  void _updateContinueWatching(Movie movie, Duration? lastPosition) {
    if (!mounted) return;
    final totalDuration = parseDuration(movie.duration ?? '0m');
    final progressPercent =
        (totalDuration.inMilliseconds > 0 && lastPosition != null)
            ? lastPosition.inMilliseconds / totalDuration.inMilliseconds
            : 0.0;

    if (progressPercent > 0.95) {
      if (movie.id != null) {
        _watchProgress.remove(movie.id!);
        SharedPreferences.getInstance().then((prefs) {
          prefs.remove('playback_position_${movie.id}');
          prefs.remove('playback_duration_${movie.id}');
        });
      }
      _continueWatchingList.removeWhere((m) => m.id == movie.id);
      _saveContinueWatchingData();
      _continueWatchingStreamController.add(true);
      return;
    }

    setState(() {
      _continueWatchingList.removeWhere((m) => m.id == movie.id);
      if (movie.id != null) {
        if (lastPosition != null && lastPosition > Duration.zero) {
          _watchProgress[movie.id!] = lastPosition;
          _continueWatchingList.insert(0, movie);
        } else if (lastPosition == Duration.zero) {
          _watchProgress.remove(movie.id!);
        }
      }
      if (_continueWatchingList.length > 10) {
        _continueWatchingList = _continueWatchingList.sublist(0, 10);
      }
    });
    _saveContinueWatchingData().then((_) {
      _continueWatchingStreamController.add(true);
    });
  }

  // ====================== UI Builder ======================
  @override
  Widget build(BuildContext context) {
    // إعدادات أحجام الكروت للأفلام والمسلسلات
    const double fixedCardWidth = 130.0;
    const double cardAspectRatio = 0.65;
    const double titleBarHeight = 35.0;
    const double totalCardHeight = fixedCardWidth / cardAspectRatio;
    const double imageHeight = totalCardHeight - titleBarHeight;

    const double cwCardWidth = 200.0;
    const double cwCardHeight = 90.0;

    const double seriesCardWidth = 130.0;
    const double seriesCardAspectRatio = 0.65;
    const double seriesTotalCardHeight =
        seriesCardWidth / seriesCardAspectRatio;
    const double seriesImageHeight = seriesTotalCardHeight - titleBarHeight;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Directionality(
        textDirection: TextDirection.ltr,
        child: SafeArea(
          top: true,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopLogo(),
                
                // 🎪 قسم الإعلانات (السلايدر الجديد)
                _buildBannerSlider(),

                // 🔴 قسم القنوات المباشرة
                _buildLiveChannelsSection(),

                // قسم الأفلام العربية
                _buildSectionTitle("أفلام عربية", onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MoviesArabicPage())).then(
                      (_) => _loadContinueWatchingData());
                }, showArrow: true),
                FutureBuilder<List<Movie>>(
                  future: _arabicMoviesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingIndicator(height: totalCardHeight);
                    }
                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data!.isEmpty) {
                      return _buildErrorIndicator(height: totalCardHeight);
                    }
                    final movies = snapshot.data!;
                    return _buildHorizontalList(
                      itemCount: movies.length,
                      height: totalCardHeight,
                      itemBuilder: (context, index) {
                        return _buildMoviePortraitCard(
                            movies[index],
                            fixedCardWidth,
                            imageHeight,
                            titleBarHeight,
                            type: 'arabic_movie');
                      },
                    );
                  },
                ),

                // ... قسم مشاهداتك
                if (_isContinueWatchingLoaded &&
                    _continueWatchingList.isNotEmpty) ...[
                  _buildSectionTitle("مشاهداتك", showArrow: false),
                  _buildHorizontalList(
                    itemCount: _continueWatchingList.length,
                    height: cwCardHeight + 20,
                    itemBuilder: (context, index) {
                      final movie = _continueWatchingList[index];
                      final progressDuration = (movie.id != null)
                          ? (_watchProgress[movie.id] ?? Duration.zero)
                          : Duration.zero;
                      final totalDuration =
                          parseDuration(movie.duration ?? '0m');
                      final progressPercent = totalDuration.inMilliseconds > 0
                          ? progressDuration.inMilliseconds /
                              totalDuration.inMilliseconds
                          : 0.0;
                      return _buildContinueWatchingCard(
                        movie,
                        progressPercent.clamp(0.0, 1.0),
                        progressDuration,
                        cwCardWidth,
                        cwCardHeight,
                      );
                    },
                  ),
                ],

                // قسم مسلسلات عربية
                _buildSectionTitle("مسلسلات عربية", onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SeriesArabicPage(
                                onEpisodeWatched: _updateContinueWatching,
                              ))).then((_) => _loadContinueWatchingData());
                }, showArrow: true),
                FutureBuilder<List<Movie>>(
                  future: _arabicSeriesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingIndicator(
                          height: seriesTotalCardHeight);
                    }
                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data!.isEmpty) {
                      return const SizedBox(height: seriesTotalCardHeight);
                    }
                    final seriesList = snapshot.data!;
                    return _buildHorizontalList(
                      itemCount: seriesList.length,
                      height: seriesTotalCardHeight,
                      itemBuilder: (context, index) {
                        return _buildSeriesPortraitCard(
                            seriesList[index],
                            seriesCardWidth,
                            seriesImageHeight,
                            titleBarHeight,
                            type: 'arabic_series');
                      },
                    );
                  },
                ),

                // ✅ قسم المسلسلات التركية (الجديد)
                _buildSectionTitle("مسلسلات تركية", onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SeriesTurkishPage(
                        onEpisodeWatched: _updateContinueWatching,
                      ),
                    ),
                  ).then((_) => _loadContinueWatchingData());
                }, showArrow: true),
                FutureBuilder<List<Movie>>(
                  future: _turkishSeriesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingIndicator(
                          height: seriesTotalCardHeight);
                    }
                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data!.isEmpty) {
                      return _buildErrorIndicator(
                        height: seriesTotalCardHeight,
                        message: "لا توجد مسلسلات تركية حالياً",
                      );
                    }
                    final turkishSeriesList = snapshot.data!;
                    return _buildHorizontalList(
                      itemCount: turkishSeriesList.length,
                      height: seriesTotalCardHeight,
                      itemBuilder: (context, index) {
                        return _buildSeriesPortraitCard(
                            turkishSeriesList[index],
                            seriesCardWidth,
                            seriesImageHeight,
                            titleBarHeight,
                            type: 'turkish_series');
                      },
                    );
                  },
                ),

                // قسم أفلام أجنبية
                _buildSectionTitle("أفلام أجنبية", onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MoviesForeignPage())).then(
                      (_) => _loadContinueWatchingData());
                }, showArrow: true),
                FutureBuilder<List<Movie>>(
                  future: _foreignMoviesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingIndicator(height: totalCardHeight);
                    }
                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data!.isEmpty) {
                      return _buildErrorIndicator(
                          height: totalCardHeight,
                          message: "لا توجد أفلام أجنبية حالياً");
                    }
                    final movies = snapshot.data!;
                    return _buildHorizontalList(
                      itemCount: movies.length,
                      height: totalCardHeight,
                      itemBuilder: (context, index) {
                        return _buildMoviePortraitCard(
                            movies[index],
                            fixedCardWidth,
                            imageHeight,
                            titleBarHeight,
                            type: 'foreign_movie');
                      },
                    );
                  },
                ),

                // قسم مسلسلات أجنبية
                _buildSectionTitle("مسلسلات أجنبية", onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SeriesForeignPage(
                                onEpisodeWatched: (Movie, Duration) {},
                              ))).then((_) => _loadContinueWatchingData());
                }, showArrow: true),
                FutureBuilder<List<Movie>>(
                  future: _foreignSeriesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingIndicator(
                          height: seriesTotalCardHeight);
                    }
                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data!.isEmpty) {
                      return _buildErrorIndicator(
                          height: seriesTotalCardHeight,
                          message: "لا توجد مسلسلات أجنبية حالياً");
                    }
                    final seriesList = snapshot.data!;
                    return _buildHorizontalList(
                      itemCount: seriesList.length,
                      height: seriesTotalCardHeight,
                      itemBuilder: (context, index) {
                        return _buildSeriesPortraitCard(
                            seriesList[index],
                            seriesCardWidth,
                            seriesImageHeight,
                            titleBarHeight,
                            type: 'foreign_series');
                      },
                    );
                  },
                ),

                // قسم ديزني
                _buildSectionTitle("أفلام أنمي وديزني", onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const DisneyPage())).then(
                      (_) => _loadContinueWatchingData());
                }, showArrow: true),
                FutureBuilder<List<Movie>>(
                  future: _disneyMoviesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingIndicator(height: totalCardHeight);
                    }
                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data!.isEmpty) {
                      return _buildErrorIndicator(
                          height: totalCardHeight,
                          message: "لا توجد أفلام أنمي حالياً");
                    }
                    final movies = snapshot.data!;
                    return _buildHorizontalList(
                      itemCount: movies.length,
                      height: totalCardHeight,
                      itemBuilder: (context, index) {
                        return _buildMoviePortraitCard(
                            movies[index],
                            fixedCardWidth,
                            imageHeight,
                            titleBarHeight,
                            type: 'disney');
                      },
                    );
                  },
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _selectedIndex,
        backgroundColor: _appBarColor,
        selectedItemColor: _accentColor,
        unselectedItemColor: _unselectedColor,
        onTap: _onItemTapped,
        isAdmin: _isAdmin,
      ),
    );
  }

  // ✅ 1. دالة بناء قسم الإعلانات (السلايدر)
  Widget _buildBannerSlider() {
    if (_banners.isEmpty) {
      return Container(
        height: 180,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: _appBarColor,
        ),
        child: Center(
          child: CircularProgressIndicator(color: _accentColor),
        ),
      );
    }

    return Container(
      height: 200,
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // السلايدر
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: _banners.length,
              itemBuilder: (context, index) {
                final banner = _banners[index];
                final bannerImage = banner['imageUrl'] as String? ?? '';
                final bannerTitle = banner['title'] as String? ?? 'إعلان';
                final bannerDescription = banner['description'] as String? ?? '';
                final bannerLink = banner['link'] as String? ?? 'https://www.saway.store';
                final bool isWhatsApp = bannerLink == 'whatsapp';

                return GestureDetector(
                  onTap: () => _openBannerLink(bannerLink),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: bannerImage,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: _appBarColor,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: _accentColor,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: _appBarColor,
                              child: Center(
                                child: Icon(
                                  Icons.image,
                                  color: Colors.white54,
                                  size: 60,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.8),
                                  Colors.transparent,
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 16,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bannerTitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black,
                                        blurRadius: 4,
                                        offset: Offset(1, 1),
                                      ),
                                    ],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (bannerDescription.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      bannerDescription,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black,
                                            blurRadius: 4,
                                            offset: Offset(1, 1),
                                          ),
                                        ],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _accentColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.ads_click, size: 14, color: Colors.black),
                                  SizedBox(width: 4),
                                  Text(
                                    'إعلان',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: GestureDetector(
                              onTap: () => _openBannerLink(bannerLink),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isWhatsApp
                                      ? const Color(0xFF25D366)
                                      : Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isWhatsApp ? Icons.message : Icons.open_in_new,
                                      color: isWhatsApp ? Colors.white : Colors.black,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isWhatsApp ? 'واتساب' : 'زيارة الموقع',
                                      style: TextStyle(
                                        color: isWhatsApp ? Colors.white : Colors.black,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // مؤشر الصفحات
          if (_banners.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_banners.length, (index) {
                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                      setState(() {
                        _currentBannerIndex = index;
                      });
                    },
                    child: Container(
                      width: _currentBannerIndex == index ? 12 : 8,
                      height: _currentBannerIndex == index ? 12 : 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentBannerIndex == index
                            ? _accentColor
                            : Colors.white.withOpacity(0.5),
                      ),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  // ✅ 2. دالة بناء قسم القنوات المباشرة
  Widget _buildLiveChannelsSection() {
    const double liveCardWidth = 240;
    const double liveCardHeight = 140;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "القنوات المباشرة",
                style: TextStyle(
                  color: Color(0xFFFDD835),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LivePage()),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _accentColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Text(
                        "مشاهدة الكل",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward, color: Colors.black, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        FutureBuilder<List<Movie>>(
          future: _liveChannelsFuture,
          builder: (context, snapshot) {
            // ✅ عرض حالة التحميل
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                height: liveCardHeight + 10,
                child: Center(
                  child: CircularProgressIndicator(color: _accentColor),
                ),
              );
            }
            
            // ✅ عرض حالة الخطأ
            if (snapshot.hasError) {
              print('❌ خطأ في FutureBuilder للقنوات: ${snapshot.error}');
              return _buildErrorIndicator(
                height: liveCardHeight + 10,
                message: "حدث خطأ في تحميل القنوات",
              );
            }
            
            // ✅ إذا لم تكن هناك بيانات أو كانت فارغة
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              print('⚠️ لا توجد بيانات للقنوات المباشرة');
              return _buildNoChannelsMessage(liveCardHeight + 10);
            }
            
            final channels = snapshot.data!;
            print('✅ عدد القنوات المعروضة: ${channels.length}');
            
            return SizedBox(
              height: liveCardHeight + 10,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: channels.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: _buildLiveChannelCard(channels[index], liveCardWidth, liveCardHeight),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  // ✅ 3. تصميم الكارت للقنوات المباشرة
  Widget _buildLiveChannelCard(Movie channel, double width, double height) {
    // 🎨 استخراج معلومات الجودة من البيانات
    final bool isHD = channel.isHD ?? true;
    final String quality = channel.quality ?? 'HD';

    final image = _getBestImageForMovie(channel);
    final isAsset = _isAssetImage(image);

    return GestureDetector(
      onTap: () => _openLivePlayer(channel),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: _appBarColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 🖼️ الصورة
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildImageWidget(
                  imageUrl: image,
                  isAsset: isAsset,
                  height: double.infinity,
                  width: double.infinity,
                  fit: BoxFit.cover),
            ),

            // ⭐ بادج الجودة (أعلى اليمين)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: isHD ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  quality,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // 📝 العنوان (في الأسفل مع خلفية شفافة)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Text(
                  channel.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // 🔴 بادج LIVE حمراء
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ رسالة عدم وجود قنوات
  Widget _buildNoChannelsMessage(double height) {
    return SizedBox(
      height: height,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.live_tv,
              color: Colors.white54,
              size: 40,
            ),
            SizedBox(height: 8),
            Text(
              "لا توجد قنوات مباشرة حالياً",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 4),
            Text(
              "سيتم تحديث القائمة قريباً",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _liveChannelsFuture = _fetchLiveChannelsFromAPI();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: Colors.black,
              ),
              child: Text("إعادة تحميل"),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ تشغيل القناة المباشرة
  Future<void> _openLivePlayer(Movie channel) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerFullScreen(
          movie: channel,
          videoUrl: channel.videoUrl ?? '',
          title: channel.title,
          startAt: Duration.zero,
          isLive: true,
        ),
      ),
    );
  }

  Widget _buildTopLogo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Image.asset(
            'assets/app/app.PNG',
            width: 120,
            height: 40,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 12),
          const Text(
            'QASUION_TV',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SearchPage()));
            },
            icon: const Icon(Icons.search, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title,
      {VoidCallback? onTap, bool showArrow = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: _accentColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (showArrow)
              Icon(
                Icons.arrow_forward_ios,
                color: _accentColor,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalList({
    required Widget Function(BuildContext, int) itemBuilder,
    required int itemCount,
    required double height,
    bool hasViewAllCard = false,
  }) {
    final totalItems = itemCount + (hasViewAllCard ? 1 : 0);
    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: totalItems,
        itemBuilder: (context, index) {
          if (hasViewAllCard && index == itemCount) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: _buildViewAllCard(height),
            );
          }
          final child = itemBuilder(context, index);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: child,
          );
        },
      ),
    );
  }

  Widget _buildViewAllCard(double height) {
    return Container(
      width: 150,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      decoration: BoxDecoration(
        color: _appBarColor,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: _accentColor, width: 2),
      ),
      child: const Center(
        child: Text(
          "View All",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

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

    if (isAsset) {
      return Image.asset(
        imageUrl,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            _buildPlaceholder(h: height, w: width),
      );
    } else {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: fit,
        placeholder: (context, url) =>
            _buildLoadingPlaceholder(h: height, w: width),
        errorWidget: (context, url, error) =>
            _buildPlaceholder(h: height, w: width),
      );
    }
  }

  bool _isAssetImage(String imageUrl) {
    return imageUrl.startsWith('assets/') ||
        imageUrl.startsWith('asset') ||
        !imageUrl.startsWith('http');
  }

  String _getBestImageForMovie(Movie movie) {
    if (movie.imageAsset.isNotEmpty) {
      return movie.imageAsset;
    }
    if (movie.imageUrl.isNotEmpty) {
      return movie.imageUrl;
    }
    if (movie.posterPath != null && movie.posterPath!.isNotEmpty) {
      return movie.posterPath!;
    }
    if (movie.backdropPath != null && movie.backdropPath!.isNotEmpty) {
      return movie.backdropPath!;
    }
    if (movie.displayImage.isNotEmpty) {
      return movie.displayImage;
    }
    return 'assets/placeholder_image.jpg';
  }

  Widget _buildMoviePortraitCard(
      Movie movie, double cardWidth, double imageHeight, double titleBarHeight,
      {String type = 'arabic_movie'}) {
    final startAt = (movie.id != null) ? _watchProgress[movie.id] : null;
    final totalDuration = parseDuration(movie.duration ?? '0m');
    final progressDuration = startAt ?? Duration.zero;
    final progressPercent = totalDuration.inMilliseconds > 0
        ? progressDuration.inMilliseconds / totalDuration.inMilliseconds
        : 0.0;
    final bool showProgress = progressPercent > 0 && progressPercent < 0.95;
    final String bestImage = _getBestImageForMovie(movie);
    final bool isAsset = _isAssetImage(bestImage);

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MovieDetailPage(movie: movie),
          ),
        );
        if (mounted) {
          switch (type) {
            case 'arabic_movie':
              setState(() {
                _arabicMoviesFuture = ApiService.getMovies();
              });
              break;
            case 'foreign_movie':
            case 'disney':
              setState(() {
                _foreignMoviesFuture = ApiService.getForeignMovies();
                _disneyMoviesFuture = ApiService.getDisneyMovies();
              });
              break;
          }
          await _loadContinueWatchingData();
        }
      },
      child: SizedBox(
        width: cardWidth,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: imageHeight,
                    child: ClipRRect(
                      borderRadius: BorderRadius.zero,
                      child: _buildImageWidget(
                        imageUrl: bestImage,
                        isAsset: isAsset,
                        height: imageHeight,
                        width: cardWidth,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (showProgress)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        value: progressPercent.clamp(0.0, 1.0),
                        backgroundColor: Colors.black.withOpacity(0.5),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(_accentColor),
                        minHeight: 4,
                      ),
                    )
                ],
              ),
              Container(
                height: titleBarHeight,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: const BoxDecoration(
                  color: Colors.black,
                ),
                child: Center(
                  child: Text(
                    movie.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeriesPortraitCard(
      Movie series, double cardWidth, double imageHeight, double titleBarHeight,
      {String type = 'arabic_series'}) {
    final String bestImage = _getBestImageForMovie(series);
    final bool isAsset = _isAssetImage(bestImage);

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SeriesDetailPage(
              series: series,
              onEpisodeWatched: _updateContinueWatching,
            ),
          ),
        );
        if (mounted) {
          switch (type) {
            case 'arabic_series':
              setState(() {
                _arabicSeriesFuture = ApiService.getArabicSeries();
              });
              break;
            case 'foreign_series':
            case 'turkish_series':
              setState(() {
                if (type == 'foreign_series') {
                  _foreignSeriesFuture = ApiService.getForeignSeries();
                } else if (type == 'turkish_series') {
                  _turkishSeriesFuture = ApiService.getTurkishSeries();
                }
              });
              break;
          }
          await _loadContinueWatchingData();
        }
      },
      child: SizedBox(
        width: cardWidth,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: imageHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.zero,
                  child: _buildImageWidget(
                    imageUrl: bestImage,
                    isAsset: isAsset,
                    height: imageHeight,
                    width: cardWidth,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Container(
                height: titleBarHeight,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: const BoxDecoration(
                  color: Colors.black,
                ),
                child: Center(
                  child: Text(
                    series.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContinueWatchingCard(Movie movie, double progressPercent,
      Duration startAt, double cardWidth, double cardHeight) {
    final String durationString = movie.duration ?? 'N/A';
    final bool isSeries = movie.type == 'series' || movie.episodes != null;
    final String itemType = isSeries ? 'مسلسل' : 'فيلم';

    return GestureDetector(
      onTap: () async {
        if (isSeries) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SeriesDetailPage(
                series: movie,
                onEpisodeWatched: _updateContinueWatching,
              ),
            ),
          ).then((_) => _loadContinueWatchingData());
        } else {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPlayerFullScreen(
                videoUrl: movie.videoUrl ?? '',
                title: movie.title,
                movie: movie,
                startAt: startAt,
                isLive: false,
              ),
            ),
          );
          if (result is Duration) {
            _updateContinueWatching(movie, result);
          } else {
            _loadContinueWatchingData();
          }
        }
      },
      child: SizedBox(
        width: cardWidth,
        height: cardHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: ClipRRect(
            borderRadius: BorderRadius.zero,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildImageWidget(
                  imageUrl: _getBestImageForMovie(movie),
                  isAsset: _isAssetImage(_getBestImageForMovie(movie)),
                  height: cardHeight,
                  width: cardWidth,
                  fit: BoxFit.cover,
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent
                      ],
                      stops: const [0.0, 0.5],
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      itemType,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 25,
                  left: 8,
                  right: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    value: progressPercent,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
                    minHeight: 5,
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      durationString,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator({required double height}) {
    return SizedBox(
      height: height,
      child: Center(
        child: CircularProgressIndicator(color: _accentColor),
      ),
    );
  }

  Widget _buildErrorIndicator(
      {required double height, String message = "فشل تحميل البيانات."}) {
    return SizedBox(
      height: height,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 40,
            ),
            SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  // إعادة تحميل البيانات حسب القسم
                  if (message.contains("القنوات")) {
                    _liveChannelsFuture = _fetchLiveChannelsFromAPI();
                  } else if (message.contains("أفلام عربية")) {
                    _arabicMoviesFuture = ApiService.getMovies();
                  } else if (message.contains("مسلسلات عربية")) {
                    _arabicSeriesFuture = ApiService.getArabicSeries();
                  } else if (message.contains("تركية")) {
                    _turkishSeriesFuture = ApiService.getTurkishSeries();
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: Colors.black,
              ),
              child: Text("إعادة المحاولة"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingPlaceholder({double? h, double? w}) {
    return Container(
      height: h,
      width: w,
      color: _appBarColor.withOpacity(0.5),
      child: const Center(
        child: Icon(Icons.movie_filter_outlined,
            color: Colors.white24, size: 40),
      ),
    );
  }

  Widget _buildPlaceholder({double? h, double? w}) {
    return Container(
      height: h,
      width: w,
      color: _appBarColor.withOpacity(0.5),
      child: const Center(
        child: Icon(Icons.broken_image_outlined,
            color: Colors.white38, size: 40),
      ),
    );
  }

  void _onItemTapped(int index) async {
    if (mounted) {
      if (index == 0) {
        if (_selectedIndex != index) {
          setState(() => _selectedIndex = index);
        }
      } else if (index == 1) {
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const SearchPage()));
      } else if (index == 2) {
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const LivePage()));
      } else if (index == 3) {
        await AppBottomNav.openWhatsApp();
      } else if (index == 4) {
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const AccountPage()));
      }
      if (index != 0) {
        setState(() => _selectedIndex = 0);
      }
    }
  }

  Duration parseDuration(String durationString) {
    int hours = 0;
    int minutes = 0;
    int seconds = 0;
    try {
      final hourMatch =
          RegExp(r'(\d+)\s*(?:h|ساعة)').firstMatch(durationString);
      if (hourMatch != null) hours = int.parse(hourMatch.group(1)!);
      final minuteMatch =
          RegExp(r'(\d+)\s*(?:m|دقيقة)').firstMatch(durationString);
      if (minuteMatch != null) minutes = int.parse(minuteMatch.group(1)!);
      final secondMatch =
          RegExp(r'(\d+)\s*(?:s|ثانية)').firstMatch(durationString);
      if (secondMatch != null) seconds = int.parse(secondMatch.group(1)!);
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
      } else if (hours == 0 &&
          minutes == 0 &&
          seconds == 0 &&
          durationString.isNotEmpty) {
        minutes =
            int.tryParse(durationString.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      }
    } catch (e) {
      return Duration.zero;
    }
    return Duration(
        hours: hours.abs(), minutes: minutes.abs(), seconds: seconds.abs());
  }
}