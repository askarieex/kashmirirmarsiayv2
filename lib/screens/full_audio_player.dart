import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:marquee/marquee.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

// Import the persistent mini player notifier.
import '../widgets/persistent_mini_player.dart';

// Content type enum to determine which content is playing
enum ContentType { marsiya, noha }

/// Global audio player instance to persist playback.
final AudioPlayer globalAudioPlayer = AudioPlayer();

// Global variables for Noha player
String globalNohaTitle = '';
String globalNohaArtistName = '';
String globalNohaImageUrl = '';

class FullAudioPlayer extends StatefulWidget {
  final String audioId;
  final bool autoPlay;
  final ContentType contentType;
  final Map<String, dynamic>? audioData; // Optional pre-loaded data

  const FullAudioPlayer({
    Key? key,
    required this.audioId,
    this.autoPlay = false,
    required this.contentType,
    this.audioData,
  }) : super(key: key);

  @override
  State<FullAudioPlayer> createState() => _FullAudioPlayerState();
}

class _FullAudioPlayerState extends State<FullAudioPlayer>
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
  List<dynamic> recommendedAudios = [];
  int currentIndex = -1;

  // Flag to indicate if this screen is being replaced (via next/previous navigation)
  bool _isReplaced = false;

  // Add a gradient background
  final List<Color> _gradientColors = [
    const Color(0xFF1A8754), // Primary green
    const Color(0xFF106B42), // Darker green
  ];

  // Function to handle tab changes
  void _handleTabChange() {
    // If tab index is 1 (Lyrics tab) and pdfUrl is not null
    if (_tabCtrl.index == 1 && pdfUrl != null) {
      print("Tab changed to Lyrics, triggering PDF load");
      // Force reload the LyricsTab widget to ensure PDF is loaded
      setState(() {
        _lyricsTab = LyricsTab(
          key: UniqueKey(), // Use a unique key to force widget rebuild
          pdfUrl: pdfUrl,
        );
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Hide persistent mini-player on this full-screen player.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showPersistentMiniPlayerNotifier.value = false;
    });
    _tabCtrl = TabController(length: 2, vsync: this);

    // Add a listener to load PDF when Lyrics tab is clicked
    _tabCtrl.addListener(_handleTabChange);

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _lyricsTab = const Center(child: CircularProgressIndicator());

    // If we have pre-loaded data, use it
    if (widget.audioData != null) {
      _setAudioDataFromMap(widget.audioData!);
      _setupAudio();
      fetchRecommendations();
    } else {
      fetchAudioData().then((_) {
        _setupAudio();
        fetchRecommendations();
      });
    }

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
        showPersistentMiniPlayerNotifier.value = true;
      });
    }
    _tabCtrl.removeListener(_handleTabChange); // Remove listener
    _tabCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _setupAudio() async {
    final currentSource = _player.audioSource;
    if (currentSource is UriAudioSource) {
      final currentTag = currentSource.tag as Map<String, dynamic>?;
      if (currentTag?['audioId'] == widget.audioId &&
          currentTag?['contentType'] == widget.contentType.toString()) {
        return;
      }
    }
    if (audioUrl.isNotEmpty) {
      try {
        await _player.setAudioSource(
          AudioSource.uri(
            Uri.parse(audioUrl),
            tag: {
              'audioId': widget.audioId,
              'contentType': widget.contentType.toString(),
            },
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

  // Set audio data from a pre-loaded map
  void _setAudioDataFromMap(Map<String, dynamic> data) {
    // Determine author name using the appropriate field with fallbacks
    String authorName = '';

    // Check for non-empty author_name first
    if (data['author_name']?.toString().isNotEmpty == true) {
      authorName = data['author_name'];
      print("Using author_name: $authorName");
    }
    // Then check for manual_author
    else if (data['manual_author']?.toString().isNotEmpty == true) {
      authorName = data['manual_author'];
      print("Using manual_author: $authorName");
    }
    // If we have an author_id, fetch the name
    else if (data['author_id']?.toString().isNotEmpty == true) {
      // We'll set a default for now, but this should have been fetched earlier
      authorName = 'Unknown Artist';
      print("Missing author name but have ID: ${data['author_id']}");

      // Start an async operation to update the author later
      fetchAuthorName(data['author_id']).then((name) {
        if (mounted && name != 'Unknown Artist') {
          setState(() {
            author = name;

            // Update globals
            if (widget.contentType == ContentType.marsiya) {
              globalArtistName = name;
            } else {
              globalNohaArtistName = name;
            }
          });
        }
      });
    } else {
      // Default fallback
      authorName =
          widget.contentType == ContentType.marsiya
              ? 'Unknown Artist'
              : 'Unknown Reciter';
      print("Using default author name");
    }

    setState(() {
      title = data['title'] ?? 'Audio';
      author = authorName;
      if ((data['image_url']?.toString() ?? '').isNotEmpty) {
        imageUrl = data['image_url'];
      }
      audioUrl = data['audio_url'] ?? '';
      views = data['views'] ?? '0';

      // Handle PDF URL - check both fields and use the first non-empty one
      if ((data['lyrics_pdf']?.toString() ?? '').isNotEmpty) {
        pdfUrl = data['lyrics_pdf'];
        print("Found PDF URL from lyrics_pdf: $pdfUrl");
      } else if ((data['pdf_url']?.toString() ?? '').isNotEmpty) {
        pdfUrl = data['pdf_url'];
        print("Found PDF URL from pdf_url: $pdfUrl");
      } else {
        pdfUrl = null;
        print("No PDF URL found in data");
      }

      // Format date if available
      if (data['uploaded_date'] != null) {
        try {
          final date = DateTime.parse(data['uploaded_date']);
          dateUploaded = DateFormat('MMM d, yyyy').format(date);
        } catch (e) {
          dateUploaded = data['uploaded_date'] ?? '';
        }
      } else {
        dateUploaded = '';
      }

      durationStr = data['duration'] ?? '';
      isLoading = false;
    });

    // Update global variables for the mini player
    if (widget.contentType == ContentType.marsiya) {
      globalTrackTitle = title;
      globalArtistName = author;
      globalImageUrl = imageUrl;
    } else {
      globalNohaTitle = title;
      globalNohaArtistName = author;
      globalNohaImageUrl = imageUrl;
    }

    _lyricsTab = LyricsTab(pdfUrl: pdfUrl);

    // Fetch recommendations immediately after setting audio data
    fetchRecommendations();
  }

  Future<void> fetchAudioData() async {
    String apiUrl =
        widget.contentType == ContentType.marsiya
            ? "https://algodream.in/admin/api/get_marsiya_audio_byId.php?api_key=MOHAMMADASKERYMALIKFROMNOWLARI&audio_id=${widget.audioId}"
            : "https://algodream.in/admin/api/get_noha_audio_byId.php?api_key=MOHAMMADASKERYMALIKFROMNOWLARI&noha_id=${widget.audioId}";

    print("Fetching audio data from: $apiUrl");

    try {
      final res = await http.get(Uri.parse(apiUrl));
      print("Audio data API response status: ${res.statusCode}");

      if (res.statusCode == 200) {
        final jsonData = json.decode(res.body);
        print(
          "Audio data API response: ${res.body.substring(0, min(100, res.body.length))}...",
        );

        if (jsonData['status'] == 'success') {
          final data =
              widget.contentType == ContentType.marsiya
                  ? jsonData['data']
                  : jsonData['data'][0];

          // Better handling of author information
          if (widget.contentType == ContentType.marsiya) {
            String tempAuthor = '';

            // Try manual_author first if it exists and is not empty
            if (data['manual_author']?.toString().isNotEmpty == true) {
              tempAuthor = data['manual_author'];
              print("Using manual_author: $tempAuthor");
            }
            // Then try author_name if manual_author is empty
            else if (data['author_name']?.toString().isNotEmpty == true) {
              tempAuthor = data['author_name'];
              print("Using author_name: $tempAuthor");
            }
            // Finally, try to fetch author by ID if available
            else if (data['author_id']?.toString().isNotEmpty == true &&
                data['author_id'] != "0") {
              print("Fetching author by ID: ${data['author_id']}");
              tempAuthor = await fetchAuthorName(data['author_id']);
              print("Fetched author by ID: $tempAuthor");

              // Store the fetched author name in the data
              data['author_name'] = tempAuthor;
            }
            // If all else fails, use default
            else {
              tempAuthor = 'Unknown Artist';
              print("Using default author name");
            }

            data['author_name'] = tempAuthor;
          } else {
            // For Noha, ensure we have an author name
            if (data['author_name']?.toString().isEmpty == true) {
              if (data['manual_author']?.toString().isNotEmpty == true) {
                data['author_name'] = data['manual_author'];
              } else if (data['author_id']?.toString().isNotEmpty == true &&
                  data['author_id'] != "0") {
                data['author_name'] = await fetchAuthorName(data['author_id']);
              } else {
                data['author_name'] = 'Unknown Reciter';
              }
            }
          }

          if (mounted) {
            _setAudioDataFromMap(data);
          }
        } else if (mounted) {
          setState(() => errorMsg = "API Error: ${jsonData['message']}");
        }
      } else if (mounted) {
        setState(() => errorMsg = "Server Error: ${res.statusCode}");
      }
    } catch (e) {
      print("Error fetching audio data: $e");
      if (mounted) setState(() => errorMsg = "Network Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<String> fetchAuthorName(String authorId) async {
    try {
      print("Fetching author with ID: $authorId");
      final res = await http.get(
        Uri.parse(
          "https://algodream.in/admin/api/get_author.php?api_key=MOHAMMADASKERYMALIKFROMNOWLARI&author_id=$authorId",
        ),
      );
      print("Author API response status: ${res.statusCode}");
      print("Author API response: ${res.body}");

      if (res.statusCode == 200) {
        final jsonData = json.decode(res.body);
        if (jsonData['status'] == 'success' && jsonData['data'] != null) {
          final authorName = jsonData['data']['name'];
          print("Found author name: $authorName");
          return authorName ?? 'Unknown Artist';
        }
      }
    } catch (e) {
      print("Error fetching author data: $e");
    }
    return 'Unknown Artist';
  }

  Future<void> fetchRecommendations() async {
    // Define the audio type parameter based on content type
    final audioType =
        widget.contentType == ContentType.marsiya ? "marsiya" : "noha";
    final fullAudioId = widget.audioId.toString().trim();

    print("Fetching recommendations for $audioType ID: $fullAudioId");

    try {
      // Use the exact URL format from the example response
      String apiUrl =
          "https://algodream.in/admin/api/get_audio_recommendations.php?%20"
          "audio_type=$audioType%20"
          "&audio_id=$fullAudioId%20"
          "&api_key=MOHAMMADASKERYMALIKFROMNOWLARI";

      print("Trying recommendation API: $apiUrl");

      final res = await http.get(Uri.parse(apiUrl));
      print("API Response Status: ${res.statusCode}");

      if (res.statusCode == 200) {
        final String responseBody = res.body;
        print("Response body: $responseBody");

        try {
          final jsonData = json.decode(responseBody);

          if (jsonData['status'] == 'success' && jsonData['data'] != null) {
            final data = jsonData['data'];

            if (data is List && data.isNotEmpty) {
              print("Found ${data.length} recommendations");

              List<Map<String, dynamic>> processedData = [];

              for (var item in data) {
                if (item is Map<String, dynamic>) {
                  // Determine author name using the appropriate field with fallbacks
                  String authorName = '';

                  // Check for author_name first
                  if (item['author_name']?.toString().isNotEmpty == true) {
                    authorName = item['author_name'];
                  }
                  // Then check for manual_author
                  else if (item['manual_author']?.toString().isNotEmpty ==
                      true) {
                    authorName = item['manual_author'];
                  }
                  // Try to fetch author by ID if available
                  else if (item['author_id']?.toString().isNotEmpty == true &&
                      item['author_id'] != "0") {
                    // We'll try to fetch author asynchronously in a moment
                    authorName =
                        widget.contentType == ContentType.marsiya
                            ? 'Unknown Artist'
                            : 'Unknown Reciter';
                  }
                  // Default fallback
                  else {
                    authorName =
                        widget.contentType == ContentType.marsiya
                            ? 'Unknown Artist'
                            : 'Unknown Reciter';
                  }

                  // Make sure all fields are present
                  final processedItem = {
                    'id': item['id']?.toString() ?? '',
                    'title': item['title']?.toString() ?? 'Unknown Title',
                    'author_name': authorName,
                    'author_id': item['author_id']?.toString() ?? '',
                    'image_url':
                        item['image_url']?.toString() ??
                        'https://algodream.in/admin/uploads/default_art.png',
                  };
                  processedData.add(processedItem);
                }
              }

              if (processedData.isNotEmpty) {
                setState(() {
                  recommendedAudios = processedData;
                  currentIndex = recommendedAudios.indexWhere(
                    (audio) => audio['id']?.toString() == fullAudioId,
                  );
                });

                // Now try to fetch any missing author names asynchronously
                for (int i = 0; i < processedData.length; i++) {
                  final item = processedData[i];
                  if ((item['author_name'] == 'Unknown Artist' ||
                          item['author_name'] == 'Unknown Reciter') &&
                      item['author_id']?.toString().isNotEmpty == true &&
                      item['author_id'] != "0") {
                    // Use a local function to capture the index
                    void updateAuthorName(int index) async {
                      final authorName = await fetchAuthorName(
                        item['author_id'],
                      );
                      if (mounted &&
                          authorName != 'Unknown Artist' &&
                          index < recommendedAudios.length) {
                        setState(() {
                          recommendedAudios[index]['author_name'] = authorName;
                        });
                      }
                    }

                    updateAuthorName(i);
                  }
                }

                print(
                  "Successfully loaded ${processedData.length} recommendations",
                );
                return;
              }
            }
          }

          print(
            "API didn't return valid data structure. Using empty recommendations.",
          );
          setState(() => recommendedAudios = []);
        } catch (parseError) {
          print("Error parsing JSON response: $parseError");
          setState(() => recommendedAudios = []);
        }
      } else {
        print("Bad response from API: ${res.statusCode}");
        setState(() => recommendedAudios = []);
      }
    } catch (e) {
      print("Error accessing recommendation API: $e");
      setState(() => recommendedAudios = []);
    }
  }

  Future<void> _togglePlayPause() async {
    try {
      await (await AudioSession.instance).setActive(true);
      if (isPlaying) {
        await _player.pause();
        if (mounted) setState(() => isWaiting = false);
      } else {
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
    if (recommendedAudios.isNotEmpty) {
      int newIndex = currentIndex + 1;
      if (newIndex >= recommendedAudios.length) {
        newIndex = 0; // loop back to the first track.
      }
      final newAudioId = recommendedAudios[newIndex]['id'];
      // Mark this screen as being replaced so mini-player is not shown on dispose.
      _isReplaced = true;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => FullAudioPlayer(
                audioId: newAudioId,
                contentType: widget.contentType,
              ),
        ),
      );
    }
  }

  Future<void> _playPrevious() async {
    if (recommendedAudios.isNotEmpty) {
      int newIndex = currentIndex - 1;
      if (newIndex < 0) {
        newIndex = recommendedAudios.length - 1; // loop to the last track.
      }
      final newAudioId = recommendedAudios[newIndex]['id'];
      _isReplaced = true;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => FullAudioPlayer(
                audioId: newAudioId,
                contentType: widget.contentType,
              ),
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
                    color: const Color(0xFF1A8754),
                  ),
                )
                : errorMsg.isNotEmpty
                ? _errorView()
                : Column(
                  children: [
                    // Back button
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Color(0xFF1A8754),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),

                    // Tab selector
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 4,
                      ),
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: TabBar(
                          controller: _tabCtrl,
                          indicator: const BoxDecoration(
                            color: Color(0xFF1A8754),
                            borderRadius: BorderRadius.all(Radius.circular(25)),
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.grey.shade700,
                          tabs: const [
                            Tab(
                              icon: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.music_note, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    "Audio",
                                    style: TextStyle(
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
                                  Icon(Icons.description, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    "Lyrics",
                                    style: TextStyle(
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
                    ),

                    // Main content area
                    Expanded(
                      child: TabBarView(
                        controller: _tabCtrl,
                        children: [
                          // Audio tab
                          SingleChildScrollView(
                            child: Column(
                              children: [
                                // Album artwork - square with slightly rounded corners
                                Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: AspectRatio(
                                      aspectRatio: 1.0,
                                      child: CachedNetworkImage(
                                        imageUrl: imageUrl,
                                        placeholder:
                                            (_, __) => Container(
                                              color: Colors.grey.shade200,
                                              child: const Center(
                                                child: Icon(
                                                  Icons.music_note,
                                                  size: 80,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                        errorWidget:
                                            (_, __, ___) => Container(
                                              color: Colors.grey.shade200,
                                              child: const Center(
                                                child: Icon(
                                                  Icons.music_note,
                                                  size: 80,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),

                                // View count and date
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.visibility_outlined,
                                              size: 16,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              "$views views",
                                              style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.calendar_today_outlined,
                                              size: 14,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              dateUploaded.isNotEmpty
                                                  ? dateUploaded
                                                  : "Mar 3, 2025",
                                              style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Title with marquee
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    20,
                                    20,
                                    10,
                                  ),
                                  child:
                                      title.length > 25
                                          ? SizedBox(
                                            height: 30,
                                            child: Marquee(
                                              text: title,
                                              style: const TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                              scrollAxis: Axis.horizontal,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              blankSpace: 40.0,
                                              velocity: 30.0,
                                              pauseAfterRound: const Duration(
                                                seconds: 1,
                                              ),
                                              showFadingOnlyWhenScrolling: true,
                                              fadingEdgeStartFraction: 0.1,
                                              fadingEdgeEndFraction: 0.1,
                                            ),
                                          )
                                          : Text(
                                            title,
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                ),

                                // Artist name with appropriate prefix based on content type
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      widget.contentType == ContentType.marsiya
                                          ? (author == 'Unknown Artist'
                                              ? "zakir: Unknown Artist"
                                              : "zakir: $author")
                                          : (author == 'Unknown Reciter'
                                              ? "reciter: Unknown Reciter"
                                              : "reciter: $author"),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF1A8754),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Progress indicator - moved up
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  height: 4,
                                  child: Stack(
                                    children: [
                                      // Track
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                        width: double.infinity,
                                        height: 4,
                                      ),
                                      // Progress indicator (green line)
                                      FractionallySizedBox(
                                        widthFactor: sliderValue / sliderMax,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1A8754),
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                          height: 4,
                                          width: double.infinity,
                                        ),
                                      ),
                                      // The dot at the progress point (only if not at start position)
                                      if (sliderValue > 0.01)
                                        Positioned(
                                          left:
                                              MediaQuery.of(
                                                context,
                                              ).size.width *
                                              (sliderValue / sliderMax) *
                                              0.9,
                                          top: -3,
                                          child: GestureDetector(
                                            onHorizontalDragUpdate: (details) {
                                              // Calculate position based on drag
                                              final RenderBox box =
                                                  context.findRenderObject()
                                                      as RenderBox;
                                              final pos = box.globalToLocal(
                                                details.globalPosition,
                                              );
                                              final relative =
                                                  pos.dx / box.size.width;
                                              final value =
                                                  relative * sliderMax;
                                              setState(
                                                () =>
                                                    _dragValue = value.clamp(
                                                      0.0,
                                                      sliderMax,
                                                    ),
                                              );
                                            },
                                            onHorizontalDragEnd: (details) {
                                              if (_dragValue != null) {
                                                _player.seek(
                                                  Duration(
                                                    seconds:
                                                        _dragValue!.toInt(),
                                                  ),
                                                );
                                                setState(
                                                  () => _dragValue = null,
                                                );
                                              }
                                            },
                                            child: Container(
                                              width: 10,
                                              height: 10,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF1A8754),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                // Time indicators - moved up
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    4,
                                    20,
                                    10,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDuration(_position),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      Text(
                                        _formatDuration(_duration),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Player controls - keep here
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.shuffle,
                                        color: Colors.black54,
                                        size: 20,
                                      ),
                                      onPressed: null,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 20),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.skip_previous,
                                        size: 28,
                                        color: Colors.black,
                                      ),
                                      onPressed:
                                          recommendedAudios.isNotEmpty
                                              ? _playPrevious
                                              : null,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 20),
                                    // Play/Pause button
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF1A8754),
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        icon: Icon(
                                          isPlaying
                                              ? Icons.pause
                                              : Icons.play_arrow,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                        onPressed:
                                            isWaiting ? null : _togglePlayPause,
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.skip_next,
                                        size: 28,
                                        color: Colors.black,
                                      ),
                                      onPressed:
                                          recommendedAudios.isNotEmpty
                                              ? _playNext
                                              : null,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 20),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.repeat,
                                        color: Colors.black54,
                                        size: 20,
                                      ),
                                      onPressed: _toggleLoop,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 20),

                                // Recommended audio section
                                if (recommendedAudios.isNotEmpty)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 20,
                                        ),
                                        child: Text(
                                          "Recommended",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        height: 180,
                                        child: ListView.builder(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          scrollDirection: Axis.horizontal,
                                          itemCount: recommendedAudios.length,
                                          itemBuilder: (context, index) {
                                            final audio =
                                                recommendedAudios[index];
                                            final isCurrentAudio =
                                                audio['id'] == widget.audioId;

                                            return GestureDetector(
                                              onTap: () {
                                                if (!isCurrentAudio) {
                                                  _isReplaced = true;
                                                  Navigator.pushReplacement(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder:
                                                          (
                                                            _,
                                                          ) => FullAudioPlayer(
                                                            audioId:
                                                                audio['id'],
                                                            contentType:
                                                                widget
                                                                    .contentType,
                                                            autoPlay: true,
                                                          ),
                                                    ),
                                                  );
                                                }
                                              },
                                              child: Container(
                                                width: 140,
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      isCurrentAudio
                                                          ? const Color(
                                                            0xFFE8F5EF,
                                                          )
                                                          : Colors
                                                              .grey
                                                              .shade100,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border:
                                                      isCurrentAudio
                                                          ? Border.all(
                                                            color: const Color(
                                                              0xFF1A8754,
                                                            ),
                                                            width: 2,
                                                          )
                                                          : null,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    // Thumbnail with play icon overlay
                                                    Stack(
                                                      children: [
                                                        ClipRRect(
                                                          borderRadius:
                                                              const BorderRadius.only(
                                                                topLeft:
                                                                    Radius.circular(
                                                                      10,
                                                                    ),
                                                                topRight:
                                                                    Radius.circular(
                                                                      10,
                                                                    ),
                                                              ),
                                                          child: CachedNetworkImage(
                                                            imageUrl:
                                                                audio['image_url'] ??
                                                                'https://algodream.in/admin/uploads/default_art.png',
                                                            height: 100,
                                                            width:
                                                                double.infinity,
                                                            fit: BoxFit.cover,
                                                            placeholder:
                                                                (
                                                                  _,
                                                                  __,
                                                                ) => Container(
                                                                  color:
                                                                      Colors
                                                                          .grey
                                                                          .shade300,
                                                                  child: const Center(
                                                                    child: Icon(
                                                                      Icons
                                                                          .music_note,
                                                                      color:
                                                                          Colors
                                                                              .grey,
                                                                    ),
                                                                  ),
                                                                ),
                                                          ),
                                                        ),
                                                        if (isCurrentAudio)
                                                          Positioned.fill(
                                                            child: Container(
                                                              decoration: BoxDecoration(
                                                                color: Colors
                                                                    .black
                                                                    .withOpacity(
                                                                      0.3,
                                                                    ),
                                                                borderRadius:
                                                                    const BorderRadius.only(
                                                                      topLeft:
                                                                          Radius.circular(
                                                                            10,
                                                                          ),
                                                                      topRight:
                                                                          Radius.circular(
                                                                            10,
                                                                          ),
                                                                    ),
                                                              ),
                                                              child: const Center(
                                                                child: Icon(
                                                                  Icons
                                                                      .play_circle_fill,
                                                                  color:
                                                                      Colors
                                                                          .white,
                                                                  size: 40,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),

                                                    // Title and author
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            8.0,
                                                          ),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            audio['title'] ??
                                                                'Unknown Title',
                                                            style: TextStyle(
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  isCurrentAudio
                                                                      ? const Color(
                                                                        0xFF1A8754,
                                                                      )
                                                                      : Colors
                                                                          .black87,
                                                            ),
                                                            maxLines: 2,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                          const SizedBox(
                                                            height: 2,
                                                          ),
                                                          Text(
                                                            widget.contentType ==
                                                                    ContentType
                                                                        .marsiya
                                                                ? (audio['author_name'] ==
                                                                        'Unknown Artist'
                                                                    ? 'zakir: Unknown Artist'
                                                                    : 'zakir: ${audio['author_name']}')
                                                                : (audio['author_name'] ==
                                                                        'Unknown Reciter'
                                                                    ? 'reciter: Unknown Reciter'
                                                                    : 'reciter: ${audio['author_name']}'),
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              color:
                                                                  Colors
                                                                      .grey
                                                                      .shade600,
                                                            ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),

                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                          // Lyrics tab
                          _lyricsTab,
                        ],
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _errorView() => Center(
    child: Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: const Color(0xFF1A8754), size: 60),
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
              await fetchAudioData();
              await _setupAudio();
              await fetchRecommendations();
            },
            icon: const Icon(Icons.refresh),
            label: const Text("Retry"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A8754),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class LyricsTab extends StatefulWidget {
  final String? pdfUrl;
  const LyricsTab({Key? key, this.pdfUrl}) : super(key: key);
  @override
  State<LyricsTab> createState() => _LyricsTabState();
}

class _LyricsTabState extends State<LyricsTab> {
  bool isLoading = false;
  String? pdfPath;
  String errorMsg = '';
  int currentPage = 0;
  int totalPages = 0;
  bool isFullScreen = false;
  int _loadAttempts = 0;
  static const int _maxLoadAttempts = 3;

  @override
  void initState() {
    super.initState();
    // Automatically load the PDF when the widget initializes
    if (widget.pdfUrl != null) {
      // Use a small delay to ensure the widget is fully built
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _loadPdf();
        }
      });
    }
  }

  @override
  void didUpdateWidget(LyricsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the PDF URL has changed, reload it
    if (widget.pdfUrl != oldWidget.pdfUrl) {
      _loadAttempts = 0; // Reset attempts
      if (widget.pdfUrl != null) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _loadPdf();
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) =>
      widget.pdfUrl == null
          ? _noPdfView()
          : pdfPath != null
          ? Column(
            children: [
              // PDF Header
              if (!isFullScreen) _buildPdfHeader(),

              // PDF View with fullscreen controls overlay
              Expanded(
                child: Stack(
                  children: [
                    // PDF View
                    PDFView(
                      filePath: pdfPath!,
                      enableSwipe: true,
                      swipeHorizontal: false,
                      autoSpacing: true,
                      pageFling: true,
                      pageSnap: true,
                      fitPolicy: FitPolicy.BOTH,
                      preventLinkNavigation:
                          false, // If true, disables PDF links
                      onRender: (pages) {
                        setState(() {
                          totalPages = pages!;
                          isLoading = false;
                        });
                        print("PDF rendered with $pages pages");
                      },
                      onError: (error) {
                        print("PDF render error: $error");
                        setState(() {
                          errorMsg = "Failed to render PDF: $error";
                          isLoading = false;
                        });

                        // Try to reload the PDF if rendering fails
                        _retryLoadIfNeeded();
                      },
                      onPageError: (page, error) {
                        print("Error on page $page: $error");
                      },
                      onViewCreated: (controller) {
                        // You can add navigation controls here if needed
                        print("PDF view controller created");
                      },
                      onPageChanged: (page, total) {
                        print("Page changed to ${page! + 1} of $total");
                        setState(() {
                          currentPage = page + 1;
                          totalPages = total!;
                        });
                      },
                    ),

                    // Exit fullscreen button (only shown in fullscreen mode)
                    if (isFullScreen)
                      Positioned(
                        top: 20,
                        right: 20,
                        child: Material(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(30),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(30),
                            onTap: _toggleFullScreen,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: const Icon(
                                Icons.fullscreen_exit,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Page indicator
              if (totalPages > 0 && !isFullScreen)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Page $currentPage of $totalPages",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          )
          : isLoading
          ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Color(0xFF1A8754)),
                const SizedBox(height: 16),
                Text(
                  "Loading lyrics...",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          )
          : errorMsg.isNotEmpty
          ? _errorView()
          : _loadPdfButton();

  // Try to reload the PDF if loading fails
  void _retryLoadIfNeeded() {
    if (_loadAttempts < _maxLoadAttempts) {
      _loadAttempts++;
      print("Retrying PDF load - attempt $_loadAttempts of $_maxLoadAttempts");
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _loadPdf();
        }
      });
    }
  }

  Widget _buildPdfHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "PDF Lyrics",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A8754),
            ),
          ),
          TextButton.icon(
            icon: const Icon(
              Icons.fullscreen,
              color: Color(0xFF1A8754),
              size: 18,
            ),
            label: const Text(
              "View Full Screen",
              style: TextStyle(
                color: Color(0xFF1A8754),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            onPressed: _toggleFullScreen,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleFullScreen() {
    // Toggle fullscreen mode using SystemChrome
    if (isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
        DeviceOrientation.portraitUp,
      ]);
    }
    setState(() {
      isFullScreen = !isFullScreen;
    });
  }

  Widget _noPdfView() => Center(
    child: Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.picture_as_pdf, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            "No lyrics available for this audio",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "The artist hasn't provided lyrics for this content yet",
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );

  Widget _errorView() => Center(
    child: Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          const Text(
            "Failed to load lyrics",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            errorMsg,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadPdf,
            icon: const Icon(Icons.refresh),
            label: const Text("Try Again"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A8754),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _loadPdfButton() => Center(
    child: ElevatedButton.icon(
      onPressed: _loadPdf,
      icon: const Icon(Icons.download),
      label: const Text("Load Lyrics"),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1A8754),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );

  Future<void> _loadPdf() async {
    if (widget.pdfUrl == null) {
      print("PDF URL is null, cannot load PDF");
      setState(() {
        errorMsg = 'No PDF URL provided';
        isLoading = false;
      });
      return;
    }

    // If PDF is already loaded, don't reload it
    if (pdfPath != null && mounted) {
      print("PDF already loaded: $pdfPath");
      return;
    }

    print("Starting PDF loading process...");
    setState(() {
      isLoading = true;
      errorMsg = '';
    });

    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final filePath = '${tempDir.path}/$fileName.pdf';
      final file = File(filePath);

      // Print the PDF URL for debugging
      print("Attempting to load PDF from URL: ${widget.pdfUrl}");

      // Check if URL is valid
      if (!widget.pdfUrl!.startsWith('http')) {
        throw 'Invalid PDF URL: ${widget.pdfUrl}';
      }

      final response = await http
          .get(Uri.parse(widget.pdfUrl!))
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw 'PDF download timed out. Please check your internet connection.';
            },
          );

      print("HTTP response status code: ${response.statusCode}");

      if (response.statusCode != 200) {
        throw 'Failed to download PDF: HTTP ${response.statusCode}';
      }

      print("Downloaded PDF size: ${response.bodyBytes.length} bytes");

      if (response.bodyBytes.isEmpty) {
        throw 'Downloaded PDF is empty';
      }

      await file.writeAsBytes(response.bodyBytes);
      print("PDF written to file: $filePath");

      // Verify file exists and has content
      if (await file.exists()) {
        final fileSize = await file.length();
        print("PDF file size on disk: $fileSize bytes");

        if (fileSize > 0) {
          if (mounted) {
            setState(() {
              pdfPath = filePath;
              isLoading = false;
              _loadAttempts = 0; // Reset load attempts on success
              print("PDF loaded successfully");
            });
          }
        } else {
          throw 'Downloaded file is empty (zero bytes)';
        }
      } else {
        throw 'File does not exist after writing';
      }
    } catch (e) {
      print("PDF loading error: $e");
      if (mounted) {
        setState(() {
          errorMsg = 'Failed to load PDF: ${e.toString()}';
          isLoading = false;
        });
        _retryLoadIfNeeded();
      }
    }
  }

  @override
  void dispose() {
    // Reset system UI and orientation settings when widget is disposed
    if (isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }
}
