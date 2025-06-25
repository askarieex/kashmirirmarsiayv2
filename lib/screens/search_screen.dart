import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/recent_search.dart';
import '../services/search_service.dart';
import '../services/app_search_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;
  String _searchQuery = '';
  List<RecentSearch> _recentSearches = [];
  bool _isLoading = true;

  // Search results
  List<SearchResult> _searchResults = [];
  bool _isSearchingApi = false;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        if (_searchQuery.isNotEmpty) {
          _performSearch(_searchQuery);
        }
      });
    });
  }

  Future<void> _loadRecentSearches() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final recents = await SearchService.getRecentSearches();
      setState(() {
        _recentSearches = recents;
      });
    } catch (e) {
      debugPrint('Error loading recent searches: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _isSearchingApi = true;
    });

    try {
      // Use the AppSearchService to search across the app
      final results = await AppSearchService.searchAll(query);

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearchingApi = false;
        });
      }
    } catch (e) {
      debugPrint('Error searching: $e');
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearchingApi = false;
        });
      }
    }
  }

  Future<void> _saveSearch(String query, {String type = 'text'}) async {
    if (query.trim().isEmpty) return;

    await SearchService.saveSearch(query, type);
    _loadRecentSearches(); // Refresh the recent searches list
  }

  Future<void> _removeRecentSearch(String query) async {
    await SearchService.removeSearch(query);
    _loadRecentSearches();
  }

  Future<void> _clearAllRecentSearches() async {
    await SearchService.clearRecentSearches();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // Search header
            _buildSearchHeader(),

            // Search results or recent searches
            Expanded(
              child:
                  _searchQuery.isEmpty
                      ? _buildRecentSearches()
                      : _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                });
              },
            ),

          // Search field
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Search Marsiya, Noha, or audio...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    IconlyLight.search,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                  suffixIcon:
                      _searchQuery.isNotEmpty
                          ? IconButton(
                            icon: Icon(
                              Icons.close,
                              color: Colors.grey.shade600,
                              size: 20,
                            ),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                          : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    _saveSearch(value);
                    _performSearch(value);
                  }
                },
                textInputAction: TextInputAction.search,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_recentSearches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(IconlyLight.search, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No recent searches',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_recentSearches.isNotEmpty)
                TextButton(
                  onPressed: () => _clearAllRecentSearches(),
                  child: Text(
                    'Clear All',
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: AnimationLimiter(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8),
              itemCount: _recentSearches.length,
              itemBuilder: (context, index) {
                final search = _recentSearches[index];
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: ListTile(
                        leading: Icon(
                          _getIconForSearchType(search.type),
                          color: Colors.grey.shade600,
                        ),
                        title: Text(
                          search.query,
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          _formatTimestamp(search.timestamp),
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.close,
                            color: Colors.grey.shade600,
                            size: 18,
                          ),
                          onPressed: () => _removeRecentSearch(search.query),
                        ),
                        onTap: () {
                          _searchController.text = search.query;
                          _searchFocusNode.requestFocus();
                          _performSearch(search.query);
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_isSearchingApi) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Searching...',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_searchQuery.isEmpty) {
      return Container();
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(IconlyLight.search, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No results found for "$_searchQuery"',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Search Results',
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: AnimationLimiter(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final result = _searchResults[index];
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: ListTile(
                        leading: _buildResultTypeIcon(result.type),
                        title: Text(
                          result.title,
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                        ),
                        subtitle:
                            result.subtitle != null
                                ? Text(
                                  result.subtitle!,
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                )
                                : null,
                        onTap: () {
                          // Save search query when result is selected
                          _saveSearch(
                            _searchQuery,
                            type: _getTypeString(result.type),
                          );

                          // Navigate to appropriate screen
                          AppSearchService.navigateToResult(context, result);
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultTypeIcon(SearchResultType type) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case SearchResultType.marsiya:
        iconData = IconlyBold.paper;
        iconColor = Colors.blue.shade400;
        break;
      case SearchResultType.noha:
        iconData = IconlyBold.play;
        iconColor = Colors.green.shade400;
        break;
      case SearchResultType.audio:
        iconData = IconlyBold.voice;
        iconColor = Colors.purple.shade400;
        break;
      case SearchResultType.profile:
        iconData = IconlyBold.profile;
        iconColor = Colors.orange.shade400;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: iconColor, size: 20),
    );
  }

  String _getTypeString(SearchResultType type) {
    switch (type) {
      case SearchResultType.marsiya:
        return 'marsiya';
      case SearchResultType.noha:
        return 'noha';
      case SearchResultType.audio:
        return 'audio';
      case SearchResultType.profile:
        return 'profile';
    }
  }

  IconData _getIconForSearchType(String type) {
    switch (type.toLowerCase()) {
      case 'audio':
        return IconlyLight.voice;
      case 'marsiya':
        return IconlyLight.paper;
      case 'noha':
        return IconlyLight.play;
      case 'profile':
        return IconlyLight.profile;
      default:
        return IconlyLight.search;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
