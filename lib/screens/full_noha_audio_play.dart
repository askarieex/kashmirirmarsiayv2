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
import 'dart:io';
import 'package:share_plus/share_plus.dart';

// Import the persistent mini player notifier.
import '../widgets/persistent_mini_player.dart';

// Import additional screens for bottom navigation.
import 'home_screen.dart';
import 'marsiya_screen.dart';

/// Global audio player instance to persist playback.
final AudioPlayer globalNohaPlayer = AudioPlayer();

// Global variables to hold current track info for the mini player
String globalNohaTitle = "Unknown Noha";
String globalNohaArtistName = "Unknown Artist";
String globalNohaImageUrl =
    'https://algodream.in/admin/uploads/default_art.png';

class FullNohaAudioPlay extends StatefulWidget {
  final String nohaId;
  final bool autoPlay;
  const FullNohaAudioPlay({
    Key? key,
    required this.nohaId,
    this.autoPlay = false,
  }) : super(key: key);
  @override
  State<FullNohaAudioPlay> createState() => _FullNohaAudioPlayState();
}

class _FullNohaAudioPlayState extends State<FullNohaAudioPlay>
    with TickerProviderStateMixin {
  final AudioPlayer _player = globalNohaPlayer;
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
    fetchNohaData().then((_) {
      _setupAudio();
      fetchRecommendations();
    });
    _player.durationStream.listen(
      (d) => mounted ? setState(() => _duration = d ?? Duration.zero) : null,
    );
    _player.positionStream.listen(
      (p) => mounted ? setState(() => _position = p) : null,
    );
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
          print("Re-enabling mini-player for Noha content");
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
      if (currentTag?['nohaId'] == widget.nohaId) return;
    }
    if (audioUrl.isNotEmpty) {
      try {
        // Stop any playing marsiya audio before playing noha
        coordPlayerPlayback(true);

        await _player.setAudioSource(
          AudioSource.uri(
            Uri.parse(audioUrl),
            tag: {'nohaId': widget.nohaId.toString()},
          ),
        );
        await (await AudioSession.instance).setActive(true);
        if (widget.autoPlay) {
          await _player.play();
          if (mounted) setState(() => isWaiting = true);
        }
      } catch (e) {
        if (mounted) setState(() => errorMsg = "Audio Setup Error: $e");
      }
    }
  }

  Future<void> fetchNohaData() async {
    try {
      final res = await http.get(
        Uri.parse(
          "https://algodream.in/admin/api/get_noha_audio_byId.php?api_key=MOHAMMADASKERYMALIKFROMNOWLARI&noha_id=${widget.nohaId}",
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
              if ((data['image_url']?.toString() ?? '').isNotEmpty)
                imageUrl = data['image_url'];
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

            // Update global variables for the mini player.
            globalNohaTitle = title;
            globalNohaArtistName = author;
            globalNohaImageUrl = imageUrl;

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
          "https://algodream.in/admin/api/get_noha_audio_recommendation.php?api_key=MOHAMMADASKERYMALIKFROMNOWLARI&noha_id=${widget.nohaId}",
        ),
      );
      if (res.statusCode == 200) {
        final jsonData = json.decode(res.body);
        if (jsonData['status'] == 'success') {
          final data = jsonData['data'];
          setState(() {
            recommendedSongs = data;
            currentIndex = recommendedSongs.indexWhere(
              (song) => song['id'].toString() == widget.nohaId,
            );
          });
        }
      }
    } catch (e) {
      // Handle recommendation errors silently.
    }
  }

  Future<void> _togglePlayPause() async {
    try {
      await (await AudioSession.instance).setActive(true);
      if (isPlaying) {
        await _player.pause();
        if (mounted) setState(() => isWaiting = false);
      } else {
        // Stop any playing marsiya audio before playing noha
        coordPlayerPlayback(true);

        if (_player.processingState == ProcessingState.idle)
          await _setupAudio();
        await _player.play();
        if (mounted) setState(() => isWaiting = true);
      }
    } catch (e) {
      if (mounted) setState(() => errorMsg = "Playback error: $e");
    }
  }

  Future<void> _seekForward() async =>
      await _player.seek(_position + const Duration(seconds: 10));
  Future<void> _seekBackward() async =>
      await _player.seek(_position - const Duration(seconds: 10));
  void _toggleLoop() => setState(() => isLoop = !isLoop);
  String _formatDuration(Duration d) =>
      "${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}";

  Future<void> _playNext() async {
    if (recommendedSongs.isNotEmpty) {
      int newIndex = currentIndex + 1;
      if (newIndex >= recommendedSongs.length) {
        newIndex = 0; // loop back to the first track.
      }
      final newNohaId = recommendedSongs[newIndex]['id'].toString();
      // Mark this screen as being replaced so mini-player is not shown on dispose.
      _isReplaced = true;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => FullNohaAudioPlay(nohaId: newNohaId)),
      );
    }
  }

  Future<void> _playPrevious() async {
    if (recommendedSongs.isNotEmpty) {
      int newIndex = currentIndex - 1;
      if (newIndex < 0) {
        newIndex = recommendedSongs.length - 1; // loop to the last track.
      }
      final newNohaId = recommendedSongs[newIndex]['id'].toString();
      _isReplaced = true;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => FullNohaAudioPlay(nohaId: newNohaId)),
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
        icon: Icon(
          Icons.arrow_back,
          color: Theme.of(context).colorScheme.primary,
        ),
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
        tabs: const [
          Tab(
            icon: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.music_note, size: 18),
                SizedBox(width: 8),
                Text(
                  "Audio",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Tab(
            icon: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description, size: 18),
                SizedBox(width: 8),
                Text(
                  "Lyrics",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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
            Icons.error_outline,
            color: Theme.of(context).colorScheme.primary,
            size: 60,
          ),
          const SizedBox(height: 16),
          const Text(
            "Something went wrong",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            errorMsg,
            style: const TextStyle(color: Colors.grey, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              setState(() {
                isLoading = true;
                errorMsg = "";
              });
              await fetchNohaData();
              await _setupAudio();
            },
            icon: const Icon(Icons.refresh),
            label: const Text("Try Again"),
          ),
        ],
      ),
    ),
  );

  Widget _audioPlayerTab(BuildContext context) => Column(
    children: [
      const SizedBox(height: 20),
      Container(
        width: 240,
        height: 240,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A8754).withOpacity(0.15),
              blurRadius: 25,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            width: 240,
            height: 240,
            fit: BoxFit.cover,
            placeholder:
                (context, url) =>
                    const Center(child: CircularProgressIndicator()),
            errorWidget:
                (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.image_not_supported,
                    size: 60,
                    color: Colors.black54,
                  ),
                ),
          ),
        ),
      ),
      const Spacer(),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _infoChip(Icons.visibility_outlined, "${views.toString()} views"),
            _infoChip(Icons.calendar_today_outlined, dateUploaded),
          ],
        ),
      ),
      const SizedBox(height: 20),
    ],
  );

  Widget _infoChip(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
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
    color: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _titleAuthor(),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 5,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            activeTrackColor: Theme.of(context).colorScheme.primary,
            inactiveTrackColor: Colors.grey.shade200,
            thumbColor: Theme.of(context).colorScheme.primary,
            overlayColor: Theme.of(
              context,
            ).colorScheme.primary.withOpacity(0.2),
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _formatDuration(_duration),
                      style: TextStyle(
                        fontSize: 12,
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
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Skip Previous Button
            _ctrlBtn(Icons.skip_previous, _playPrevious, size: 26),
            // Seek Backward Button
            _ctrlBtn(Icons.replay_10_rounded, _seekBackward, size: 26),
            // Play/Pause Button
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A8754).withOpacity(0.3),
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
            // Seek Forward Button
            _ctrlBtn(Icons.forward_10_rounded, _seekForward, size: 26),
            // Skip Next Button
            _ctrlBtn(Icons.skip_next, _playNext, size: 26),
          ],
        ),
        const SizedBox(height: 12),
      ],
    ),
  );

  Widget _ctrlBtn(IconData icon, VoidCallback onPressed, {double size = 24}) =>
      Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(30),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Icon(
              icon,
              size: size,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );

  Widget _titleAuthor() => Container(
    padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
    margin: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title.length > 30
            ? SizedBox(
              height: 28,
              child: Marquee(
                text: title,
                style: const TextStyle(
                  fontSize: 22,
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
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        const SizedBox(height: 4),
        Text(
          author,
          style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

// Extension to make DateFormat easier
extension DateTimeExtension on DateTime {
  static DateTime? tryParse(String? input) {
    if (input == null || input.isEmpty) return null;
    try {
      return DateTime.parse(input);
    } catch (_) {
      return null;
    }
  }

  T let<T>(T Function(DateTime d) block) => block(this);
}

/// Lyrics tab to display PDF content
class LyricsTab extends StatefulWidget {
  final String? pdfUrl;

  const LyricsTab({Key? key, this.pdfUrl}) : super(key: key);

  @override
  State<LyricsTab> createState() => _LyricsTabState();
}

class _LyricsTabState extends State<LyricsTab> {
  bool _isLoading = true;
  String? _localPath;
  String _errorMsg = '';
  bool _hasPdf = false;

  @override
  void initState() {
    super.initState();
    _checkPdf();
  }

  Future<void> _checkPdf() async {
    if (widget.pdfUrl == null || widget.pdfUrl!.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasPdf = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final cachedDir = await getTemporaryDirectory();
      final String fileId = widget.pdfUrl!
          .split('/')
          .last
          .replaceAll(RegExp(r'[^\w]'), '_');
      final String filePath = '${cachedDir.path}/$fileId.pdf';
      final file = File(filePath);

      if (await file.exists()) {
        setState(() {
          _localPath = filePath;
          _isLoading = false;
          _hasPdf = true;
        });
        return;
      }

      // File doesn't exist, download it.
      final response = await http.get(Uri.parse(widget.pdfUrl!));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        setState(() {
          _localPath = filePath;
          _isLoading = false;
          _hasPdf = true;
        });
      } else {
        setState(() {
          _errorMsg = 'Failed to download lyrics: ${response.statusCode}';
          _isLoading = false;
          _hasPdf = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = 'Error: $e';
        _isLoading = false;
        _hasPdf = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasPdf) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No lyrics available for this noha',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            if (_errorMsg.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _errorMsg,
                style: TextStyle(fontSize: 14, color: Colors.red.shade300),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _checkPdf,
              icon: const Icon(Icons.refresh),
              label: const Text("Try Again"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A8754),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: const Color(0xFF1A8754),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Noha Lyrics',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white, size: 20),
                  onPressed: () async {
                    try {
                      await Share.shareFiles([
                        _localPath!,
                      ], text: 'Check out these noha lyrics!');
                    } catch (e) {
                      // Ignore errors
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: PDFView(
              filePath: _localPath!,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageFling: true,
              onError: (error) {
                setState(() {
                  _errorMsg = error.toString();
                  _hasPdf = false;
                });
              },
              onRender: (_) {
                setState(() => _isLoading = false);
              },
              onViewCreated: (pdfViewController) {
                // Controller can be stored for further manipulation if needed
              },
            ),
          ),
        ],
      ),
    );
  }
}
