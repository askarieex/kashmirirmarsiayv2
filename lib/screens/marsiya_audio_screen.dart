import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'full_marsiya_audio_play.dart';
import 'dart:typed_data';
import '../widgets/persistent_mini_player.dart';

// Import your bottom navigation targets (if not already imported)
import 'home_screen.dart';
import 'noha_screen.dart';

const Color accentTeal = Color(0xFF008F41);
const Color backgroundColor = Color(0xFFF2F7F7);

class MarsiyaAudioScreen extends StatefulWidget {
  const MarsiyaAudioScreen({super.key});

  @override
  State<MarsiyaAudioScreen> createState() => _MarsiyaAudioScreenState();
}

class _MarsiyaAudioScreenState extends State<MarsiyaAudioScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isSearchFocused = false;

  // Animation controller for search bar
  late AnimationController _searchAnimationController;
  late Animation<double> _searchBarWidthAnimation;
  final FocusNode _searchFocusNode = FocusNode();

  // List to hold the marsiya audio data from the API.
  List<Map<String, dynamic>> _marsiyaList = [];

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

    // Initialize search animation controller
    _searchAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _searchBarWidthAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _searchAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus) {
        _searchAnimationController.forward();
        setState(() {
          _isSearchFocused = true;
        });
      } else {
        if (_searchQuery.isEmpty) {
          _searchAnimationController.reverse();
          setState(() {
            _isSearchFocused = false;
          });
        }
      }
    });

    fetchMarsiya();
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
    await fetchMarsiya(page: _currentPage, isLoadMore: true);

    setState(() {
      _isLoadingMore = false;
    });
  }

  void _sortByCurrentTab() {
    if (_marsiyaList.isEmpty) return;

    switch (_tabController.index) {
      case 0: // All - no specific sorting
        break;
      case 1: // Recent
        _marsiyaList.sort((a, b) {
          final dateA =
              DateTime.tryParse(a['uploaded_date'] ?? '') ?? DateTime(1970);
          final dateB =
              DateTime.tryParse(b['uploaded_date'] ?? '') ?? DateTime(1970);
          return dateB.compareTo(dateA);
        });
        break;
      case 2: // Popular
        _marsiyaList.sort((a, b) {
          final viewsA = int.tryParse(a['views']?.toString() ?? '0') ?? 0;
          final viewsB = int.tryParse(b['views']?.toString() ?? '0') ?? 0;
          return viewsB.compareTo(viewsA);
        });
        break;
    }
  }

  Future<void> fetchMarsiya({int page = 1, bool isLoadMore = false}) async {
    if (!isLoadMore) {
      setState(() {
        _isLoading = true;
        _cachedFilteredList = null;
      });
    }

    // Adapted URL to support pagination
    final url =
        "https://algodream.in/admin/api/get_marsiya.php?api_key=MOHAMMADASKERYMALIKFROMNOWLARI&page=${page.toString()}&limit=${_itemsPerPage.toString()}";

    try {
      // Try to get from cache first
      final cacheKey = 'marsiya_page_$page';
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
            _marsiyaList.addAll(newData);
          } else {
            _marsiyaList = newData;
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
      print('Error fetching marsiya: $e');
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

  List<Map<String, dynamic>> get filteredMarsiyaList {
    // Return cached result if available and search query hasn't changed
    if (_cachedFilteredList != null) return _cachedFilteredList!;

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
    // Stop any playing noha before playing marsiya
    coordPlayerPlayback(false);

    _globalPlaylist = filteredMarsiyaList;
    _globalCurrentIndex = _globalPlaylist.indexOf(item);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => FullMarsiyaAudioPlay(
              audioId: item['id'].toString(),
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
    _searchFocusNode.dispose();
    _searchAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> displayedList = filteredMarsiyaList;

    return Scaffold(
      backgroundColor: backgroundColor,
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
                          await fetchMarsiya();
                        },
                        color: accentTeal,
                        backgroundColor: Colors.white,
                        strokeWidth: 3,
                        child:
                            displayedList.isEmpty
                                ? _buildEmptyState()
                                : _buildMarsiyaList(displayedList),
                      ),
            ),
          ],
        ),
      ),
      // Bottom Navigation Bar REMOVED
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
          Icon(IconlyBold.voice, size: 80, color: Colors.teal.shade300),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? "No marsiya audio available"
                : "No results found for \"$_searchQuery\"",
            style: GoogleFonts.nunitoSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.teal.shade700,
            ),
          ),
          const SizedBox(height: 8),
          if (_searchQuery.isNotEmpty)
            TextButton.icon(
              icon: Icon(IconlyBold.close_square, color: Colors.teal.shade600),
              label: Text(
                "Clear search",
                style: GoogleFonts.nunitoSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.teal.shade600,
                ),
              ),
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _cachedFilteredList = null;
                });
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.teal.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMarsiyaList(List<Map<String, dynamic>> displayedList) {
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
              child: FadeInAnimation(child: _buildMarsiyaItem(item)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        gradient: LinearGradient(
          colors: [Colors.white, backgroundColor],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
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
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: accentTeal.withOpacity(0.15),
                    blurRadius: 4,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                IconlyLight.arrow_left,
                color: accentTeal,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مرثیہ آڈیو',
                  style: GoogleFonts.notoNastaliqUrdu(
                    color: accentTeal,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    height: 1.9,
                  ),
                  textDirection: ui.TextDirection.rtl,
                ),
                Text(
                  'Marsiya Audio Collection',
                  style: GoogleFonts.nunitoSans(
                    color: Colors.teal.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          _buildFavoriteButton(),
        ],
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: accentTeal.withOpacity(0.15),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(IconlyLight.heart, color: accentTeal, size: 22),
    );
  }

  Widget _buildSearchBar() {
    return Hero(
      tag: 'searchBar',
      child: AnimatedBuilder(
        animation: _searchAnimationController,
        builder: (context, child) {
          return Container(
            width:
                MediaQuery.of(context).size.width *
                (_searchBarWidthAnimation.value),
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: accentTeal.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _cachedFilteredList = null;
                });
              },
              style: GoogleFonts.nunitoSans(
                color: Colors.grey.shade800,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Search marsiya, author...',
                hintStyle: GoogleFonts.nunitoSans(
                  color: Colors.grey.shade400,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Icon(
                  _isSearchFocused ? IconlyBold.search : IconlyLight.search,
                  color: Colors.teal.shade400,
                  size: 22,
                ),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: Icon(
                            IconlyBold.close_square,
                            color: Colors.grey.shade500,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                              _cachedFilteredList = null;
                              _searchFocusNode.unfocus();
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
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(
                    color: accentTeal.withOpacity(0.3),
                    width: 2,
                  ),
                ),
              ),
            ),
          );
        },
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
            color: accentTeal.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 0,
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
          labelStyle: GoogleFonts.nunitoSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          unselectedLabelStyle: GoogleFonts.nunitoSans(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          splashFactory: NoSplash.splashFactory,
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
          tabs: [
            _buildTabItem(IconlyLight.document, 'All'),
            _buildTabItem(IconlyLight.time_circle, 'Recent'),
            _buildTabItem(IconlyLight.star, 'Popular'),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(IconData icon, String title) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(title, style: const TextStyle(height: 1)),
        ],
      ),
    );
  }

  Widget _buildMarsiyaItem(Map<String, dynamic> item) {
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

    // Check if the item is PDF or Audio
    bool isPdf = item['content_type'] == 'pdf';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accentTeal.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: accentTeal.withOpacity(0.12),
              blurRadius: 15,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.7),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(-3, -3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _onItemTap(item),
              splashColor: accentTeal.withOpacity(0.1),
              highlightColor: accentTeal.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Beautiful icon based on content type with animation effect
                    Hero(
                      tag: 'play_${item['id'].toString()}',
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors:
                                isPdf
                                    ? [
                                      Color(0xFF9747FF),
                                      Color(0xFF7E42D9),
                                      Color(0xFF6B38C1),
                                    ] // Purple for PDF
                                    : [
                                      accentTeal,
                                      Color(0xFF00B77E),
                                      Color(0xFF00D68F),
                                    ], // Green for Audio
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: (isPdf ? Color(0xFF9747FF) : accentTeal)
                                  .withOpacity(0.25),
                              blurRadius: 12,
                              spreadRadius: 0,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _onItemTap(item),
                            borderRadius: BorderRadius.circular(16),
                            child: Center(
                              child: Icon(
                                isPdf ? IconlyLight.document : IconlyLight.play,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Content section with improved layout and styling
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title with elegant text styling
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              item['title'] ?? '',
                              style: GoogleFonts.notoNastaliqUrdu(
                                color: const Color(0xFF2D3A3A),
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                height: 1.8,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              textDirection: ui.TextDirection.rtl,
                              textAlign: TextAlign.right,
                            ),
                          ),

                          // Author with badge
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: (isPdf ? Color(0xFF9747FF) : accentTeal)
                                  .withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: (isPdf ? Color(0xFF9747FF) : accentTeal)
                                    .withOpacity(0.1),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  IconlyLight.profile,
                                  size: 12,
                                  color: isPdf ? Color(0xFF9747FF) : accentTeal,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    displayAuthor,
                                    style: GoogleFonts.poppins(
                                      color: (isPdf
                                              ? Color(0xFF9747FF)
                                              : accentTeal)
                                          .withOpacity(0.9),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Details row with attractive styling
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _buildDetailChip(
                                IconlyLight.time_circle,
                                duration.isEmpty ? "No duration" : duration,
                                Colors.purple.shade400,
                              ),
                              _buildDetailChip(
                                IconlyLight.show,
                                "$views views",
                                Colors.blue.shade400,
                              ),
                              _buildDetailChip(
                                IconlyLight.calendar,
                                formattedDate.split(" at")[0],
                                Colors.orange.shade400,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              color: color.withOpacity(0.8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class SkeletonAnimation extends StatefulWidget {
  final Widget child;
  const SkeletonAnimation({super.key, required this.child});

  @override
  _SkeletonAnimationState createState() => _SkeletonAnimationState();
}

class _SkeletonAnimationState extends State<SkeletonAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.8).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder:
          (context, child) =>
              Opacity(opacity: _animation.value, child: widget.child),
    );
  }
}

extension LetExtension on DateTime {
  T let<T>(T Function(DateTime) op) => op(this);
}
