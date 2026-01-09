import 'dart:async';
import 'dart:convert'; 
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:qasioun_tv/api/ApiService.dart';
import 'package:qasioun_tv/model/movie_model.dart';
import 'package:qasioun_tv/video_player/video_player_screen.dart';
import 'package:qasioun_tv/movies arapic/movie_detail_page.dart';
import 'package:qasioun_tv/Screen/search_page.dart';
import 'package:qasioun_tv/Screen/HomePage.dart';
import 'package:qasioun_tv/live/live_page.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:qasioun_tv/widgets/app_bottom_nav.dart';
import 'package:qasioun_tv/widgets/bottom_nav_controller.dart';
import 'package:qasioun_tv/services/user_service.dart';
import 'package:qasioun_tv/Screen/account_page.dart';

class MoviesArabicPage extends StatefulWidget {
  const MoviesArabicPage({super.key});

  @override
  _MoviesArabicPageState createState() => _MoviesArabicPageState();
}

class _MoviesArabicPageState extends State<MoviesArabicPage> {
  List<Movie> movies = [];
  bool isLoading = true;
  List<Movie> filteredMovies = [];
  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();
  bool _isAdmin = false;

  Timer? _refreshTimer; 

  // الألوان المستخدمة
  final Color _backgroundColor = const Color(0xFF040C1A);
  final Color _appBarColor = const Color(0xFF081830);
  final Color _accentColor = const Color(0xFFFDD835);

  @override
  void initState() {
    super.initState();
    // set global bottom nav index to Home as there is no dedicated Movies tab
    BottomNavController.index.value = 0;
    _initializeApp();
    _startAutoRefresh(); 
    _initUserState();
  }

  Future<void> _initUserState() async {
    final v = await UserService.isAdmin();
    if (mounted) setState(() => _isAdmin = v);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel(); 
    _searchController.dispose();
    super.dispose();
  }

