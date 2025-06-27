import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:marquee/marquee.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'dart:io';

// Import the persistent mini player notifier.
import '../widgets/persistent_mini_player.dart';
import '../services/view_tracking_service.dart';

// Import additional screens for bottom navigation.

/// Global audio player instance to persist playback.
final AudioPlayer globalAudioPlayer = AudioPlayer();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await (await AudioSession.instance).configure(
    const AudioSessionConfiguration.music(),
  );
  runApp(const MarsiyaAudioApp());
}

class MarsiyaAudioApp extends StatelessWidget {
  const MarsiyaAudioApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Marsiya Audio Player',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF1A8754),
        secondary: Color(0xFF0D7148),
        surface: Colors.white,
        onPrimary: Colors.white,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A8754)),
        titleTextStyle: GoogleFonts.poppins(
          color: const Color(0xFF1A8754),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A8754),
          foregroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: const Color(0xFF1A8754),
        inactiveTrackColor: Colors.grey.shade200,
        thumbColor: const Color(0xFF1A8754),
        trackHeight: 4.0,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
      ),
    ),
    home: const FullMarsiyaAudioPlay(audioId: "13"),
  );
}

class FullMarsiyaAudioPlay extends StatefulWidget {
  final String audioId;
  final bool autoPlay;
  const FullMarsiyaAudioPlay({
    super.key,
    required this.audioId,
    this.autoPlay = false,
  });
  @override
  State<FullMarsiyaAudioPlay> createState() => _FullMarsiyaAudioPlayState();
}

