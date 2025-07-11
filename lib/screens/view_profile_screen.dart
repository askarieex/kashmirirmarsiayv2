import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/artist_item.dart';
import 'full_marsiya_audio_play.dart';
import 'full_noha_audio_play.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:iconly/iconly.dart';
import 'package:marquee/marquee.dart';
import '../services/view_tracking_service.dart';

class ViewProfileScreen extends StatefulWidget {
  final String profileId;

  const ViewProfileScreen({super.key, required this.profileId});

  @override
  State<ViewProfileScreen> createState() => _ViewProfileScreenState();
}

class _ViewProfileScreenState extends State<ViewProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  ArtistItem? _profile;
  List<dynamic> _marsiya = [];
  List<dynamic> _noha = [];
  int _totalContentCount = 0;

  TabController? _tabController;
  late ScrollController _scrollController;
  bool _showTitle = false;

  // Dynamic tab configuration
  List<String> _availableTabs = [];
  bool _showMarsiyaTab = false;
  bool _showNohaTab = false;

  // Flag to track if profile view has been counted
  bool _viewCounted = false;

  // Enhanced color palette
  static const Color primaryColor = Color(0xFF1A8754);
  static const Color accentColor = Color(0xFF0D7148);
  static const Color backgroundColor = Colors.white;
  static const Color cardColor = Colors.white;
  static const Color textPrimaryColor = Color(0xFF1F2937);
  static const Color textSecondaryColor = Color(0xFF6B7280);
  static const Color dividerColor = Color(0xFFECF0F1);

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollController.addListener(_updateScrollPosition);
      }
    });

    _fetchAuthorContent();
  }

  void _configureTabs() {
    final category = _profile?.category?.toLowerCase() ?? '';

    _availableTabs.clear();
    _showMarsiyaTab = false;
    _showNohaTab = false;

    // Determine which tabs to show based on category
    if (category.contains('both')) {
      _availableTabs = ['Marsiya', 'Noha'];
      _showMarsiyaTab = true;
      _showNohaTab = true;
    } else if (category.contains('zakir')) {
      _availableTabs = ['Marsiya'];
      _showMarsiyaTab = true;
      _showNohaTab = false;
    } else if (category.contains('noha')) {
      _availableTabs = ['Noha'];
      _showMarsiyaTab = false;
      _showNohaTab = true;
    } else {
      // Default: show both if category is unclear
      _availableTabs = ['Marsiya', 'Noha'];
      _showMarsiyaTab = true;
      _showNohaTab = true;
    }

    // Dispose old controller if exists
    _tabController?.dispose();

    // Create new controller with correct number of tabs
    _tabController = TabController(length: _availableTabs.length, vsync: this);

    _tabController?.addListener(() {
      if (!(_tabController?.indexIsChanging ?? true)) {
        setState(() {});
      }
    });

    print('Configured tabs for ${_profile?.name}: $_availableTabs');
  }

  void _updateScrollPosition() {
    if (_scrollController.hasClients && mounted) {
      setState(() {
        _showTitle = _scrollController.offset > 180;
      });
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _scrollController.removeListener(_updateScrollPosition);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchAuthorContent() async {
    try {
      setState(() => _isLoading = true);

      final url = Uri.parse(
        'https://algodream.in/admin/api/get_author_content.php?api_key=MOHAMMADASKERYMALIKFROMNOWLARI&author_id=${widget.profileId}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['status'] == 'success') {
          final profileData = jsonData['data']['profile'];
          final marsiyaData = jsonData['data']['marsiya'] ?? [];
          final nohaData = jsonData['data']['noha'] ?? [];

          setState(() {
            _profile = ArtistItem.fromJson(profileData);
            _marsiya = marsiyaData;
            _noha = nohaData;
            _totalContentCount = marsiyaData.length + nohaData.length;
            _isLoading = false;
          });

          // Configure tabs based on artist category
          _configureTabs();

          // Auto-navigate to appropriate tab
          if (_profile?.category?.toLowerCase().contains('noha') == true &&
              _noha.isNotEmpty) {
            _tabController?.animateTo(_showMarsiyaTab ? 1 : 0);
          }

          // ✅ Track profile view when profile loads successfully (only once)
          print(
            '🔍 Profile view tracking check: _viewCounted=$_viewCounted, profileId="${widget.profileId}"',
          );
          if (!_viewCounted) {
            print(
              '🎯 Starting profile view tracking for profileId: ${widget.profileId}',
            );
            _viewCounted = true;
            _trackProfileView();
          } else {
            print('❌ Profile view tracking skipped: already counted');
          }
        } else {
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // Track Profile view using the ViewTrackingService
  Future<void> _trackProfileView() async {
    try {
      final result = await ViewTrackingService.incrementProfileView(
        widget.profileId,
      );
      if (result['success']) {
        print(
          '✅ Profile view tracked successfully: ${result['views']} total views',
        );
        // Update the profile's totalViews if needed
        if (mounted && _profile != null) {
          setState(() {
            // Update the profile's total views with the new count from server
            _profile = ArtistItem(
              id: _profile!.id,
              name: _profile!.name,
              imageUrl: _profile!.imageUrl,
              profileImage: _profile!.profileImage,
              category: _profile!.category,
              description: _profile!.description,
              totalViews: result['views'],
            );
          });
        }
      } else {
        print('❌ Failed to track Profile view: ${result['message']}');
      }
    } catch (e) {
      print('❌ Error tracking Profile view: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body:
          _isLoading
              ? _buildLoadingScreen()
              : _profile == null
              ? _buildErrorView()
              : _buildProfileView(),
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [primaryColor, primaryColor.withOpacity(0.8)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Center(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading Artist Profile',
              style: GoogleFonts.nunitoSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [primaryColor, primaryColor.withOpacity(0.8)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Icon(
                  IconlyLight.danger,
                  size: 50,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Failed to load profile',
              style: GoogleFonts.nunitoSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchAuthorContent,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: primaryColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Try Again',
                style: GoogleFonts.nunitoSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileView() {
    return NestedScrollView(
      controller: _scrollController,
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: primaryColor,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(IconlyLight.arrow_left_2, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title:
                _showTitle
                    ? Text(
                      _profile?.name ?? '',
                      style: GoogleFonts.nunitoSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                    : null,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background gradient with pattern
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [primaryColor, primaryColor.withOpacity(0.8)],
                      ),
                    ),
                    child: CustomPaint(painter: PatternPainter(opacity: 0.1)),
                  ),
                  // Profile content
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Hero(
                                tag: 'profile_${_profile?.id}',
                                child: Container(
                                  width: 110,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: _profile?.profileImage ?? '',
                                      fit: BoxFit.cover,
                                      placeholder:
                                          (context, url) => Container(
                                            color: Colors.grey.shade200,
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                color: primaryColor,
                                              ),
                                            ),
                                          ),
                                      errorWidget: (context, url, error) {
                                        // Debug: Print image loading error
                                        print(
                                          'Profile image loading error: $error',
                                        );
                                        print('Image URL: $url');
                                        return Container(
                                          color: Colors.grey.shade100,
                                          child: const Icon(
                                            IconlyLight.profile,
                                            size: 50,
                                            color: Colors.grey,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _profile?.name ?? '',
                                      style: GoogleFonts.nunitoSans(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _profile?.category ?? '',
                                        style: GoogleFonts.nunitoSans(
                                          fontSize: 14,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: _buildStatItems(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child:
                    _tabController == null
                        ? const SizedBox.shrink()
                        : TabBar(
                          controller: _tabController,
                          indicatorColor: primaryColor,
                          indicatorWeight: 3,
                          labelColor: primaryColor,
                          unselectedLabelColor: textSecondaryColor,
                          labelStyle: GoogleFonts.nunitoSans(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          unselectedLabelStyle: GoogleFonts.nunitoSans(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                          tabs:
                              _availableTabs.map((tabName) {
                                return Tab(
                                  icon: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        tabName == 'Marsiya'
                                            ? IconlyLight.document
                                            : IconlyLight.voice,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        tabName,
                                        style: GoogleFonts.nunitoSans(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                        ),
              ),
            ),
          ),
        ];
      },
      body:
          _tabController == null
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: _buildTabViews(),
              ),
    );
  }

  List<Widget> _buildTabViews() {
    List<Widget> tabViews = [];

    for (String tabName in _availableTabs) {
      if (tabName == 'Marsiya') {
        tabViews.add(_buildContentList(_marsiya, true));
      } else if (tabName == 'Noha') {
        tabViews.add(_buildContentList(_noha, false));
      }
    }

    return tabViews;
  }

  List<Widget> _buildStatItems() {
    List<Widget> stats = [];

    // Show stats based on available content and category
    if (_showMarsiyaTab && _marsiya.isNotEmpty) {
      stats.add(
        _buildStatItem(IconlyLight.document, '${_marsiya.length}', 'Marsiya'),
      );
    }

    if (_showNohaTab && _noha.isNotEmpty) {
      stats.add(_buildStatItem(IconlyLight.voice, '${_noha.length}', 'Noha'));
    }

    // Always show total views
    stats.add(
      _buildStatItem(IconlyLight.show, '${_profile?.totalViews ?? 0}', 'Views'),
    );

    // If no content stats, show placeholders
    if (stats.length == 1) {
      // Only views stat
      stats.insert(
        0,
        _buildStatItem(IconlyLight.folder, '${_totalContentCount}', 'Content'),
      );
    }

    return stats;
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.nunitoSans(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.nunitoSans(
            fontSize: 19,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildContentList(List<dynamic> content, bool isMarsiya) {
    if (content.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
                IconlyLight.voice,
                size: 50,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No ${isMarsiya ? 'Marsiya' : 'Noha'} Available',
              style: GoogleFonts.nunitoSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This artist hasn\'t uploaded any ${isMarsiya ? 'marsiya' : 'noha'} yet.',
              style: GoogleFonts.nunitoSans(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: content.length,
      itemBuilder: (context, index) {
        final item = content[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            isMarsiya
                                ? FullMarsiyaAudioPlay(
                                  audioId: item['id'].toString(),
                                )
                                : FullNohaAudioPlay(
                                  nohaId: item['id'].toString(),
                                ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl:
                                  item['image_url'] ??
                                  item['imageUrl'] ??
                                  _profile?.profileImage ??
                                  'https://algodream.in/admin/uploads/default_art.png',
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => Container(
                                    color: Colors.grey.shade100,
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: primaryColor,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                              errorWidget: (context, url, error) {
                                print('Content image loading error: $error');
                                print('Image URL: $url');
                                return Container(
                                  color: primaryColor.withOpacity(0.1),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        isMarsiya
                                            ? IconlyLight.document
                                            : IconlyLight.voice,
                                        size: 30,
                                        color: primaryColor,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        isMarsiya ? 'Marsiya' : 'Noha',
                                        style: GoogleFonts.nunitoSans(
                                          fontSize: 10,
                                          color: primaryColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
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
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'] ?? '',
                            style: GoogleFonts.nunitoSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textPrimaryColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      IconlyLight.show,
                                      size: 14,
                                      color: primaryColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${item['views'] ?? 0}',
                                      style: GoogleFonts.nunitoSans(
                                        fontSize: 12,
                                        color: primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      IconlyLight.calendar,
                                      size: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      item['uploaded_date'] != null
                                          ? DateTime.parse(
                                            item['uploaded_date'],
                                          ).toString().split(' ')[0]
                                          : '',
                                      style: GoogleFonts.nunitoSans(
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
                        ],
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, accentColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(
                        IconlyLight.play,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Pattern painter for background design
class PatternPainter extends CustomPainter {
  final double opacity;

  const PatternPainter({this.opacity = 0.05});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withOpacity(opacity)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;

    final dotPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.2)
          ..style = PaintingStyle.fill;

    final random = math.Random(42);

    // Draw some circles
    for (int i = 0; i < 40; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 1 + random.nextDouble() * 3;

      canvas.drawCircle(Offset(x, y), radius, dotPaint);
    }

    // Draw some lines
    for (int i = 0; i < 10; i++) {
      final x1 = random.nextDouble() * size.width;
      final y1 = random.nextDouble() * size.height;
      final x2 = x1 + (random.nextDouble() * 80 - 40);
      final y2 = y1 + (random.nextDouble() * 80 - 40);

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