  // بدء التحديث التلقائي كل 10 دقائق
  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      if (!_showSearchBar && mounted) {
        print("Auto-refreshing movies list in MoviesArabicPage...");
        loadMovies(showMessages: false);
      }
    });
  }

  // تهيئة الصفحة
  Future<void> _initializeApp() async {
    await loadMovies(showMessages: false);
    // checkForUpdates(); // يمكنك تفعيله إذا أردت التحقق عند فتح الصفحة
  }

  // التحقق من تحديثات التطبيق (اختياري)
  Future<void> checkForUpdates() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final response = await http.get(Uri.parse(
          'https://api.npoint.io/5b7128a45d775d19a493'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersion = data['version'];
        if (latestVersion != currentVersion) {
          print("Update available: $latestVersion");
          // يمكنك إظهار النافذة هنا
        } else {
          print("App is up to date.");
        }
      }
    } catch (e) {
      print('Error checking app updates: $e');
    }
  }

  // --- فتح مشغل الفيديو وتحديث SharedPreferences ---
  Future<void> _openVideoPlayer(Movie movie) async {
    // 1. قراءة نقطة التوقف المحفوظة
    final prefs = await SharedPreferences.getInstance();
    Duration startAt = Duration.zero;
    if (movie.id != null) {
      final int? savedPositionMillis =
          prefs.getInt('playback_position_${movie.id}');
      if (savedPositionMillis != null) {
        startAt = Duration(milliseconds: savedPositionMillis);
      }
    }

    // 2. الانتقال للمشغل وانتظار النتيجة
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerFullScreen(
          movie: movie,
          videoUrl: movie.videoUrl ?? '',
          title: movie.title,
          startAt: startAt,
        ),
      ),
    );

    // 3. تحديث SharedPreferences بناءً على النتيجة
    if (!mounted || movie.id == null) return;

    Duration finalPosition = startAt; // الافتراضي
    if (result is Duration) {
      finalPosition = result;
    } 
    // إذا كانت النتيجة true، نعتمد startAt (آخر نقطة قبل التشغيل)

    await _updateWatchHistoryInPrefs(movie, finalPosition);

    // Don't pop the Movies page when returning from the player — keep it in stack.
    // بعد العودة من المشغل، حدث قائمة الأفلام لتعكس أي تغييرات
    if (mounted) {
      await loadMovies(showMessages: false);
    }
  }

  // دالة لتحديث قائمة "مشاهداتك" ونقطة التوقف في SharedPreferences
  Future<void> _updateWatchHistoryInPrefs(
      Movie movie, Duration lastPosition) async {
    if (movie.id == null) return;
      
    // ⭐️ حساب المدة الإجمالية
    final prefs = await SharedPreferences.getInstance();
    final int? totalDurationMillis = prefs.getInt('playback_duration_${movie.id}');
    
    final totalDuration = (totalDurationMillis != null && totalDurationMillis > 0) 
        ? Duration(milliseconds: totalDurationMillis)
        : Duration.zero; 
        
    final progressPercent = (totalDuration.inMilliseconds > 0)
        ? lastPosition.inMilliseconds / totalDuration.inMilliseconds
        : 0.0;
        
    // ⭐️ إزالة إذا تمت المشاهدة بأكثر من 95%
    if (progressPercent > 0.95) {
      await prefs.remove('playback_position_${movie.id}');
      await prefs.remove('playback_duration_${movie.id}'); 
      // إزالة الفيلم من قائمة "مشاهداتك"
      List<String>? savedListJson = prefs.getStringList('continue_watching_list');
      if (savedListJson != null) {
          final currentList = savedListJson.map((s) => Movie.fromJson(json.decode(s))).toList();
          currentList.removeWhere((m) => m.id == movie.id);
          final List<String> listToSaveJson = currentList.map((m) => json.encode(m.toJson())).toList();
          await prefs.setStringList('continue_watching_list', listToSaveJson);
      }
      return; 
    }
    
    if (lastPosition <= Duration.zero) {
      await prefs.remove('playback_position_${movie.id}');
      // لا حاجة لحذف duration
      return;
    }


    List<Movie> currentList = [];
    final List<String>? savedListJson =
        prefs.getStringList('continue_watching_list');
    if (savedListJson != null) {
      try {
        currentList =
            savedListJson.map((s) => Movie.fromJson(json.decode(s))).toList();
      } catch (e) {
        print("Error decoding saved list: $e");
      }
    }

    currentList.removeWhere((m) => m.id == movie.id);
    currentList.insert(0, movie);

    // حفظ القائمة
    try {
      final List<String> listToSaveJson =
          currentList.take(10).map((m) => json.encode(m.toJson())).toList(); // ⭐️ حد 10
      await prefs.setStringList('continue_watching_list', listToSaveJson);
    } catch (e) {
      print("Error encoding movie list for SharedPreferences: $e");
    }

    // حفظ نقطة التوقف
    await prefs.setInt(
        'playback_position_${movie.id}', lastPosition.inMilliseconds);
    print(
        "Updated SharedPreferences from MoviesArabicPage for ID: ${movie.id}");
  }
  // --- نهاية تعديل المشغل والتحديث ---

  // تحميل قائمة الأفلام
  Future<void> loadMovies({bool showMessages = true}) async {
    bool initialLoad = movies.isEmpty;
    if (initialLoad && mounted) {
      setState(() => isLoading = true);
    } else if (mounted) {
      print("Refreshing movies list...");
    }

    try {
      final loadedMovies = await ApiService.getMovies();
      if (mounted) {
        setState(() {
          movies = loadedMovies;
          if (!_showSearchBar) {
            filteredMovies = movies;
          } else {
            _searchMovies(_searchController.text);
          }
          isLoading = false;
        });
        if (showMessages) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تحديث القائمة بنجاح!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('[MoviesArabicPage] Error loading movies: $e');
      if (mounted) {
        setState(() => isLoading = false);
        if (showMessages) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('فشل تحميل التحديث. تحقق من الاتصال.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3)),
          );
        }
      }
    }
  }

  // فلترة الأفلام
  void _searchMovies(String query) {
    if (!mounted) return;
    if (query.isEmpty) {
      setState(() => filteredMovies = movies);
      return;
    }
    Future.microtask(() {
      final lowerQuery = query.toLowerCase();
      final results = movies.where((movie) {
        return movie.title.toLowerCase().contains(lowerQuery) ||
            movie.description.toLowerCase().contains(lowerQuery) ||
            movie.category.toLowerCase().contains(lowerQuery);
      }).toList();
      if (mounted) setState(() => filteredMovies = results);
    });
  }

  // تبديل شريط البحث
  void _toggleSearchBar() {
    if (!mounted) return;
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (!_showSearchBar) {
        _searchController.clear();
        filteredMovies = movies;
      }
    });
  }

  void _onBottomNavTapped(int index) async {
    if (index == 0) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomePage()));
    } else if (index == 1) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const SearchPage()));
    } else if (index == 2) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LivePage()));
    } else if (index == 3) {
      // contact
      await AppBottomNav.openWhatsApp();
    } else if (index == 4) {
      // account -> always open AccountPage
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const AccountPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildMainAppBar(),
      body: _buildBody(),
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

  AppBar _buildMainAppBar() {
    return AppBar(
      leading: _showSearchBar
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: _toggleSearchBar,
              tooltip: 'إغلاق البحث',
            )
          : IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () => loadMovies(showMessages: true),
              tooltip: 'تحديث',
            ),
      title: _showSearchBar
          ? _buildSearchField()
          : const Text('أفلام عربية',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              )),
      backgroundColor: _appBarColor,
      elevation: 0,
      centerTitle: true,
      actions: _showSearchBar
          ? [
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.white),
                tooltip: 'مسح البحث',
                onPressed: () {
                  if (_searchController.text.isNotEmpty) {
                    _searchController.clear();
                    _searchMovies('');
                  }
                },
              ),
            ]
          : [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: _toggleSearchBar,
                tooltip: 'بحث',
              ),
            ],
    );
  }

  // بناء حقل البحث
  Widget _buildSearchField() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _searchMovies,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: const InputDecoration(
          hintText: 'ابحث في الأفلام...',
          hintStyle: TextStyle(color: Colors.white54),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, color: Colors.white54, size: 20),
          contentPadding: EdgeInsets.symmetric(vertical: 11.5),
        ),
        cursorColor: Colors.white,
        autofocus: true,
      ),
    );
  }

  // بناء محتوى الصفحة
  Widget _buildBody() {
    if (isLoading) return _buildLoadingIndicator();
    if (movies.isEmpty && !_showSearchBar) return _buildEmptyState();
    if (filteredMovies.isEmpty && _showSearchBar) return _buildNoResults();
    return _buildMoviesGrid();
  }

  // --- Widgets مساعدة ---
  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: _accentColor),
          const SizedBox(height: 16),
          const Text('جاري تحميل الأفلام...',
              style: TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return const Center(
      child: Text(
        'لا توجد نتائج تطابق بحثك',
        style: TextStyle(fontSize: 18, color: Colors.grey),
      ),
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RefreshIndicator(
          onRefresh: () => loadMovies(showMessages: true),
          backgroundColor: _appBarColor,
          color: _accentColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.mobile_off_outlined,
                        size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('لا توجد أفلام متاحة حالياً',
                        style: TextStyle(fontSize: 18, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text('اسحب للأسفل أو اضغط زر التحديث',
                        style:
                            TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // بناء شبكة العرض مع RefreshIndicator
  Widget _buildMoviesGrid() {
    return OrientationBuilder(
      builder: (context, orientation) {
        final crossAxisCount = orientation == Orientation.portrait ? 3 : 5;
        final childAspectRatio =
            orientation == Orientation.portrait ? 0.65 : 0.75;
        return RefreshIndicator(
          onRefresh: () => loadMovies(showMessages: true),
          backgroundColor: _appBarColor,
          color: _accentColor,
          child: GridView.builder(
            physics:
                const AlwaysScrollableScrollPhysics(), // لتمكين السحب دائماً
            padding: const EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: filteredMovies.length,
            itemBuilder: (context, index) {
              return _buildMovieCard(filteredMovies[index]);
            },
          ),
        );
      },
    );
  }

  // بناء كرت الفيلم (مع إزالة الحواف ودعم Assets)
  Widget _buildMovieCard(Movie movie) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => MovieDetailPage(movie: movie)));
        // بعد العودة من صفحة التفاصيل، حدث القائمة تلقائياً
        if (mounted) {
          await loadMovies(showMessages: false);
        }
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        // ❌ إزالة الحواف الدائرية من الكارد الخارجي
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                // ❌ إزالة الحواف الدائرية من الصورة
                borderRadius: BorderRadius.zero,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // ✅ استخدام منطق عرض الصورة (Asset أو Network)
                    _buildMovieImageWidget(movie),

                    // عرض التقييم إذا كان موجوداً
                    if (movie.rating != null && movie.rating! > 0)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star,
                                  color: Colors.amber, size: 12),
                              const SizedBox(width: 2),
                              Text(
                                movie.rating!.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                    // ⭐️ شريط التقدم والوقت (نقلناه هنا داخل Stack)
                    FutureBuilder<SharedPreferences>(
                      future: SharedPreferences.getInstance(),
                      builder: (context, snap) {
                        if (!snap.hasData || movie.id == null) return const SizedBox.shrink();
                        final prefs = snap.data!;
                        final pos = prefs.getInt('playback_position_${movie.id}') ?? 0;
                        final total = prefs.getInt('playback_duration_${movie.id}') ?? 0;
                        
                        final progressPercent = (total > 0) ? (pos / total).clamp(0.0, 1.0) : 0.0;
                        if (progressPercent <= 0 || progressPercent > 0.95) return const SizedBox.shrink(); // لا تعرض إذا لم تتم المشاهدة أو تمت بالكامل

                        final left = _formatDuration(Duration(milliseconds: pos));
                        final right = _formatDuration(Duration(milliseconds: total));
                        
                        return Stack(
                            children: [
                                // الوقت في الأسفل (يسار الصورة)
                                Positioned(
                                  bottom: 4, 
                                  right: 4, // ✅ الموقع الجديد
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(4)),
                                    child: Text('$left / $right', style: const TextStyle(color: Colors.white, fontSize: 10)),
                                  ),
                                ),
                                // شريط التقدم across bottom
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: LinearProgressIndicator(
                                    value: progressPercent,
                                    backgroundColor: Colors.black.withOpacity(0.3),
                                    valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
                                    minHeight: 4,
                                  ),
                                ),
                            ]
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            // ❌ تم حذف الـ FutureBuilder الذي كان يعرض الشريط هنا
            Container(
              height: 35,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              // ❌ إزالة الحواف الدائرية من شريط العنوان
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.zero,
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
    );
  }
  
  // ⭐️ دالة محسنة لعرض صور الأفلام
  Widget _buildMovieImageWidget(Movie movie) {
    // الحصول على أفضل صورة متاحة للفيلم
    final String bestImage = _getBestImageForMovie(movie);
    
    // التحقق مما إذا كانت الصورة من نوع Asset
    final bool isAsset = _isAssetImage(bestImage);
    
    return _buildImageWidget(
      imageUrl: bestImage,
      isAsset: isAsset,
      height: double.infinity,
      width: double.infinity,
      fit: BoxFit.cover,
    );
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
      return _buildPlaceholder();
    }

    // إذا كانت الصورة من الإنترنت (غير asset)
    if (!isAsset) {
      try {
        return CachedNetworkImage(
          imageUrl: imageUrl,
          fit: fit,
          placeholder: (context, url) => _buildLoadingPlaceholder(),
          errorWidget: (context, url, error) {
            // إذا فشل تحميل الصورة من الإنترنت، جرب كـ asset
            try {
              return Image.asset(
                imageUrl,
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
            imageUrl,
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
        imageUrl,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          // إذا فشل كـ asset، جرب كـ صورة من الإنترنت
          try {
            return CachedNetworkImage(
              imageUrl: imageUrl,
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

  // دالة تنسيق المدة
  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      final h = d.inHours;
      final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      return '$h:$m:$s';
    } else {
      final m = d.inMinutes.toString().padLeft(2, '0');
      final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      return '$m:$s';
    }
  }

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
} // نهاية الـ State