class _FullMarsiyaAudioPlayState extends State<FullMarsiyaAudioPlay>
    with TickerProviderStateMixin {
  final AudioPlayer _player = globalAudioPlayer;
  late TabController _tabCtrl;
  late AnimationController _animCtrl;

  bool isPlaying = false, isLoading = true, isWaiting = false, isLoop = false;
  String title = "Loading...",
      errorMsg = "",
      author = "",
      dateUploaded = "",
      durationStr = "",
      views = "0";
  String imageUrl =
          'https://algodream.in/admin/uploads/default_art.png', // default image
      audioUrl = '';
  String? pdfUrl;
  Duration _duration = Duration.zero, _position = Duration.zero;
  double? _dragValue;
  late Widget _lyricsTab;

  // Variables for recommendation data.
  List<dynamic> recommendedSongs = [];
  int currentIndex = -1;

  // Flag to indicate if this screen is being replaced (via next/previous navigation)
  bool _isReplaced = false;

  // Flag to track if view has been counted for this audio session
  bool _viewCounted = false;

  @override
  void initState() {
    super.initState();
    // Hide persistent mini-player on this full-screen player.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showPersistentMiniPlayerNotifier.value = false;
    });
    _tabCtrl = TabController(length: 2, vsync: this);
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _lyricsTab = const Center(child: CircularProgressIndicator());
    fetchAudioData().then((_) {
      print("fetchAudioData completed, calling _setupAudio");
      _setupAudio().then((_) {
        print("_setupAudio completed, calling fetchRecommendations");
        fetchRecommendations();
      });
    });
    _player.durationStream.listen((d) {
      print("Duration changed: ${d?.toString() ?? 'null'}");
      if (mounted) setState(() => _duration = d ?? Duration.zero);
    });

    _player.positionStream.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        isPlaying = state.playing;
        if (state.processingState != ProcessingState.loading) isWaiting = false;
        isPlaying ? _animCtrl.forward() : _animCtrl.reverse();
        if (state.processingState == ProcessingState.completed && !isLoop) {
          // When the current audio completes, play the next track automatically.
          _playNext();
        }
      });
    });
  }

  @override
  void dispose() {
    // Only re-enable the mini-player if this screen is not being replaced.
    if (!_isReplaced) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Ensure mini-player visibility is set to true and force a check of active player
        showPersistentMiniPlayerNotifier.value = true;

        // Make sure the mini-player knows we have active content
        if (_player.audioSource != null) {
          showMiniPlayer();
          print("Re-enabling mini-player for Marsiya content");
        }
      });
    }
    _tabCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _setupAudio() async {
    final currentSource = _player.audioSource;
    if (currentSource is UriAudioSource) {
      final currentTag = currentSource.tag as Map<String, dynamic>?;
      if (currentTag?['audioId'] == widget.audioId) {
        print("Audio already loaded for ID: ${widget.audioId}");
        return;
      }
    }

    print("Setting up audio for ID: ${widget.audioId}");
    print("Audio URL: $audioUrl");

    if (audioUrl.isNotEmpty) {
      try {
        // Ensure Noha player is stopped before playing Marsiya
        coordPlayerPlayback(false);

        print("Loading audio source: $audioUrl");
        await _player.setAudioSource(
          AudioSource.uri(
            Uri.parse(audioUrl),
            tag: {'audioId': widget.audioId.toString()},
          ),
        );

        print("Audio source loaded successfully");
        await (await AudioSession.instance).setActive(true);
        print("Audio session activated");

        if (widget.autoPlay) {
          print("Auto-playing audio");
          await _player.play();
          if (mounted) setState(() => isWaiting = true);
        }

        print("Audio setup completed");
      } catch (e) {
        print("Audio setup error: $e");
        if (mounted) setState(() => errorMsg = "Audio Setup Error: $e");
      }
    } else {
      print("Audio URL is empty!");
      if (mounted) setState(() => errorMsg = "No audio URL provided");
    }
  }

  Future<void> fetchAudioData() async {
    try {
      final res = await http.get(
        Uri.parse(
          "https://algodream.in/admin/api/get_marsiya_audio_byId.php?api_key=MOHAMMADASKERYMALIKFROMNOWLARI&audio_id=${widget.audioId}",
        ),
      );
      if (res.statusCode == 200) {
        final jsonData = json.decode(res.body);
        if (jsonData['status'] == 'success') {
          final data = jsonData['data'];
          String tempAuthor =
              data['manual_author']?.toString().isNotEmpty == true
                  ? data['manual_author']
                  : data['author_name']?.toString().isNotEmpty == true
                  ? data['author_name']
                  : data['author_id'] != null
                  ? await fetchAuthorName(data['author_id'])
                  : 'Unknown Artist';
          if (mounted) {
            setState(() {
              title = data['title'] ?? 'Audio';
              author = tempAuthor;
              if ((data['image_url']?.toString() ?? '').isNotEmpty) {
                imageUrl = data['image_url'];
              }
              audioUrl = data['audio_url'] ?? '';
              views = data['views'] != null ? data['views'].toString() : '0';
              pdfUrl = data['pdf_url'] ?? data['lyrics_pdf'];
              dateUploaded =
                  data['uploaded_date'] != null
                      ? (DateTime.tryParse(
                            data['uploaded_date'],
                          )?.let((d) => DateFormat('MMM d, yyyy').format(d)) ??
                          data['uploaded_date'])
                      : '';
              durationStr = data['duration'] ?? '';
              isLoading = false;
            });

            print("Fetched audio data:");
            print("Title: $title");
            print("Author: $author");
            print("Audio URL: $audioUrl");
            print("Duration: $durationStr");

            // Update global variables for the mini player.
            globalTrackTitle = title;
            globalArtistName = author;
            globalImageUrl = imageUrl;

            _lyricsTab = LyricsTab(pdfUrl: pdfUrl);
          }
        } else if (mounted)
          setState(() => errorMsg = "API Error: ${jsonData['message']}");
      } else if (mounted)
        setState(() => errorMsg = "Server Error: ${res.statusCode}");
    } catch (e) {
      if (mounted) setState(() => errorMsg = "Network Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<String> fetchAuthorName(dynamic authorId) async {
    try {
      final res = await http.get(
        Uri.parse(
          "https://algodream.in/admin/api/get_author.php?api_key=MOHAMMADASKERYMALIKFROMNOWLARI&author_id=${authorId.toString()}",
        ),
      );
      if (res.statusCode == 200) {
        final jsonData = json.decode(res.body);
        return jsonData['status'] == 'success'
            ? jsonData['data']['name'] ?? 'Unknown Artist'
            : 'Unknown Artist';
      }
    } catch (_) {}
    return 'Unknown Artist';
  }

  Future<void> fetchRecommendations() async {
    try {
      final res = await http.get(
        Uri.parse(
          "https://algodream.in/admin/api/get_marsiya_audio_recommendation.php?api_key=MOHAMMADASKERYMALIKFROMNOWLARI&audio_id=${widget.audioId}",
        ),
      );
      if (res.statusCode == 200) {
        final jsonData = json.decode(res.body);
        if (jsonData['status'] == 'success') {
          final data = jsonData['data'];
          setState(() {
            recommendedSongs = data;
            currentIndex = recommendedSongs.indexWhere(
              (song) => song['id'].toString() == widget.audioId,
            );
          });
        }
      }
    } catch (e) {
      // Handle recommendation errors silently.
    }
  }

  Future<void> _togglePlayPause() async {
    print("Toggle play/pause called. Current state: isPlaying=$isPlaying");
    print("Player state: ${_player.processingState}");
    print("Audio source loaded: ${_player.audioSource != null}");

    try {
      await (await AudioSession.instance).setActive(true);
      if (isPlaying) {
        print("Pausing audio");
        await _player.pause();
        if (mounted) setState(() => isWaiting = false);
      } else {
        print("Starting audio playback");
        // Stop any playing noha audio before playing marsiya
        coordPlayerPlayback(false);

        if (_player.processingState == ProcessingState.idle) {
          print("Player is idle, setting up audio first");
          await _setupAudio();
        }

        print("Calling player.play()");
        await _player.play();
        if (mounted) setState(() => isWaiting = true);
        print("Play() called successfully");

        // ✅ Track view count when audio starts playing (only once per session)
        if (!_viewCounted && widget.audioId.isNotEmpty) {
          _viewCounted = true;
          _trackMarsiyaView();
        }
      }
    } catch (e) {
      print("Playback error: $e");
      if (mounted) setState(() => errorMsg = "Playback error: $e");
    }
  }

  // Track Marsiya view using the ViewTrackingService
  Future<void> _trackMarsiyaView() async {
    try {
      final result = await ViewTrackingService.incrementMarsiyaView(
        widget.audioId,
      );
      if (result['success']) {
        print(
          '✅ Marsiya view tracked successfully: ${result['views']} total views',
        );
        // Update the displayed view count with the new count from server
        if (mounted) {
          setState(() {
            views = ViewTrackingService.formatViewCount(result['views']);
          });
        }
      } else {
        print('❌ Failed to track Marsiya view: ${result['message']}');
      }
    } catch (e) {
      print('❌ Error tracking Marsiya view: $e');
    }
  }

  Future<void> _seekForward() async =>
      await _player.seek(_position + const Duration(seconds: 10));
  Future<void> _seekBackward() async =>
      await _player.seek(_position - const Duration(seconds: 10));
  String _formatDuration(Duration d) =>
      "${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}";

  Future<void> _playNext() async {
    if (recommendedSongs.isNotEmpty) {
      int newIndex = currentIndex + 1;
      if (newIndex >= recommendedSongs.length) {
        newIndex = 0; // loop back to the first track.
      }
      final newAudioId = recommendedSongs[newIndex]['id'].toString();
      // Mark this screen as being replaced so mini-player is not shown on dispose.
      _isReplaced = true;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => FullMarsiyaAudioPlay(audioId: newAudioId),
        ),
      );
    }
  }

  Future<void> _playPrevious() async {
    if (recommendedSongs.isNotEmpty) {
      int newIndex = currentIndex - 1;
      if (newIndex < 0) {
        newIndex = recommendedSongs.length - 1; // loop to the last track.
      }
      final newAudioId = recommendedSongs[newIndex]['id'].toString();
      _isReplaced = true;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => FullMarsiyaAudioPlay(audioId: newAudioId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sliderMax =
        _duration.inSeconds > 0 ? _duration.inSeconds.toDouble() : 1.0;
    final sliderValue = (_dragValue ?? _position.inSeconds.toDouble()).clamp(
      0.0,
      sliderMax,
    );
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child:
            isLoading
                ? Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                )
                : errorMsg.isNotEmpty
                ? _errorView()
                : Column(
                  children: [
                    _topNavBar(),
                    _customTabBar(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabCtrl,
                        children: [_audioPlayerTab(context), _lyricsTab],
                      ),
                    ),
                    _playerControls(context, sliderValue, sliderMax),
                  ],
                ),
      ),
    );
  }

  Widget _topNavBar() => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 10,
          spreadRadius: 1,
        ),
      ],
    ),
    padding: const EdgeInsets.only(left: 8, top: 8, bottom: 4),
    child: Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        icon: const Icon(IconlyLight.arrow_left_2, color: Color(0xFF1A8754)),
        onPressed: () => Navigator.pop(context),
      ),
    ),
  );

  Widget _customTabBar() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
    height: 48,
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(25),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: TabBar(
        controller: _tabCtrl,
        indicator: BoxDecoration(
          color: const Color(0xFF1A8754),
          borderRadius: BorderRadius.circular(25),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade800,
        tabs: [
          Tab(
            icon: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(IconlyLight.voice, size: 18),
                const SizedBox(width: 8),
                Text(
                  "Audio",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Tab(
            icon: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(IconlyLight.document, size: 18),
                const SizedBox(width: 8),
                Text(
                  "Lyrics",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _errorView() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            IconlyLight.danger,
            color: Theme.of(context).colorScheme.primary,
            size: 60,
          ),
          const SizedBox(height: 16),
          Text(
            "Something went wrong",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            errorMsg,
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              setState(() {
                isLoading = true;
                errorMsg = "";
              });
              await fetchAudioData();
              await _setupAudio();
            },
            icon: const Icon(Icons.refresh),
            label: Text(
              "Try Again",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _audioPlayerTab(BuildContext context) => Column(
    children: [
      const SizedBox(height: 16),
      Hero(
        tag: 'marsiya_art_${widget.audioId}',
        child: Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A8754).withOpacity(0.2),
                blurRadius: 25,
                spreadRadius: 4,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Container(
                            color: Colors.grey.shade100,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF1A8754),
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => Container(
                            color: Colors.grey.shade100,
                            child: const Icon(
                              IconlyLight.image,
                              size: 50,
                              color: Colors.black54,
                            ),
                          ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        IconlyLight.voice,
                        size: 16,
                        color: const Color(0xFF1A8754),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Marsiya",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A8754),
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
      const Spacer(),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _infoChip(IconlyLight.show, "${views.toString()} views"),
            _infoChip(IconlyLight.calendar, dateUploaded),
          ],
        ),
      ),
      const SizedBox(height: 16),
    ],
  );

  Widget _infoChip(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF1A8754)),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );

  Widget _playerControls(
    BuildContext context,
    double sliderValue,
    double sliderMax,
  ) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 15,
          spreadRadius: 3,
          offset: const Offset(0, -3),
        ),
      ],
    ),
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _titleAuthor(),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            activeTrackColor: const Color(0xFF1A8754),
            inactiveTrackColor: Colors.grey.shade200,
            thumbColor: const Color(0xFF1A8754),
            overlayColor: const Color(0xFF1A8754).withOpacity(0.2),
          ),
          child: Column(
            children: [
              Slider(
                value: sliderValue,
                min: 0.0,
                max: sliderMax,
                onChanged: (v) => setState(() => _dragValue = v),
                onChangeEnd: (v) async {
                  await _player.seek(Duration(seconds: v.toInt()));
                  setState(() => _dragValue = null);
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _formatDuration(_duration),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ctrlBtn(IconlyLight.arrow_left_2, _playPrevious, size: 24),
            _ctrlBtn(IconlyLight.arrow_left, _seekBackward, size: 24),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A8754), Color(0xFF0D7148)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A8754).withOpacity(0.25),
                    blurRadius: 12,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child:
                  isWaiting
                      ? const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                      : Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: _togglePlayPause,
                          child: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
            ),
            _ctrlBtn(IconlyLight.arrow_right, _seekForward, size: 24),
            _ctrlBtn(IconlyLight.arrow_right_2, _playNext, size: 24),
          ],
        ),
      ],
    ),
  );

  Widget _titleAuthor() => Container(
    padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
    margin: const EdgeInsets.only(bottom: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title.length > 30
            ? SizedBox(
              height: 28,
              child: Marquee(
                text: title,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                scrollAxis: Axis.horizontal,
                blankSpace: 50.0,
                velocity: 30.0,
                pauseAfterRound: const Duration(seconds: 2),
                showFadingOnlyWhenScrolling: true,
                fadingEdgeStartFraction: 0.1,
                fadingEdgeEndFraction: 0.1,
                startPadding: 10.0,
              ),
            )
            : Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "zakir:",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                author.isNotEmpty ? author : "Unknown Artist",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF1A8754),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _ctrlBtn(
    IconData icon,
    VoidCallback onPressed, {
    required double size,
    Color? color,
  }) => Container(
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: IconButton(
      icon: Icon(icon, color: color ?? const Color(0xFF1A8754), size: size),
      onPressed: onPressed,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(),
    ),
  );
}

