import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:qasioun_tv/Screen/HomePage.dart';
import 'package:qasioun_tv/Screen/search_page.dart';
import 'package:qasioun_tv/Screen/account_page.dart';
import 'package:qasioun_tv/model/movie_model.dart';
import 'package:qasioun_tv/video_player/video_player_screen.dart';
import 'package:qasioun_tv/widgets/app_bottom_nav.dart';
import 'package:qasioun_tv/widgets/bottom_nav_controller.dart';
import 'package:qasioun_tv/services/user_service.dart';

class LivePage extends StatefulWidget {
  const LivePage({super.key});

  @override
  State<LivePage> createState() => _LivePageState();
}

/* ================= MODEL ================= */
class LiveChannel {
  final String id;
  final String name;
  final String imageUrl;
  final String streamUrl;
  final String category;
  final String quality;
  final bool isHD;

  LiveChannel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.streamUrl,
    required this.category,
    required this.quality,
    required this.isHD,
  });

  factory LiveChannel.fromJson(Map<String, dynamic> json) {
    return LiveChannel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      imageUrl: json['image'] ?? 'assets/Image_live/LIVE.png',
      streamUrl: json['stream_url'] ?? '',
      category: json['category'] ?? 'عامة',
      quality: json['quality'] ?? '',
      isHD: json['isHD'] ?? false,
    );
  }
}

/* ================= PAGE ================= */
class _LivePageState extends State<LivePage> {
  static const String apiUrl =
      'https://api.npoint.io/f575068a82f14f5bf05d';

  final Color _bg = const Color(0xFF040C1A);
  final Color _appBar = const Color(0xFF081830);
  final Color _accent = const Color(0xFFFDD835);

  final double _cardW = 160;
  final double _cardH = 120;

  List<LiveChannel> channels = [];
  List<LiveChannel> filtered = [];

  bool loading = true;
  bool showSearch = false;
  bool isAdmin = false;

  Timer? timer;
  final TextEditingController searchCtrl = TextEditingController();

  int catIndex = 0;

  final List<String> categories = [
    'الكل',
    'رياضة (جميع الجودات)',
    'أخبار',
    'أفلام',
    'دراما',
    'أطفال',
    'وثائقي',
    'موسيقى',
    'قنوات مصر',
    'قنوات السعودية',
    'قنوات سوريا',
    'قنوات العراق',
    'قنوات لبنان',
    'قنوات الكويت',
    'قنوات الإمارات',
    'قنوات مغربية',
    'قنوات تونسية',
    'قنوات جزائرية',
    'قنوات دولية',
  ];

  @override
  void initState() {
    super.initState();
    BottomNavController.index.value = 2;
    _loadUser();
    loadChannels();
    timer = Timer.periodic(const Duration(minutes: 10), (_) => loadChannels());
  }

  Future<void> _loadUser() async {
    final v = await UserService.isAdmin();
    if (mounted) setState(() => isAdmin = v);
  }

  @override
  void dispose() {
    timer?.cancel();
    searchCtrl.dispose();
    super.dispose();
  }

  /* ================= DATA ================= */
  Future<void> loadChannels() async {
    try {
      final res = await http.get(Uri.parse(apiUrl));
      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        channels = data
            .map((e) => LiveChannel.fromJson(e))
            .where((c) => c.streamUrl.isNotEmpty)
            .toList();
        _applyFilter();
      }
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  void _applyFilter() {
    if (catIndex == 0) {
      filtered = channels;
    } else {
      final c = categories[catIndex];
      filtered = channels.where((e) {
        return c == 'رياضة (جميع الجودات)'
            ? e.category.contains('رياضة')
            : e.category == c;
      }).toList();
    }

    if (searchCtrl.text.isNotEmpty) {
      _search(searchCtrl.text);
    }
  }

  void _search(String q) {
    final s = q.toLowerCase();
    filtered = filtered
        .where((e) =>
            e.name.toLowerCase().contains(s) ||
            e.category.toLowerCase().contains(s) ||
            e.quality.toLowerCase().contains(s))
        .toList();
    setState(() {});
  }

  /* ================= PLAYER ================= */
  void _open(LiveChannel c) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerFullScreen(
          movie: Movie(
            title: c.name,
            imageUrl: c.imageUrl,
            videoUrl: c.streamUrl,
            category: c.category, description: '',
          ),
          videoUrl: c.streamUrl,
          title: c.name,
          isLive: true,
        ),
      ),
    );
  }

  /* ================= UI ================= */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 2,
        backgroundColor: _appBar,
        selectedItemColor: _accent,
        unselectedItemColor: Colors.white,
        onTap: _nav,
        isAdmin: isAdmin,
      ),
      body: loading
          ? Center(child: CircularProgressIndicator(color: _accent))
          : Column(
              children: [
                const SizedBox(height: 15), // ✅ مسافة 5px
                _buildCategories(),
                Expanded(child: _buildGrid()),
              ],
            ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _appBar,
      centerTitle: true,
      title: showSearch
          ? TextField(
              controller: searchCtrl,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'ابحث في القنوات...',
                hintStyle: TextStyle(color: Colors.white54),
                border: InputBorder.none,
              ),
              onChanged: _search,
            )
          : const Text('القنوات المباشرة'),
      actions: [
        IconButton(
          icon: Icon(showSearch ? Icons.close : Icons.search),
          onPressed: () {
            setState(() {
              showSearch = !showSearch;
              searchCtrl.clear();
              _applyFilter();
            });
          },
        ),
      ],
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (_, i) => GestureDetector(
          onTap: () {
            catIndex = i;
            _applyFilter();
            setState(() {});
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: i == catIndex ? _accent : _appBar,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                categories[i],
                style: TextStyle(
                  color: i == catIndex ? Colors.black : Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filtered.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: _cardW / _cardH,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (_, i) => _buildCard(filtered[i]),
    );
  }

  /* ================= CARD ================= */
  Widget _buildCard(LiveChannel c) {
    return GestureDetector(
      onTap: () => _open(c),
      child: Container(
        decoration: BoxDecoration(
          color: _appBar,
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
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                c.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.tv, color: Colors.white54),
              ),
            ),

            // ⭐ الجودة فقط (بدون مباشر)
            if (c.quality.isNotEmpty)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: c.isHD ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    c.quality,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // اسم القناة
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Text(
                  c.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
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

  void _nav(int i) {
    if (i == 0) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomePage()));
    } else if (i == 1) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const SearchPage()));
    } else if (i == 4) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const AccountPage()));
    }
  }
}
