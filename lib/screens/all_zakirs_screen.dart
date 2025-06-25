import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'view_profile_screen.dart';

class ZakirProfile {
  final int id;
  final String name;
  final String profileImage;
  final int totalViews;
  final int totalPlays;

  ZakirProfile({
    required this.id,
    required this.name,
    required this.profileImage,
    required this.totalViews,
    required this.totalPlays,
  });

  factory ZakirProfile.fromJson(Map<String, dynamic> json) {
    return ZakirProfile(
      id: json['id'],
      name: json['name'],
      profileImage: json['profile_image'],
      totalViews: json['total_views'],
      totalPlays: json['total_plays'],
    );
  }
}

class AllZakirsScreen extends StatefulWidget {
  const AllZakirsScreen({super.key});

  @override
  State<AllZakirsScreen> createState() => _AllZakirsScreenState();
}

class _AllZakirsScreenState extends State<AllZakirsScreen> {
  List<ZakirProfile> _zakirs = [];
  List<ZakirProfile> _filteredZakirs = [];
  bool _isLoading = true;
  bool _isSearchActive = false;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _fetchZakirs();
    _searchController.addListener(_filterZakirs);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterZakirs);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _filterZakirs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredZakirs = List.from(_zakirs);
      } else {
        _filteredZakirs =
            _zakirs
                .where((zakir) => zakir.name.toLowerCase().contains(query))
                .toList();
      }
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearchActive = !_isSearchActive;
      if (!_isSearchActive) {
        _searchController.clear();
        _filteredZakirs = List.from(_zakirs);
      } else {
        _searchFocusNode.requestFocus();
      }
    });
  }

  Future<void> _fetchZakirs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://algodream.in/admin/api/get_all_zakirs.php?api_key=MOHAMMADASKERYMALIKFROMNOWLARI',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> zakirsData = data['data'];
          setState(() {
            _zakirs =
                zakirsData
                    .map((zakir) => ZakirProfile.fromJson(zakir))
                    .toList();
            _filteredZakirs = List.from(_zakirs);
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Failed to load data';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Server error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _isSearchActive ? Colors.white : const Color(0xFF00875A),
      elevation: _isSearchActive ? 0 : 0,
      centerTitle: !_isSearchActive,
      title:
          _isSearchActive
              ? _buildSearchField()
              : Text(
                'Zakirs',
                style: GoogleFonts.nunitoSans(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      leading:
          _isSearchActive
              ? IconButton(
                icon: const Icon(
                  IconlyLight.arrow_left_2,
                  color: Color(0xFF00875A),
                ),
                onPressed: _toggleSearch,
              )
              : IconButton(
                icon: const Icon(IconlyLight.arrow_left, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
      actions: [
        if (!_isSearchActive)
          IconButton(
            icon: const Icon(IconlyLight.search, color: Colors.white),
            onPressed: _toggleSearch,
          ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      decoration: InputDecoration(
        hintText: 'Search zakirs...',
        hintStyle: GoogleFonts.nunitoSans(
          color: Colors.grey[400],
          fontSize: 16,
        ),
        border: InputBorder.none,
        prefixIcon: Icon(
          IconlyLight.search,
          color: const Color(0xFF00875A).withOpacity(0.7),
        ),
        suffixIcon:
            _searchController.text.isNotEmpty
                ? IconButton(
                  icon: const Icon(Icons.clear, color: Color(0xFF00875A)),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
                : null,
      ),
      style: GoogleFonts.poppins(color: const Color(0xFF333333), fontSize: 16),
      textInputAction: TextInputAction.search,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00875A)),
            ),
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[800]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchZakirs,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00875A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_filteredZakirs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchController.text.isNotEmpty
                  ? Icons.search_off
                  : Icons.person_off,
              color: Colors.grey[400],
              size: 80,
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty
                  ? 'No results found for "${_searchController.text}"'
                  : 'No Zakirs Found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: TextButton(
                  onPressed: () {
                    _searchController.clear();
                  },
                  child: Text(
                    'Clear Search',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF00875A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchZakirs,
      color: const Color(0xFF00875A),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Text(
                    'All Zakirs',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00875A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_filteredZakirs.length}',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _filteredZakirs.length,
                itemBuilder: (context, index) {
                  final zakir = _filteredZakirs[index];
                  return _buildZakirCard(zakir);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZakirCard(ZakirProfile zakir) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ViewProfileScreen(profileId: zakir.id.toString()),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile image with gradient border
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [const Color(0xFF00875A), const Color(0xFF4ECDC4)],
                  ),
                ),
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.white,
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: zakir.profileImage,
                      placeholder:
                          (context, url) => const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF00875A),
                              ),
                              strokeWidth: 2,
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => const Icon(
                            IconlyLight.profile,
                            size: 60,
                            color: Color(0xFFCCCCCC),
                          ),
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                zakir.name,
                style: GoogleFonts.nunitoSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF333333),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00875A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Zakir',
                style: GoogleFonts.nunitoSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF00875A),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatistic(Icons.visibility, zakir.totalViews.toString()),
                const SizedBox(width: 16),
                _buildStatistic(Icons.play_circle, zakir.totalPlays.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistic(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(
          value,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
