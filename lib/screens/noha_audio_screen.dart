import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'full_noha_audio_play.dart';
import 'dart:typed_data';
import '../widgets/persistent_mini_player.dart';

// Import your bottom navigation targets (if not already imported)
import 'home_screen.dart';
import 'marsiya_screen.dart';

const Color accentTeal = Color(0xFF008F41);

class NohaAudioScreen extends StatefulWidget {
  const NohaAudioScreen({super.key});

  @override
  State<NohaAudioScreen> createState() => _NohaAudioScreenState();
}

class _NohaAudioScreenState extends State<NohaAudioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isLoadingMore = false;

  // List to hold the noha audio data from the API.
  List<Map<String, dynamic>> _nohaList = [];

  // Filtered list cache to avoid recalculating on every build
  List<Map<String, dynamic>>? _cachedFilteredList;

  // Cache for fetched author names.
  final Map<String, String> _authorCache = {};

  // Pagination variables.
  final int _itemsPerPage = 20;
  int _currentPage = 1;
  bool _hasMoreData = true;

  // Global playlist and current track index.
  List<Map<String, dynamic>> _globalPlaylist = [];
  int _globalCurrentIndex = -1;

  // Custom cache manager for audio meta data
  final _cacheManager = DefaultCacheManager();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this)..addListener(() {
      _refreshDataForTab();
    });
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    fetchNoha();
  }

  void _refreshDataForTab() {
    setState(() {
      _cachedFilteredList = null;
      _sortByCurrentTab();
    });
  }

  void _scrollListener() {
    if (_searchQuery.isEmpty && !_isLoadingMore && _hasMoreData) {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMoreData();
      }
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    _currentPage++;
    await fetchNoha(page: _currentPage, isLoadMore: true);

    setState(() {
      _isLoadingMore = false;
    });
  }

  void _sortByCurrentTab() {
    if (_nohaList.isEmpty) return;

    switch (_tabController.index) {
      case 0: // All - no specific sorting
        break;
      case 1: // Recent
        _nohaList.sort((a, b) {
          final dateA =
              DateTime.tryParse(a['uploaded_date'] ?? '') ?? DateTime(1970);
          final dateB =
              DateTime.tryParse(b['uploaded_date'] ?? '') ?? DateTime(1970);
          return dateB.compareTo(dateA);
        });
        break;
      case 2: // Popular
        _nohaList.sort((a, b) {
          final viewsA = int.tryParse(a['views']?.toString() ?? '0') ?? 0;
          final viewsB = int.tryParse(b['views']?.toString() ?? '0') ?? 0;
          return viewsB.compareTo(viewsA);
        });
        break;
    }
  }

  Future<void> fetchNoha({int page = 1, bool isLoadMore = false}) async {
    if (!isLoadMore) {
      setState(() {
        _isLoading = true;
        _cachedFilteredList = null;
      });
    }

    // Using the Noha API endpoint
    final url =
        "https://algodream.in/admin/api/get_noha.php?api_key=MOHAMMADASKERYMALIKFROMNOWLARI&page=${page.toString()}&limit=${_itemsPerPage.toString()}";

    try {
      // Try to get from cache first
      final cacheKey = 'noha_page_$page';
      final cachedData = await _cacheManager.getSingleFile(url);

      String responseBody;

      if (cachedData.existsSync() && !isLoadMore) {
        responseBody = await cachedData.readAsString();
      } else {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode != 200) {
          throw Exception('Failed to load data');
        }
        responseBody = response.body;

        // Save to cache
        await _cacheManager.putFile(
          url,
          Uint8List.fromList(responseBody.codeUnits),
          key: cacheKey,
          maxAge: const Duration(hours: 2),
        );
      }

      final jsonData = json.decode(responseBody);

      if (jsonData['status'] == 'success') {
        final newData = List<Map<String, dynamic>>.from(jsonData['data']);

        setState(() {
          if (isLoadMore) {
            _nohaList.addAll(newData);
          } else {
            _nohaList = newData;
          }

          _hasMoreData = newData.length == _itemsPerPage;
          _isLoading = false;
          _cachedFilteredList = null;

          // Sort according to current tab
          _sortByCurrentTab();
        });

        // Batch fetch author details
        _prefetchAuthorDetails(newData);
      } else {
        setState(() {
          _isLoading = false;
          _hasMoreData = false;
        });
      }
    } catch (e) {
      print('Error fetching noha: $e');
      setState(() {
        _isLoading = false;
        _hasMoreData = false;
      });
    }
  }

  // Batch fetch author details for performance
  Future<void> _prefetchAuthorDetails(List<Map<String, dynamic>> items) async {
    // Collect unique author IDs that need to be fetched
    final Set<String> authorIdsToFetch = {};

    for (var item in items) {
      if (item['author_id'].toString() == "1" &&
          (item['manual_author'] == null ||
              item['manual_author'].toString().isEmpty)) {
        if (!_authorCache.containsKey("1")) {
          authorIdsToFetch.add("1");
        }
      }
    }

    // Batch fetch authors
    if (authorIdsToFetch.isNotEmpty) {
      for (final authorId in authorIdsToFetch) {
        await fetchAuthor(authorId);
      }
    }
  }

  Future<void> fetchAuthor(String authorId) async {
    final url =
        "https://algodream.in/admin/api/get_author.php?api_key=MOHAMMADASKERYMALIKFROMNOWLARI&author_id=$authorId";

    try {
      // Check cache first
      final cacheKey = 'author_$authorId';
      final fileInfo = await _cacheManager.getFileFromCache(cacheKey);

      if (fileInfo != null) {
        final cachedData = await fileInfo.file.readAsString();
        final jsonData = json.decode(cachedData);
        if (jsonData['status'] == 'success') {
          setState(() {
            _authorCache[authorId] = jsonData['data']['name'];
          });
          return;
        }
      }

      // If not in cache, fetch from network
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == 'success') {
          // Cache the result
          await _cacheManager.putFile(
            url,
            Uint8List.fromList(response.body.codeUnits),
            key: cacheKey,
            maxAge: const Duration(days: 7), // Authors change rarely
          );

          setState(() {
            _authorCache[authorId] = jsonData['data']['name'];
          });
        }
      }
    } catch (e) {
      print('Error fetching author: $e');
    }
  }

  List<Map<String, dynamic>> get filteredNohaList {
    // Return cached result if available and search query hasn't changed
    if (_cachedFilteredList != null) return _cachedFilteredList!;

    List<Map<String, dynamic>> list = _nohaList;
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

    // Cache the result
    _cachedFilteredList = list;
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
    // Stop any playing marsiya before playing noha
    coordPlayerPlayback(true);

    _globalPlaylist = filteredNohaList;
    _globalCurrentIndex = _globalPlaylist.indexOf(item);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => FullNohaAudioPlay(
              nohaId: item['id'].toString(),
              autoPlay: true,
            ),
      ),
    );
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
    List<Map<String, dynamic>> displayedList = filteredNohaList;

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
                      ? _buildShimmerLoading()
                      : RefreshIndicator(
                        onRefresh: () async {
                          _currentPage = 1;
                          _hasMoreData = true;
                          await fetchNoha();
                        },
                        child:
                            displayedList.isEmpty
                                ? _buildEmptyState()
                                : _buildNohaList(displayedList),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 500),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  height: 100,
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
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_note_outlined,
            size: 80,
            color: Colors.teal.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? "No noha audio available"
                : "No results found for \"$_searchQuery\"",
            style: TextStyle(
              fontSize: 18,
              color: Colors.teal.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          if (_searchQuery.isNotEmpty)
            TextButton.icon(
              icon: Icon(Icons.close, color: Colors.teal.shade600),
              label: Text(
                "Clear search",
                style: TextStyle(color: Colors.teal.shade600),
              ),
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _cachedFilteredList = null;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildNohaList(List<Map<String, dynamic>> displayedList) {
    return AnimationLimiter(
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount:
            displayedList.length +
            (_hasMoreData && _searchQuery.isEmpty ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == displayedList.length && _searchQuery.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(color: accentTeal),
              ),
            );
          }

          final item = displayedList[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 500),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(child: _buildNohaItem(item)),
            ),
          );
        },
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
                  'نوحہ آڈیو',
                  style: TextStyle(
                    color: accentTeal,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    height: 1.2,
                  ),
                  textDirection: ui.TextDirection.rtl,
                ),
                Text(
                  'Noha Audio Collection',
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
    return Hero(
      tag: 'searchBar',
      child: Container(
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
              _cachedFilteredList = null;
            });
          },
          style: TextStyle(color: Colors.grey.shade800),
          decoration: InputDecoration(
            hintText: 'Search noha, author...',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.teal.shade400,
              size: 22,
            ),
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
                          _cachedFilteredList = null;
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
          overlayColor: MaterialStateProperty.all(Colors.transparent),
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

  Widget _buildNohaItem(Map<String, dynamic> item) {
    String displayAuthor = "";
    if (item['manual_author'] != null &&
        item['manual_author'].toString().isNotEmpty) {
      displayAuthor = item['manual_author'];
    } else if (item['author_id'] != null &&
        item['author_id'].toString() == "1") {
      displayAuthor = _authorCache["1"] ?? "Loading...";
    } else {
      displayAuthor = item['author_name'] ?? "Unknown";
    }

    String uploadedDate = item['uploaded_date'] ?? "";
    String formattedDate = formatUploadedDate(uploadedDate);
    String duration = item['duration'] ?? "";
    String views = item['views']?.toString() ?? "";

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onItemTap(item),
          borderRadius: BorderRadius.circular(16),
          child: Ink(
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
                // Visual play icon with ripple effect
                Hero(
                  tag: 'play_${item['id'].toString()}',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _onItemTap(item),
                      borderRadius: BorderRadius.circular(28),
                      child: Ink(
                        width: 56,
                        height: 56,
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
                        child: const Center(
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Main content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] ?? "Untitled Noha",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF333333),
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                displayAuthor,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            // Views
                            Icon(
                              Icons.visibility_outlined,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "$views views",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Duration
                            Icon(
                              Icons.timer_outlined,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              duration,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Arrow icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  margin: const EdgeInsets.only(right: 16),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: accentTeal,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
