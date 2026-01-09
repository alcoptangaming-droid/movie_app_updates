import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qasioun_tv/model/episode.dart';
import 'package:qasioun_tv/model/movie_model.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VideoPlayerFullScreen extends StatefulWidget {
  final String videoUrl;
  final String title;
  final Movie movie;
  final Duration? startAt;
  final Episode? currentEpisode;
  final List<Episode>? seriesEpisodes;
  final Function(Episode)? onNextEpisode;
  final bool isLive;

  const VideoPlayerFullScreen({
    super.key,
    required this.videoUrl,
    required this.title,
    required this.movie,
    this.startAt,
    this.currentEpisode,
    this.seriesEpisodes,
    this.onNextEpisode,
    this.isLive = false,
  });

  @override
  State<VideoPlayerFullScreen> createState() => _VideoPlayerFullScreenState();
}

class _VideoPlayerFullScreenState extends State<VideoPlayerFullScreen> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  bool _isLoading = true;
  bool _showControls = true;
  bool _hasError = false;
  String _errorMessage = "";

  Timer? _controlsTimer;
  Timer? _saveProgressTimer;
  double _currentSpeed = 1.0;

  Duration _lastSavedPosition = Duration.zero;
  bool _isVideoCompleted = false;
  Duration _totalDuration = Duration.zero;
  Timer? _saveToPrefsTimer;

  final List<Map<String, dynamic>> _playerSizes = [
    {'name': 'ملء الشاشة', 'scale': 1.0, 'icon': Icons.fullscreen},
    {'name': '75%', 'scale': 0.75, 'icon': Icons.zoom_out_map},
    {'name': '50%', 'scale': 0.5, 'icon': Icons.aspect_ratio},
  ];
  int _currentSizeIndex = 0;

  final List<Map<String, dynamic>> _fitModes = [
    {'name': 'ملء', 'fit': BoxFit.fill, 'icon': Icons.fit_screen},
    {'name': 'تغطية', 'fit': BoxFit.cover, 'icon': Icons.fullscreen},
    {'name': 'احتواء', 'fit': BoxFit.contain, 'icon': Icons.fullscreen_exit},
  ];
  int _currentFitIndex = 0;
  BoxFit _currentFit = BoxFit.fill;

  Episode? _nextEpisode;
  String _currentQuality = '720p HD';
  Timer? _liveBufferTimer;
  bool _isBuffering = false;
  bool _isInitialized = false; // ⭐️ متغير جديد لتتبع التهيئة

  @override
  void initState() {
    super.initState();
    _prepareVideo();
    _findNextEpisode();
  }

  void _findNextEpisode() {
    if (widget.currentEpisode != null && widget.seriesEpisodes != null) {
      final currentIndex = widget.seriesEpisodes!.indexWhere(
          (ep) => ep.episodeNumber == widget.currentEpisode!.episodeNumber);
      if (currentIndex != -1 && currentIndex < widget.seriesEpisodes!.length - 1) {
        setState(() {
          _nextEpisode = widget.seriesEpisodes![currentIndex + 1];
        });
      }
    }
  }

  Future<void> _prepareVideo() async {
    try {
      print("🎬 Preparing video: ${widget.title}");
      print("🔗 Video URL: ${widget.videoUrl}");
      
      // ⭐️ تفعيل قفل الشاشة وتوجيه الشاشة أفقياً
      await WakelockPlus.enable();
      await _setLandscape();

      // ⭐️ التحقق من صحة الرابط
      if (widget.videoUrl.isEmpty) {
        throw Exception("رابط الفيديو فارغ");
      }

      if (!widget.videoUrl.startsWith('http')) {
        throw Exception("رابط الفيديو غير صالح: ${widget.videoUrl}");
      }

      // ⭐️ إنشاء مشغل الفيديو
      _controller = VideoPlayerController.network(
        widget.videoUrl,
        httpHeaders: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      );

      // ⭐️ تهيئة المشغل
      await _controller.initialize();
      
      setState(() {
        _isInitialized = true; // ⭐️ تم التهيئة بنجاح
      });

      // ⭐️ التعامل مع البث المباشر والمحتوى المسجل
      if (widget.isLive) {
        _currentSpeed = 1.0;
        _controller.setPlaybackSpeed(1.0);
      } else {
        _totalDuration = _controller.value.duration;
        
        if (widget.startAt != null && widget.startAt! < _controller.value.duration) {
          await _controller.seekTo(widget.startAt!);
          _lastSavedPosition = widget.startAt!;
          print("⏩ Started at position: ${widget.startAt}");
        }
      }

      // ⭐️ بدء التشغيل التلقائي فور التهيئة
      await _controller.play();
      setState(() {
        _isPlaying = true;
        _isLoading = false;
      });
      
      print("✅ Video playing successfully");

      // ⭐️ إضافة مستمع لتغيرات حالة الفيديو
      _controller.addListener(_videoListener);

      _startControlsTimer();
      
      // ⭐️ بدء حفظ التقدم (للحلقات فقط)
      if (!widget.isLive && widget.movie.type == 'episode') {
        _startSaveProgressTimer();
        _startSavingToPreferences();
      }

      // ⭐️ مراقبة البث المباشر
      if (widget.isLive) {
        _startLiveBufferMonitor();
      }

    } catch (e) {
      print("❌ Error preparing video: $e");
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
      
      // ⭐️ إعادة المحاولة التلقائية في حالة الفشل
      if (widget.isLive) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            _retryVideo();
          }
        });
      }
    }
  }

  void _videoListener() {
    if (!mounted) return;
    
    setState(() {
      // ⭐️ مراقبة حالة التحميل للبث المباشر
      if (widget.isLive) {
        _isBuffering = _controller.value.isBuffering;
      }
      
      // ⭐️ اكتشاف اكتمال الفيديو (للمحتوى المسجل)
      if (!widget.isLive && 
          _controller.value.position >= _controller.value.duration &&
          _controller.value.duration > Duration.zero) {
        _isVideoCompleted = true;
        print("🎉 Video completed");
      }
    });
  }

  void _retryVideo() {
    print("🔄 Retrying video playback...");
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    _prepareVideo();
  }

  void _startLiveBufferMonitor() {
    _liveBufferTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_controller.value.isInitialized && _controller.value.isBuffering) {
        print("📡 Live stream buffering...");
      }
    });
  }

  Future<void> _startSavingToPreferences() async {
    if (widget.isLive || widget.movie.type != 'episode') return;
    
    _saveToPrefsTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_controller.value.isInitialized &&
          !_isVideoCompleted &&
          widget.movie.id != null) {
        final prefs = await SharedPreferences.getInstance();
        final pos = _controller.value.position.inMilliseconds;
        final total = _controller.value.duration.inMilliseconds;
        await prefs.setInt('playback_position_${widget.movie.id}', pos);
        await prefs.setInt('playback_duration_${widget.movie.id}', total);
      }
    });
  }

  void _startSaveProgressTimer() {
    if (widget.isLive) return;
    
    _saveProgressTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_controller.value.isInitialized &&
          _controller.value.position != _lastSavedPosition &&
          !_isVideoCompleted) {
        _lastSavedPosition = _controller.value.position;
      }
    });
  }

  Duration _getCurrentProgress() {
    if (widget.isLive || _isVideoCompleted) return Duration.zero;
    
    if (_controller.value.isInitialized) {
      return _controller.value.position;
    }
    return _lastSavedPosition;
  }

  Future<void> _saveFinalPositionToPrefs() async {
    if (widget.isLive || !_controller.value.isInitialized || widget.movie.id == null) {
      return;
    }
    
    if (widget.movie.type != 'episode') return;

    final prefs = await SharedPreferences.getInstance();
    final pos = _controller.value.position.inMilliseconds;
    final total = _controller.value.duration.inMilliseconds;
    await prefs.setInt('playback_position_${widget.movie.id}', pos);
    await prefs.setInt('playback_duration_${widget.movie.id}', total);
    print("💾 Saved position: $pos / $total");
  }

  Future<void> _setLandscape() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _setPortrait() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    print("🛑 Disposing video player");
    
    _controlsTimer?.cancel();
    _saveProgressTimer?.cancel();
    _saveToPrefsTimer?.cancel();
    _liveBufferTimer?.cancel();

    _controller.removeListener(_videoListener);
    
    _saveFinalPositionToPrefs();
    
    _controller.pause();
    _controller.dispose();
    
    WakelockPlus.disable();
    _setPortrait();
    
    super.dispose();
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _resetControlsTimer() {
    if (_showControls) _startControlsTimer();
  }

  void _togglePlayPause() {
    setState(() {
      if (_isPlaying) {
        _controller.pause();
        _controlsTimer?.cancel();
        print("⏸️ Video paused");
      } else {
        _controller.play();
        _startControlsTimer();
        print("▶️ Video playing");
      }
      _isPlaying = !_isPlaying;
    });
  }

  void _skipForward() {
    if (widget.isLive) return;
    
    _resetControlsTimer();
    final pos = _controller.value.position + const Duration(seconds: 10);
    _controller.seekTo(pos);
    print("⏩ Skipped forward 10 seconds");
  }

  void _skipBackward() {
    if (widget.isLive) return;
    
    _resetControlsTimer();
    final pos = _controller.value.position - const Duration(seconds: 10);
    _controller.seekTo(pos < Duration.zero ? Duration.zero : pos);
    print("⏪ Skipped backward 10 seconds");
  }

  String _format(Duration d) {
    d = d < Duration.zero ? Duration.zero : d;
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = d.inHours;
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return hours > 0 ? "$hours:$minutes:$seconds" : "$minutes:$seconds";
  }

  void _setSpeed(double speed) {
    if (widget.isLive) return;
    
    setState(() {
      _currentSpeed = speed;
      _controller.setPlaybackSpeed(speed);
    });
    print("⚡ Speed changed to: ${speed}x");
  }

  void _setQuality(String quality) {
    setState(() {
      _currentQuality = quality;
    });
    _resetControlsTimer();
    print("📺 Quality changed to: $quality");
  }

  void _changePlayerSize() {
    _resetControlsTimer();
    setState(() {
      _currentSizeIndex = (_currentSizeIndex + 1) % _playerSizes.length;
    });
    print("🖼️ Player size changed");
  }

  void _toggleFitMode() {
    _resetControlsTimer();
    setState(() {
      _currentFitIndex = (_currentFitIndex + 1) % _fitModes.length;
      _currentFit = _fitModes[_currentFitIndex]['fit'] as BoxFit;
    });
    print("🔧 Fit mode changed");
  }

  void _onBackPressed() {
    print("🔙 Back button pressed");
    if (widget.isLive) {
      Navigator.pop(context, true);
    } else {
      final currentProgress = _getCurrentProgress();
      _saveFinalPositionToPrefs();
      Navigator.pop(context, currentProgress);
    }
  }

  void _playNextEpisode() {
    if (_nextEpisode != null && widget.onNextEpisode != null) {
      print("➡️ Playing next episode: ${_nextEpisode!.title}");
      widget.onNextEpisode!(_nextEpisode!);
    }
  }

  Widget _buildVideoPlayer() {
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    double scale = _playerSizes[_currentSizeIndex]['scale'] as double;

    return Transform.scale(
      scale: scale,
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: FittedBox(
          fit: _currentFit,
          child: SizedBox(
            width: _controller.value.size.width,
            height: _controller.value.size.height,
            child: VideoPlayer(_controller),
          ),
        ),
      ),
    );
  }

  Widget _buildNextEpisodeButton() {
    if (widget.isLive || _nextEpisode == null || !_isVideoCompleted) {
      return const SizedBox();
    }

    return Positioned(
      bottom: 100,
      right: 20,
      child: GestureDetector(
        onTap: _playNextEpisode,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.skip_next, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'الحلقة التالية',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveIndicator() {
    if (!widget.isLive) return const SizedBox();
    
    return Positioned(
      top: 30,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.5),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'مباشر',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBufferingIndicator() {
    if (!widget.isLive || !_isBuffering) return const SizedBox();
    
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
              const SizedBox(height: 20),
              const Text(
                'جاري تحميل البث المباشر...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'تحقق من جودة اتصال الإنترنت',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    final bool visible = _showControls;
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      child: IgnorePointer(
        ignoring: !visible,
        child: GestureDetector(
          onTap: _resetControlsTimer,
          child: Stack(
            children: [
              // عناصر التحكم المركزية
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (!widget.isLive)
                      _buildControlButton(
                        Icons.replay_10,
                        _skipBackward,
                        size: 42,
                      ),
                    
                    _buildControlButton(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      _togglePlayPause,
                      size: 54,
                    ),
                    
                    if (!widget.isLive)
                      _buildControlButton(
                        Icons.forward_10,
                        _skipForward,
                        size: 42,
                      ),
                  ],
                ),
              ),

              // شريط التقدم والتحكم
              Positioned(
                bottom: 15,
                left: 10,
                right: 10,
                child: Column(
                  children: [
                    if (!widget.isLive)
                      _buildProgressBar(),
                    
                    _buildBottomControls(),
                  ],
                ),
              ),

              // زر الرجوع
              Positioned(
                top: 30,
                left: 20,
                child: _buildBackButton(),
              ),

              // مؤشر البث المباشر
              _buildLiveIndicator(),

              // زر الحلقة التالية
              _buildNextEpisodeButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton(IconData icon, VoidCallback onPressed, {double size = 24}) {
    return IconButton(
      icon: Icon(icon, color: Colors.white, size: size),
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: Colors.black.withOpacity(0.5),
        padding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        thumbColor: Colors.white,
        activeTrackColor: Colors.white,
        inactiveTrackColor: Colors.white.withOpacity(0.3),
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
      ),
      child: Slider(
        min: 0.0,
        max: _controller.value.duration.inMilliseconds.toDouble(),
        value: _controller.value.isInitialized
            ? _controller.value.position.inMilliseconds.toDouble()
            : 0.0,
        onChanged: (value) {
          _controller.seekTo(Duration(milliseconds: value.round()));
        },
        onChangeStart: (_) => _controlsTimer?.cancel(),
        onChangeEnd: (_) => _resetControlsTimer(),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // الوقت الحالي
        Text(
          widget.isLive ? "مباشر" : _format(_controller.value.position),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),

        // أزرار التحكم الإضافية
        Row(
          children: [
            if (!widget.isLive)
              _buildQualityButton(),
            
            _buildSizeButton(),
            
            if (!widget.isLive)
              _buildSpeedButton(),
          ],
        ),

        // المدة الكلية
        Text(
          widget.isLive ? "" : _format(_controller.value.duration),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildQualityButton() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.hd_outlined, color: Colors.white, size: 26),
      color: Colors.black.withOpacity(0.9),
      surfaceTintColor: Colors.transparent,
      onSelected: _setQuality,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: '720p HD',
          child: Text(
            '720p HD',
            style: TextStyle(
              color: _currentQuality == '720p HD' ? Colors.blue : Colors.white,
            ),
          ),
        ),
        PopupMenuItem(
          value: '480p SD',
          child: Text(
            '480p SD',
            style: TextStyle(
              color: _currentQuality == '480p SD' ? Colors.blue : Colors.white,
            ),
          ),
        ),
        PopupMenuItem(
          value: '360p',
          child: Text(
            '360p',
            style: TextStyle(
              color: _currentQuality == '360p' ? Colors.blue : Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSizeButton() {
    return IconButton(
      icon: Icon(
        _playerSizes[_currentSizeIndex]['icon'],
        color: Colors.white,
        size: 26,
      ),
      onPressed: _changePlayerSize,
    );
  }

  Widget _buildSpeedButton() {
    return PopupMenuButton<double>(
      icon: const Icon(Icons.speed, color: Colors.white, size: 26),
      color: Colors.black.withOpacity(0.9),
      surfaceTintColor: Colors.transparent,
      onSelected: (speed) {
        _setSpeed(speed);
        _resetControlsTimer();
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 0.5,
          child: Text(
            '0.5x',
            style: TextStyle(
              color: _currentSpeed == 0.5 ? Colors.blue : Colors.white,
            ),
          ),
        ),
        PopupMenuItem(
          value: 1.0,
          child: Text(
            '1.0x (عادي)',
            style: TextStyle(
              color: _currentSpeed == 1.0 ? Colors.blue : Colors.white,
            ),
          ),
        ),
        PopupMenuItem(
          value: 1.5,
          child: Text(
            '1.5x',
            style: TextStyle(
              color: _currentSpeed == 1.5 ? Colors.blue : Colors.white,
            ),
          ),
        ),
        PopupMenuItem(
          value: 2.0,
          child: Text(
            '2.0x',
            style: TextStyle(
              color: _currentSpeed == 2.0 ? Colors.blue : Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
        onPressed: _onBackPressed,
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 60,
          ),
          const SizedBox(height: 20),
          Text(
            widget.isLive ? "تعذر الاتصال بالبث المباشر" : "تعذر تشغيل الفيديو",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _onBackPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'رجوع',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(width: 15),
              ElevatedButton(
                onPressed: _retryVideo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'إعادة المحاولة',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            widget.isLive ? "جاري الاتصال بالبث المباشر..." : "جاري تحميل الفيديو...",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          if (!widget.isLive)
            Text(
              widget.title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _onBackPressed();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _showControls = !_showControls;
                if (_showControls) {
                  _startControlsTimer();
                } else {
                  _controlsTimer?.cancel();
                }
              });
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                // مشغل الفيديو
                if (_isInitialized && !_isLoading && !_hasError)
                  _buildVideoPlayer(),

                // شاشة التحميل
                if (_isLoading)
                  _buildLoadingScreen(),

                // شاشة الخطأ
                if (_hasError)
                  _buildErrorScreen(),

                // مؤشر تحميل البث المباشر
                if (!_hasError)
                  _buildBufferingIndicator(),

                // عناصر التحكم
                if (!_isLoading && !_hasError)
                  _buildControls(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}