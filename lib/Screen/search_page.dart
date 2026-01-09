import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:qasioun_tv/Series/series_detail_page.dart';
import 'package:qasioun_tv/api/ApiService.dart';
import 'package:qasioun_tv/model/movie_model.dart';
import 'package:qasioun_tv/video_player/video_player_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  bool _isLoading = false;
  List<Movie> _searchResults = [];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(q.trim());
    });
  }

  Future<void> _performSearch(String q) async {
    if (q.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 🚀 جلب البيانات من جميع الأقسام بالتوازي لضمان أفضل سرعة
      final results = await Future.wait([
        ApiService.getMovies(),          // أفلام عربية
        ApiService.getArabicSeries(),    // مسلسلات عربية
        ApiService.getForeignMovies(),   // أفلام أجنبية
        ApiService.getForeignSeries(),   // مسلسلات أجنبية
        ApiService.getDisneyMovies(),    // ديزني وأنمي
        ApiService.getTurkishSeries(),   // مسلسلات تركية
        ApiService.getLiveChannels(),    // قنوات مباشرة
      ]);

      // دمج كل القوائم في قائمة واحدة
      final allContent = results.expand((list) => list).toList();

      final queryLower = q.toLowerCase();
      
      // تصفية النتائج وإزالة التكرار
      final List<Movie> finalResults = [];
      final Set<String> seenTitles = {};

      for (var item in allContent) {
        bool matches = item.title.toLowerCase().contains(queryLower) || 
                      (item.description?.toLowerCase().contains(queryLower) ?? false);
        
        if (matches) {
          String normalizedTitle = item.title.trim().toLowerCase();
          if (!seenTitles.contains(normalizedTitle)) {
            finalResults.add(item);
            seenTitles.add(normalizedTitle);
          }
        }
      }

      setState(() {
        _searchResults = finalResults;
      });
    } catch (e) {
      print('Search error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- دوال الصور المساعدة ---
  String _getBestImageForMovie(Movie movie) {
    if (movie.imageUrl.isNotEmpty && movie.imageUrl != 'null') return movie.imageUrl;
    if (movie.posterPath != null && movie.posterPath!.isNotEmpty) return movie.posterPath!;
    if (movie.imageAsset.isNotEmpty) return movie.imageAsset;
    return 'assets/placeholder_image.jpg';
  }

  bool _isAssetImage(String url) => url.startsWith('assets/') || !url.startsWith('http');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF040C1A),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF081830),
        elevation: 0,
        title: _buildSearchInput(),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildSearchInput() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.white70, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(
                hintText: 'ابحث عن أفلام، مسلسلات، أو قنوات...',
                hintStyle: TextStyle(color: Colors.white30, fontSize: 14),
                border: InputBorder.none,
              ),
              style: const TextStyle(color: Colors.white, fontSize: 15),
              cursorColor: Colors.white,
              autofocus: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFDD835)));
    }

    if (_controller.text.isEmpty) {
      return _buildMessage(Icons.search, 'ابدأ بالبحث في كافة الأقسام');
    }

    if (_searchResults.isEmpty) {
      return _buildMessage(Icons.search_off, 'لا توجد نتائج لـ "${_controller.text}"');
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.65,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) => _buildMovieCard(_searchResults[index]),
    );
  }

  Widget _buildMessage(IconData icon, String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.white10),
          const SizedBox(height: 16),
          Text(text, style: const TextStyle(color: Colors.white54, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildMovieCard(Movie movie) {
    final String imageUrl = _getBestImageForMovie(movie);
    final bool isAsset = _isAssetImage(imageUrl);
    final bool isSeries = movie.episodes != null && movie.episodes!.isNotEmpty;

    return GestureDetector(
      onTap: () {
        if (isSeries) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SeriesDetailPage(
                series: movie,
                onEpisodeWatched: (m, d) {},
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VideoPlayerFullScreen(
                movie: movie,
                videoUrl: movie.videoUrl ?? '',
                title: movie.title,
              ),
            ),
          );
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            Positioned.fill(
              child: isAsset
                  ? Image.asset(imageUrl, fit: BoxFit.cover)
                  : CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.white10),
                      errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                    ),
            ),
            // ملصق نوع المحتوى (مسلسل)
            if (isSeries)
              Positioned(
                top: 5, right: 5,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(4)),
                  child: const Text('مسلسل', style: TextStyle(color: Colors.white, fontSize: 9)),
                ),
              ),
            // العنوان في الأسفل
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                color: Colors.black.withOpacity(0.7),
                child: Text(
                  movie.title,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}