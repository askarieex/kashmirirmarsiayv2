import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/persistent_mini_player.dart' as player_widgets;
import 'full_audio_player.dart';

class NohaAudioScreen extends StatefulWidget {
  const NohaAudioScreen({Key? key}) : super(key: key);

  @override
  State<NohaAudioScreen> createState() => _NohaAudioScreenState();
}

class _NohaAudioScreenState extends State<NohaAudioScreen>
    with TickerProviderStateMixin {
  // API endpoint URL
  final String apiUrl =
      'https://algodream.in/admin/api/get_noha.php?api_key=MOHAMMADASKERYMALIKFROMNOWLARI';

  // Tab controller for sorting options
  late TabController _tabController;

  // List to store noha data
  List<dynamic> nohas = [];
  List<dynamic> filteredNohas = [];
  bool isLoading = true;
  String errorMessage = '';
  bool hasMore = true;
  int currentPage = 1;

  // Search controller
  final TextEditingController _searchController = TextEditingController();

  // Scroll controller for pagination
  final ScrollController _scrollController = ScrollController();

  // Audio player instance
  AudioPlayer? _audioPlayer;

  // Currently playing noha
  Map<String, dynamic>? currentPlayingNoha;

  // Audio player variables
  bool isPlaying = false;
  bool isAudioLoading = false;
  Duration audioDuration = Duration.zero;
  Duration audioPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);

    // Initialize audio player
    _audioPlayer = AudioPlayer();

    _audioPlayer!.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          isPlaying = state.playing;
          if (state.processingState != ProcessingState.loading) {
            isAudioLoading = false;
          }
        });
      }
    });

    _audioPlayer!.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          audioPosition = position;
        });
      }
    });

    _audioPlayer!.durationStream.listen((duration) {
      if (mounted && duration != null) {
        setState(() {
          audioDuration = duration;
        });
      }
    });

    // Fetch initial data
    _fetchNohas();

    // Add scroll listener for pagination
    _scrollController.addListener(_scrollListener);

    // Add search listener
    _searchController.addListener(_filterNohas);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _stopAudio();
    _audioPlayer?.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      _sortNohas(_tabController.index);
    }
  }

  void _sortNohas(int tabIndex) {
    setState(() {
      switch (tabIndex) {
        case 0: // All (default order)
          filteredNohas = List.from(nohas);
          break;
        case 1: // Recent
          filteredNohas.sort((a, b) {
            DateTime dateA = DateTime.parse(a['uploaded_date'] ?? '2023-01-01');
            DateTime dateB = DateTime.parse(b['uploaded_date'] ?? '2023-01-01');
            return dateB.compareTo(dateA); // Sort by date (newest first)
          });
          break;
        case 2: // Popular
          filteredNohas.sort((a, b) {
            int viewsA = int.tryParse(a['views'] ?? '0') ?? 0;
            int viewsB = int.tryParse(b['views'] ?? '0') ?? 0;
            return viewsB.compareTo(viewsA); // Sort by views (highest first)
          });
          break;
      }
    });
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (hasMore && !isLoading) {
        _loadMoreNohas();
      }
    }
  }

  void _filterNohas() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredNohas = List.from(nohas);
      } else {
        filteredNohas =
            nohas.where((noha) {
              final title = noha['title']?.toLowerCase() ?? '';
              final author = noha['author_name']?.toLowerCase() ?? '';
              return title.contains(query) || author.contains(query);
            }).toList();
      }
      _sortNohas(_tabController.index);
    });
  }

  Future<void> _fetchNohas() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(Uri.parse('$apiUrl&page=$currentPage'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          setState(() {
            nohas.addAll(data['data']);
            filteredNohas = List.from(nohas);
            _sortNohas(_tabController.index);
            hasMore = data['has_more'] == true;
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = data['message'] ?? 'Failed to load nohas';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Server error: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Network error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _loadMoreNohas() async {
    setState(() {
      isLoading = true;
    });

    currentPage++;
    await _fetchNohas();
  }

  void _playAudio(Map<String, dynamic> noha) async {
    // First stop any currently playing audio
    await _stopAudio();

    final audioUrl = noha['audio_url'];
    if (audioUrl == null || audioUrl.isEmpty) {
      // Show snackbar if audio URL is missing
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Audio URL not available')));
      return;
    }

    setState(() {
      isAudioLoading = true;
      currentPlayingNoha = noha;
    });

    try {
      // Set up audio source with metadata
      final audioSource = AudioSource.uri(
        Uri.parse(audioUrl),
        tag: {
          'title': noha['title'] ?? 'Unknown Title',
          'artist': noha['author_name'] ?? 'Unknown Artist',
          'audioId': noha['id'] ?? '0',
          'contentType': 'ContentType.noha',
          'imageUrl': noha['image_url'] ?? '',
        },
      );

      await _audioPlayer!.setAudioSource(audioSource);
      await _audioPlayer!.play();

      // Update the global variables for the mini player
      if (player_widgets.globalNohaTitle != null) {
        player_widgets.globalNohaTitle = noha['title'] ?? 'Unknown Title';
      }
      if (player_widgets.globalNohaArtistName != null) {
        player_widgets.globalNohaArtistName =
            noha['author_name'] ?? 'Unknown Artist';
      }
      if (player_widgets.globalNohaImageUrl != null) {
        player_widgets.globalNohaImageUrl = noha['image_url'];
      }

      // Show the persistent mini player
      player_widgets.showPersistentMiniPlayerNotifier.value = true;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error playing audio: $e')));
      setState(() {
        isAudioLoading = false;
        currentPlayingNoha = null;
      });
    }
  }

  Future<void> _stopAudio() async {
    if (_audioPlayer != null && _audioPlayer!.playing) {
      await _audioPlayer!.stop();
      setState(() {
        currentPlayingNoha = null;
      });

      // Hide the mini player
      player_widgets.showPersistentMiniPlayerNotifier.value = false;
    }
  }

  void _playNohaFromFullScreen(Map<String, dynamic> nohaData) {
    if (_audioPlayer != null) {
      // Stop any currently playing audio
      _stopAudio();
    }

    // Update the global variables for the mini player
    if (player_widgets.globalNohaTitle != null) {
      player_widgets.globalNohaTitle = nohaData['title'] ?? '';
    }
    if (player_widgets.globalNohaArtistName != null) {
      player_widgets.globalNohaArtistName = nohaData['author_name'] ?? '';
    }
    if (player_widgets.globalNohaImageUrl != null) {
      player_widgets.globalNohaImageUrl = nohaData['image_url'];
    }

    // Navigate to the full audio player screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => FullAudioPlayer(
              audioId: nohaData['id'],
              autoPlay: true,
              contentType: ContentType.noha,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5F5F8), // Light blue background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFE5F5F8),
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'نوحہ',
                  style: GoogleFonts.notoNastaliqUrdu(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00875A),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Audio Collection',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.black87),
            onPressed: () {
              // Favorite action
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search nohas...',
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // Tab bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF00875A),
                borderRadius: BorderRadius.circular(30),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.black87,
              labelStyle: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Recent'),
                Tab(text: 'Popular'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Content area
          Expanded(child: _buildNohasList()),
        ],
      ),
    );
  }

  Widget _buildNohasList() {
    if (isLoading && nohas.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00875A)),
        ),
      );
    }

    if (errorMessage.isNotEmpty && nohas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error Loading Nohas',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _fetchNohas(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00875A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text('Try Again', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      );
    }

    if (filteredNohas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_note, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Nohas Found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_searchController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Try a different search term',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredNohas.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= filteredNohas.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00875A)),
              ),
            ),
          );
        }

        final noha = filteredNohas[index];
        return _buildNohaItem(noha);
      },
    );
  }

  Widget _buildNohaItem(Map<String, dynamic> noha) {
    final isCurrentlyPlaying =
        currentPlayingNoha != null && currentPlayingNoha!['id'] == noha['id'];

    // Format the date if available
    String formattedDate = '';
    try {
      if (noha['uploaded_date'] != null) {
        final date = DateTime.parse(noha['uploaded_date']);
        formattedDate = DateFormat('dd MMM yyyy').format(date);
      }
    } catch (e) {
      // Use empty string if date parsing fails
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _playNohaFromFullScreen(noha),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Play button container
              GestureDetector(
                onTap: () {
                  if (isCurrentlyPlaying) {
                    isPlaying ? _audioPlayer?.pause() : _audioPlayer?.play();
                  } else {
                    _playAudio(noha);
                  }
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00875A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child:
                        isCurrentlyPlaying && isAudioLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : Icon(
                              isCurrentlyPlaying && isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.white,
                              size: 28,
                            ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Title, author, stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      noha['title'] ?? 'Unknown Title',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      noha['author_name'] ?? 'Unknown Zakir',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Upload date
                        if (formattedDate.isNotEmpty) ...[
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            formattedDate,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],

                        // Views
                        Icon(
                          Icons.remove_red_eye_outlined,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${noha['views'] ?? '0'} views",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Duration
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  noha['duration'] ?? '--:--',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
