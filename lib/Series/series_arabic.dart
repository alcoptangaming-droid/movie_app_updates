import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:qasioun_tv/Screen/HomePage.dart';
import 'package:qasioun_tv/Screen/search_page.dart';
import 'package:qasioun_tv/widgets/app_bottom_nav.dart';
import 'package:qasioun_tv/widgets/bottom_nav_controller.dart';
import 'package:qasioun_tv/services/user_service.dart';
import 'package:qasioun_tv/Screen/account_page.dart';
import 'package:qasioun_tv/live/live_page.dart';
import 'package:qasioun_tv/Series/series_detail_page.dart';
import 'package:qasioun_tv/api/ApiService.dart';
import 'package:qasioun_tv/model/movie_model.dart';

class SeriesArabicPage extends StatefulWidget {
  final Function(Movie, Duration) onEpisodeWatched;

  const SeriesArabicPage({super.key, required this.onEpisodeWatched});

  @override
  _SeriesArabicPageState createState() => _SeriesArabicPageState();
}

class _SeriesArabicPageState extends State<SeriesArabicPage> {
  List<Movie> seriesList = [];
  bool isLoading = true;
  List<Movie> filteredSeries = [];
  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();
  Timer? _refreshTimer;
  bool _isAdmin = false;

  final Color _backgroundColor = const Color(0xFF040C1A);
  final Color _appBarColor = const Color(0xFF081830);
  final Color _accentColor = const Color(0xFFFDD835);

  @override
  void initState() {
    super.initState();
    BottomNavController.index.value = 0;
    _initializeApp();
    _initUserState();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      if (!_showSearchBar && mounted) {
        print("Auto-refreshing series list in SeriesArabicPage...");
        loadSeries(isManualRefresh: false);
      }
    });
  }

  Future<void> _initializeApp() async {
    await loadSeries(isManualRefresh: false);
  }

  Future<void> _initUserState() async {
    final v = await UserService.isAdmin();
    if (mounted) setState(() => _isAdmin = v);
  }

  void _onBottomNavTapped(int index) async {
    if (index == 0) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomePage()));
    } else if (index == 1) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const SearchPage()));
    } else if (index == 2) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LivePage()));
    } else if (index == 3) {
      await AppBottomNav.openWhatsApp();
    } else if (index == 4) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const AccountPage()));
    }
  }

  Future<void> loadSeries({bool isManualRefresh = true}) async {
    bool initialLoad = seriesList.isEmpty;
    if (initialLoad && mounted) {
      setState(() => isLoading = true);
    } else if (mounted) {
      print("Refreshing series list...");
    }

    try {
      final loadedSeries = await ApiService.getArabicSeries();
      if (mounted) {
        setState(() {
          seriesList = loadedSeries;
          if (!_showSearchBar) {
            filteredSeries = seriesList;
          } else {
            _searchSeries(_searchController.text);
          }
          isLoading = false;
        });
      }
    } catch (e) {
      print('[SeriesArabicPage] Error loading series: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _searchSeries(String query) {
    if (!mounted) return;
    if (query.isEmpty) {
      setState(() {
        filteredSeries = seriesList;
      });
      return;
    }

    Future.microtask(() {
      final lowerCaseQuery = query.toLowerCase();
      final results = seriesList.where((series) {
        return series.title.toLowerCase().contains(lowerCaseQuery) ||
            (series.description?.toLowerCase().contains(lowerCaseQuery) ?? false);
      }).toList();
      if (mounted) setState(() => filteredSeries = results);
    });
  }

  void _toggleSearchBar() {
    if (!mounted) return;
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (!_showSearchBar) {
        _searchController.clear();
        filteredSeries = seriesList;
      }
    });
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
              onPressed: () => loadSeries(isManualRefresh: true),
              tooltip: 'تحديث',
            ),
      title: _showSearchBar
          ? _buildSearchField()
          : const Text('مسلسلات عربية',
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
                    _searchSeries('');
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

  Widget _buildSearchField() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _searchSeries,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: const InputDecoration(
          hintText: 'ابحث في المسلسلات...',
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

  Widget _buildBody() {
    if (isLoading) return _buildLoadingIndicator();
    if (seriesList.isEmpty && !_showSearchBar) return _buildEmptyState();
    if (filteredSeries.isEmpty && _showSearchBar) return _buildNoResults();
    return _buildSeriesGrid();
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: _accentColor),
          const SizedBox(height: 16),
          const Text('جاري تحميل المسلسلات...',
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
          onRefresh: () => loadSeries(isManualRefresh: true),
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
                    const Icon(Icons.tv_off_outlined,
                        size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('لا توجد مسلسلات متاحة حالياً',
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

  Widget _buildSeriesGrid() {
    return OrientationBuilder(
      builder: (context, orientation) {
        final crossAxisCount = orientation == Orientation.portrait ? 3 : 5;
        final childAspectRatio =
            orientation == Orientation.portrait ? 0.65 : 0.75;
        return RefreshIndicator(
          onRefresh: () => loadSeries(isManualRefresh: true),
          backgroundColor: _appBarColor,
          color: _accentColor,
          child: GridView.builder(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: filteredSeries.length,
            itemBuilder: (context, index) {
              return _buildSeriesCard(filteredSeries[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildSeriesCard(Movie series) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SeriesDetailPage(
              series: series,
              onEpisodeWatched: widget.onEpisodeWatched,
            ),
          ),
        );
        if (mounted) {
          await loadSeries(isManualRefresh: false);
        }
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.zero,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildSeriesImageWidget(series),
                    if (series.rating != null && series.rating! > 0)
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
                                series.rating!.toStringAsFixed(1),
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
                  ],
                ),
              ),
            ),
            Container(
              height: 35,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.zero,
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
    );
  }

  Widget _buildSeriesImageWidget(Movie series) {
    final bestImage = _getBestImageForSeries(series);
    final isAsset = _isAssetImage(bestImage);
    
    return _buildImageWidget(
      imageUrl: bestImage,
      isAsset: isAsset,
      height: double.infinity,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }

  String _getBestImageForSeries(Movie series) {
    // ✅ الأولوية لروابط الإنترنت المباشرة
    if (series.imageUrl.isNotEmpty && series.imageUrl != 'null') {
      return series.imageUrl;
    }
    if (series.posterPath != null && 
        series.posterPath!.isNotEmpty && 
        series.posterPath != 'null') {
      return series.posterPath!;
    }
    if (series.backdropPath != null && 
        series.backdropPath!.isNotEmpty && 
        series.backdropPath != 'null') {
      return series.backdropPath!;
    }
    // ✅ استخدام الـ Asset فقط كخيار أخير
    if (series.imageAsset.isNotEmpty && series.imageAsset != 'null') {
      return series.imageAsset;
    }
    return 'assets/placeholder_image.jpg';
  }

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
    return false;
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
        child: Icon(Icons.tv_off_outlined,
            color: Colors.white24, size: 40),
      ),
    );
  }
}