class LyricsTab extends StatefulWidget {
  final String? pdfUrl;
  const LyricsTab({super.key, this.pdfUrl});
  @override
  State<LyricsTab> createState() => _LyricsTabState();
}

class _LyricsTabState extends State<LyricsTab>
    with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;
  String? _localPdfPath;

  @override
  void initState() {
    super.initState();
    if (widget.pdfUrl != null) {
      _loadPdf(widget.pdfUrl!);
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadPdf(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      final bytes = response.bodyBytes;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/lyrics.pdf');
      await file.writeAsBytes(bytes);
      setState(() {
        _localPdfPath = file.path;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading PDF: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.pdfUrl == null) {
      return _noPdf();
    }

    return Stack(
      children: [
        AnimatedOpacity(
          opacity: _isLoading ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 500),
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child:
                  _localPdfPath != null
                      ? PDFView(
                        filePath: _localPdfPath!,
                        enableSwipe: true,
                        swipeHorizontal: false,
                        autoSpacing: true,
                        pageFling: true,
                        onRender: (_) => setState(() => _isLoading = false),
                        onError: (error) {
                          print(error);
                          setState(() => _isLoading = false);
                        },
                      )
                      : Container(color: Colors.white),
            ),
          ),
        ),
        if (_isLoading) const Center(child: CircularProgressIndicator()),
        Positioned(
          top: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                if (_localPdfPath != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (_) => FullScreenPdfViewer(pdfPath: _localPdfPath!),
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fullscreen,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _noPdf() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      children: [
        const SizedBox(height: 20),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            Icons.lyrics_outlined,
            size: 50,
            color: Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "No Lyrics Available",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 30),
          child: Text(
            "We couldn't find lyrics for this audio. You can still enjoy listening to the beautiful recitation.",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ),
  );
}

class FullScreenPdfViewer extends StatelessWidget {
  final String pdfPath;

  const FullScreenPdfViewer({super.key, required this.pdfPath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: PDFView(
        filePath: pdfPath,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
      ),
    );
  }
}

extension LetExtension on DateTime {
  T let<T>(T Function(DateTime) op) => op(this);
}
