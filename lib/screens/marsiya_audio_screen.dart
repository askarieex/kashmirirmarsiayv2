import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'full_marsiya_audio_play.dart';
import 'package:just_audio/just_audio.dart';

const Color accentTeal = Color(0xFF008F41);

class MarsiyaAudioScreen extends StatefulWidget {
  const MarsiyaAudioScreen({super.key});

  @override
  State<MarsiyaAudioScreen> createState() => _MarsiyaAudioScreenState();
}

class _MarsiyaAudioScreenState extends State<MarsiyaAudioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;

  // List to hold the marsiya audio data from the API.
  List<Map<String, dynamic>> _marsiyaList = [];

  // Cache for fetched author names.
  final Map<String, String> _authorCache = {};

  // Pagination variables.
  final int _itemsPerPage = 20;
  int _currentMax = 20;

  // Global playlist and current track index.
  List<Map<String, dynamic>> _globalPlaylist = [];
  int _globalCurrentIndex = -1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this)..addListener(() {
      setState(() {}); // refresh on tab change
    });
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    fetchMarsiya();
  }

  void _scrollListener() {
    if (_searchQuery.isEmpty) {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        if (_currentMax < filteredMarsiyaList.length) {
          setState(() {
            _currentMax =
                (_currentMax + _itemsPerPage) > filteredMarsiyaList.length
                    ? filteredMarsiyaList.length
                    : _currentMax + _itemsPerPage;
          });
        }
      }
    }
  }

  Future<void> fetchMarsiya() async {
    const url =
        "https://algodream.in/admin/api/get_marsiya.php?api_key=MOHAMMADASKERYMALIKFROMNOWLARI";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == 'success') {
          setState(() {
            _marsiyaList = List<Map<String, dynamic>>.from(jsonData['data']);
            _isLoading = false;
            _currentMax = _itemsPerPage;
          });
          // Fetch author details for items where needed.
          for (var item in _marsiyaList) {
            if (item['author_id'] == "1" &&
                (item['manual_author'] == null ||
                    item['manual_author'].toString().isEmpty)) {
              if (!_authorCache.containsKey("1")) {
                fetchAuthor("1");
              }
            }
          }
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print(e);
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> fetchAuthor(String authorId) async {
    final url =
        "https://algodream.in/admin/api/get_author.php?api_key=MOHAMMADASKERYMALIKFROMNOWLARI&author_id=$authorId";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == 'success') {
          setState(() {
            _authorCache[authorId] = jsonData['data']['name'];
          });
        }
      }
    } catch (e) {
      print(e);
    }
  }

  List<Map<String, dynamic>> get filteredMarsiyaList {
    List<Map<String, dynamic>> list = _marsiyaList;
    if (_searchQuery.isNotEmpty) {
      list =
          list.where((item) {
            final title = item['title']?.toString().toLowerCase() ?? "";
            final manualAuthor =
                item['manual_author']?.toString().toLowerCase() ?? "";
            final authorName =
                item['author_name']?.toString().toLowerCase() ?? "";
            return title.contains(_searchQuery.toLowerCase()) ||
                manualAuthor.contains(_searchQuery.toLowerCase()) ||
                authorName.contains(_searchQuery.toLowerCase());
          }).toList();
    }
    return list;
  }

  String formatUploadedDate(String dateStr) {
    try {
      DateTime dt = DateTime.parse(dateStr);
      return DateFormat("MMM d, yyyy 'at' hh:mm a", 'en_US').format(dt);
    } catch (e) {
      return dateStr;
    }
  }

  // When an item is tapped, set the global playlist and current index,
  // then navigate to the full player with autoPlay enabled.
  void _onItemTap(Map<String, dynamic> item) {
    _globalPlaylist = filteredMarsiyaList;
    _globalCurrentIndex = _globalPlaylist.indexOf(item);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) =>
                FullMarsiyaAudioPlay(audioId: item['id'], autoPlay: true),
      ),
    );
  }

  // Play the next track from the global playlist.
  void _playNextTrack() async {
    if (_globalPlaylist.isNotEmpty &&
        _globalCurrentIndex < _globalPlaylist.length - 1) {
      _globalCurrentIndex++;
      Map<String, dynamic> nextTrack = _globalPlaylist[_globalCurrentIndex];
      // Directly use the audio URL from the list (assuming it's available)
      String nextAudioUrl = nextTrack['audio_url'] ?? "";
      if (nextAudioUrl.isNotEmpty) {
        await globalAudioPlayer.setAudioSource(
          AudioSource.uri(Uri.parse(nextAudioUrl)),
        );
        await globalAudioPlayer.play();
        // Optionally, update UI or title details.
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> displayedList =
        _searchQuery.isNotEmpty
            ? filteredMarsiyaList
            : filteredMarsiyaList.take(_currentMax).toList();

    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            _buildSearchBar(),
            _buildTabs(),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                        onRefresh: fetchMarsiya,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount:
                              displayedList.length +
                              (displayedList.length <
                                          filteredMarsiyaList.length &&
                                      _searchQuery.isEmpty
                                  ? 1
                                  : 0),
                          itemBuilder: (context, index) {
                            if (index == displayedList.length &&
                                _searchQuery.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            final item = displayedList[index];
                            return _buildMarsiyaItem(item);
                          },
                        ),
                      ),
            ),
            // Show the mini-player if a track is playing.
            if (globalAudioPlayer.playing ||
                globalAudioPlayer.processingState == ProcessingState.ready)
              MiniPlayer(
                currentTrack:
                    _globalCurrentIndex != -1 && _globalPlaylist.isNotEmpty
                        ? _globalPlaylist[_globalCurrentIndex]
                        : null,
                onPlayPauseToggle: () async {
                  if (globalAudioPlayer.playing) {
                    await globalAudioPlayer.pause();
                  } else {
                    await globalAudioPlayer.play();
                  }
                  setState(() {});
                },
                onNext: _playNextTrack,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back, color: accentTeal, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'مرثیہ آڈیو',
                  style: TextStyle(
                    color: accentTeal,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    height: 1.2,
                  ),
                  textDirection: ui.TextDirection.rtl,
                ),
                Text(
                  'Marsiya Audio Collection',
                  style: TextStyle(color: Colors.teal.shade700, fontSize: 14),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.favorite_border,
              color: accentTeal,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            if (_searchQuery.isEmpty) {
              _currentMax = _itemsPerPage;
            }
          });
        },
        style: TextStyle(color: Colors.grey.shade800),
        decoration: InputDecoration(
          hintText: 'Search marsiya, author...',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Icon(Icons.search, color: Colors.teal.shade400, size: 22),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Colors.grey.shade500,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                        _currentMax = _itemsPerPage;
                      });
                    },
                  )
                  : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            gradient: LinearGradient(
              colors: [accentTeal, accentTeal.withOpacity(0.8)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: [
              BoxShadow(
                color: accentTeal.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey.shade600,
          labelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          splashFactory: NoSplash.splashFactory,
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
          tabs: const [
            Tab(child: Center(child: Text('All', style: TextStyle(height: 1)))),
            Tab(
              child: Center(child: Text('Recent', style: TextStyle(height: 1))),
            ),
            Tab(
              child: Center(
                child: Text('Popular', style: TextStyle(height: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // The entire list item is clickable.
  Widget _buildMarsiyaItem(Map<String, dynamic> item) {
    String displayAuthor = "";
    if (item['manual_author'] != null &&
        item['manual_author'].toString().isNotEmpty) {
      displayAuthor = item['manual_author'];
    } else if (item['author_id'] != null && item['author_id'] == "1") {
      displayAuthor = _authorCache["1"] ?? "Loading...";
    } else {
      displayAuthor = item['author_name'] ?? "Unknown";
    }

    String uploadedDate = item['uploaded_date'] ?? "";
    String formattedDate = formatUploadedDate(uploadedDate);
    String duration = item['duration'] ?? "";
    String views = item['views'] ?? "";

    return InkWell(
      onTap: () {
        _onItemTap(item);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Visual play icon.
            Container(
              width: 56,
              height: 56,
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentTeal.withOpacity(0.9), accentTeal],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: accentTeal.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            // Content section.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Title.
                    Container(
                      height: 22,
                      alignment: Alignment.centerRight,
                      child: Directionality(
                        textDirection: ui.TextDirection.rtl,
                        child: Text(
                          item['title'] ?? '',
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Author row.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayAuthor,
                          style: TextStyle(
                            color: Colors.teal.shade700,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.person,
                          size: 14,
                          color: Colors.teal.shade400,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Details row.
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              formattedDate,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: Colors.grey.shade500,
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              views,
                              style: TextStyle(
                                color: Colors.teal.shade700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.visibility_outlined,
                              size: 14,
                              color: Colors.teal.shade500,
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              duration,
                              style: TextStyle(
                                color: Colors.teal.shade700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.teal.shade500,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// MiniPlayer widget that displays a seekbar, play/pause and next controls.
class MiniPlayer extends StatefulWidget {
  final Map<String, dynamic>? currentTrack;
  final VoidCallback onPlayPauseToggle;
  final VoidCallback onNext;
  const MiniPlayer({
    super.key,
    required this.currentTrack,
    required this.onPlayPauseToggle,
    required this.onNext,
  });

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    // Listen to the global player's streams.
    globalAudioPlayer.positionStream.listen((p) {
      setState(() {
        _position = p;
      });
    });
    globalAudioPlayer.durationStream.listen((d) {
      setState(() {
        _duration = d ?? Duration.zero;
      });
    });
    // When the track completes, trigger onNext.
    globalAudioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        widget.onNext();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String title =
        widget.currentTrack != null
            ? widget.currentTrack!['title'] ?? 'Playing'
            : 'Playing';
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title and controls row.
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: widget.onPlayPauseToggle,
                icon: Icon(
                  globalAudioPlayer.playing ? Icons.pause : Icons.play_arrow,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              IconButton(
                onPressed: widget.onNext,
                icon: Icon(
                  Icons.skip_next,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          // Seekbar.
          Slider(
            value: _position.inSeconds.toDouble(),
            max:
                _duration.inSeconds.toDouble() > 0
                    ? _duration.inSeconds.toDouble()
                    : 1.0,
            onChanged: (value) async {
              await globalAudioPlayer.seek(Duration(seconds: value.toInt()));
            },
          ),
        ],
      ),
    );
  }
}

extension LetExtension on DateTime {
  T let<T>(T Function(DateTime) op) => op(this);
}
