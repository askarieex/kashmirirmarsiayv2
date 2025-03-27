import 'dart:async';
import 'dart:convert';
import 'dart:math'; // Add this import for math functions
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/wavy_header_clipper.dart';
import '../widgets/ultra_beautiful_loading_animation.dart';
import '../models/poster_item.dart';
import '../models/artist_item.dart';
import '../models/popup_message.dart'; // Import PopupMessage
import '../models/paid_promotion.dart'; // Import PaidPromotion
import '../widgets/beautiful_popup.dart'; // Import BeautifulPopup
import 'view_profile_screen.dart';
import 'marsiya_screen.dart';
import 'noha_screen.dart';
import 'zakir_screen.dart';
import 'noha_khan_screen.dart';
import 'events_screen.dart';
import 'about_us_screen.dart';
import 'contact_us_screen.dart';
import 'education_screen.dart';
import 'favourites_screen.dart';
import 'help_us_screen.dart';
import 'community_screen.dart';
import 'history_screen.dart';
import '../widgets/quick_actions_bar.dart';
import '../widgets/sponsored_ad_banner.dart';
import '../widgets/skeleton_loader.dart'; // Add import for SkeletonLoader

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // Color scheme - updated for a modern aesthetic
  static const Color primaryColor = Color(0xFF00875A); // Rich green
  static const Color secondaryColor = Color(0xFF005C41); // Darker green
  static const Color accentColor = Color(0xFF4ECDC4); // Teal accent
  static const Color backgroundColor = Color(0xFFF8F9FA); // Lighter background
  static const Color textPrimaryColor = Color(0xFF212529); // Darker text
  static const Color textSecondaryColor = Color(0xFF6C757D); // Medium gray text
  static const Color cardColor = Colors.white;

  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  final ScrollController _artistScrollController = ScrollController();
  Timer? _artistAutoScrollTimer;
  int _currentArtistIndex = 0;

  String _fajr = '';
  String _sunrise = '';
  String _dhuhr = '';
  String _maghrib = '';
  String _midnight = '';

  String _hijriDate = '';
  String _gregorianDate = '';

  bool _isLoading = true;
  bool _isLoadingAds = true;

  // Popup message properties

  final List<PosterItem> _posters = [];

  final List<ArtistItem> _artists = [];

  final List<Map<String, dynamic>> features = [
    {'label': 'Marsiya', 'icon': Icons.music_note},
    {'label': 'Noha', 'icon': Icons.headphones},
    {'label': 'Zakir', 'icon': Icons.record_voice_over},
    {'label': 'Noha Khan', 'icon': Icons.mic_external_on},
    {'label': 'Events', 'icon': Icons.event},
    {'label': 'About Us', 'icon': Icons.info_outline},
    {'label': 'Education', 'icon': Icons.school},
    {'label': 'Contact Us', 'icon': Icons.contact_mail},
    {'label': 'Favourites', 'icon': Icons.favorite},
    {'label': 'Help Us', 'icon': Icons.help},
    {'label': 'Community', 'icon': Icons.group},
    {'label': 'History', 'icon': Icons.history},
  ];

  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  // Change from final to late for loading from API
  late List<AdBannerItem> _adItems = [];

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutQuint),
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _animController.forward();
    });

    _startAutoScroll();
    _startArtistAutoScroll();

    // Set initial loading state
    _isLoading = true;
    _isLoadingAds = true;

    // Delay data fetching to show skeleton loader
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _fetchPrayerTimes();
        _fetchPosters();
        _fetchArtists();
        _fetchPaidPromotions();
        _setupPopupMessage();
      }
    });
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_posters.isEmpty) return;
      _currentPage = (_currentPage + 1) % _posters.length;
      if (mounted) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _startArtistAutoScroll() {
    _artistAutoScrollTimer?.cancel();
    _artistAutoScrollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_artists.isEmpty) return;
      _currentArtistIndex = (_currentArtistIndex + 1) % _artists.length;
      const double offsetPerItem = 95.0;
      if (mounted && _artistScrollController.hasClients) {
        _artistScrollController.animateTo(
          _currentArtistIndex * offsetPerItem,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
      _isLoadingAds = true;
    });

    try {
      // Add a small delay to ensure the skeleton loader is visible
      await Future.delayed(const Duration(milliseconds: 1500));
      await _fetchPrayerTimes();
      await _fetchPosters();
      await _fetchArtists();
      await _fetchPaidPromotions();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
    return;
  }

  Future<void> _fetchPrayerTimes() async {
    try {
      final url = Uri.parse(
        'https://api.aladhan.com/v1/timingsByCity?city=Srinagar&country=India&method=12',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final timings = data['data']['timings'];
        final date = data['data']['date'];
        setState(() {
          _fajr = timings['Fajr'] ?? '';
          _sunrise = timings['Sunrise'] ?? '';
          _dhuhr = timings['Dhuhr'] ?? '';
          _maghrib = timings['Maghrib'] ?? '';
          _midnight = timings['Midnight'] ?? '';
          _hijriDate =
              '${date['hijri']['day']} ${date['hijri']['month']['en']} ${date['hijri']['year']}';
          _gregorianDate =
              '${date['gregorian']['day']} ${date['gregorian']['month']['en']} ${date['gregorian']['year']}';
          _isLoading = false;
        });
      } else {
        debugPrint('Failed to load prayer times: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching prayer times: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchPosters() async {
    try {
      final url = Uri.parse(
        'https://algodream.in/admin/api/get_posters.php?api_key=MOHAMMADASKERYMALIKFROMNOWLARI',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['status'] == 'success') {
          final List<dynamic> postersData = jsonData['data'];
          final List<PosterItem> loadedPosters =
              postersData.map((p) {
                return PosterItem(
                  title: p['poster_name'] ?? '',
                  imageUrl: p['poster_url'] ?? '',
                );
              }).toList();
          setState(() {
            _posters.clear();
            _posters.addAll(loadedPosters);
          });
          await _precachePosterImages();
        } else {
          // Clear posters if API response is not successful
          setState(() {
            _posters.clear();
          });
        }
      } else {
        debugPrint('Failed to load posters: ${response.statusCode}');
        // Clear posters if API call fails
        setState(() {
          _posters.clear();
        });
      }
    } catch (e) {
      debugPrint('Error fetching posters: $e');
      // Clear posters if any exception occurs
      setState(() {
        _posters.clear();
      });
    }
  }

  Future<void> _precachePosterImages() async {
    for (final poster in _posters) {
      if (poster.imageUrl.isNotEmpty) {
        await precacheImage(NetworkImage(poster.imageUrl), context);
      }
    }
  }

  // Popup Message Methods
  void _setupPopupMessage() {
    _fetchPopupMessage();
  }

  Future<void> _fetchPopupMessage() async {
    try {
      final url = Uri.parse(
        'https://algodream.in/admin/api/get_popup_message.php',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['status'] == 'success') {
          final messageData = jsonData['data'];
          final popupMessage = PopupMessage.fromJson(messageData);

          setState(() {});

          if (popupMessage.display) {
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) {
                _showBeautifulPopup(context, popupMessage.message);
              }
            });
          }
        }
      } else {
        debugPrint('Failed to load popup message: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching popup message: $e');
    }
  }

  void _showBeautifulPopup(BuildContext context, String message) {
    showGeneralDialog(
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      context: context,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, animation, secondaryAnimation) => Container(),
      transitionBuilder: (ctx, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutQuad,
        );

        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: BeautifulPopup(
              message: message,
              onClose: () {
                Navigator.of(ctx).pop();
              },
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageController.dispose();
    _autoScrollTimer?.cancel();
    _artistScrollController.dispose();
    _artistAutoScrollTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: backgroundColor,
      drawer: _buildBeautifulDrawer(),
      body: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: RefreshIndicator(
                color: primaryColor,
                backgroundColor: Colors.white,
                onRefresh: _refreshData,
                child:
                    _isLoading
                        ? const SkeletonLoader()
                        : CustomScrollView(
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            // Header Section with combined prayer times and calendar
                            SliverToBoxAdapter(
                              child: _buildHeaderSection(
                                screenWidth,
                                screenHeight,
                              ),
                            ),

                            // Quick Actions - with enhanced UI
                            SliverToBoxAdapter(
                              child: AnimationConfiguration.staggeredList(
                                position: 1,
                                duration: const Duration(milliseconds: 700),
                                child: SlideAnimation(
                                  verticalOffset: 30,
                                  child: FadeInAnimation(
                                    child: Container(
                                      margin: const EdgeInsets.only(
                                        left: 16,
                                        right: 16,
                                        bottom: 20,
                                        top: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.05,
                                            ),
                                            blurRadius: 8,
                                            spreadRadius: 0,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [_buildQuickActionsRow()],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Sponsored Ad Banner
                            SliverToBoxAdapter(
                              child:
                                  _adItems.isEmpty
                                      ? const SizedBox.shrink() // Hide completely if no ads available
                                      : AnimationConfiguration.staggeredList(
                                        position: 2,
                                        duration: const Duration(
                                          milliseconds: 800,
                                        ),
                                        child: SlideAnimation(
                                          verticalOffset: 40,
                                          child: FadeInAnimation(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 20,
                                              ),
                                              child:
                                                  _isLoadingAds
                                                      ? Center(
                                                        child: SizedBox(
                                                          height: 140,
                                                          child: Center(
                                                            child: CircularProgressIndicator(
                                                              valueColor:
                                                                  AlwaysStoppedAnimation<
                                                                    Color
                                                                  >(
                                                                    primaryColor,
                                                                  ),
                                                              strokeWidth: 2,
                                                            ),
                                                          ),
                                                        ),
                                                      )
                                                      : SponsoredAdBanner(
                                                        adItems: _adItems,
                                                        height: 140,
                                                        margin:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 16,
                                                            ),
                                                      ),
                                            ),
                                          ),
                                        ),
                                      ),
                            ),

                            // Top Zakirs section with adjusted spacing - always show the section title
                            SliverToBoxAdapter(
                              child: AnimationConfiguration.staggeredList(
                                position: 3,
                                duration: const Duration(milliseconds: 900),
                                child: SlideAnimation(
                                  verticalOffset: 50,
                                  child: FadeInAnimation(
                                    child: _buildTopZakirSection(),
                                  ),
                                ),
                              ),
                            ),

                            // Content section
                            SliverToBoxAdapter(
                              child: AnimationConfiguration.staggeredList(
                                position: 4,
                                duration: const Duration(milliseconds: 1000),
                                child: SlideAnimation(
                                  verticalOffset: 60,
                                  child: FadeInAnimation(
                                    child: _buildContentSection(screenWidth),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBeautifulDrawer() {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade800, primaryColor],
            stops: const [0.0, 0.8],
          ),
        ),
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.transparent),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.music_note,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Kashmiri Marsiya',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          blurRadius: 4.0,
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildDrawerItem(
                      icon: Icons.home_outlined,
                      title: 'Home',
                      onTap: () => Navigator.pop(context),
                    ),
                    _buildDrawerItem(
                      icon: Icons.favorite_outline,
                      title: 'Favorites',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FavouritesScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.contact_mail_outlined,
                      title: 'Contact Us',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ContactUsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.school_outlined,
                      title: 'Education',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EducationScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.history,
                      title: 'History',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HistoryScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.info_outline,
                      title: 'About Us',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AboutUsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.help_outline,
                      title: 'Help Us',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HelpUsScreen(),
                          ),
                        );
                      },
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

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: primaryColor, size: 22),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(double screenWidth, double screenHeight) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background decoration with enhanced pattern
              Positioned.fill(
                child: CustomPaint(painter: LightHeaderPatternPainter()),
              ),

              // Content
              Column(
                children: [
                  // Clean minimal header with just navigation icons
                  SafeArea(
                    bottom: false,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.menu,
                              color: primaryColor,
                              size: 24,
                            ),
                            onPressed: () {
                              Scaffold.of(context).openDrawer();
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.notifications_none_rounded,
                              color: primaryColor,
                              size: 24,
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Notifications tapped!'),
                                ),
                              );
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Islamic Date Card in Green
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 16,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _hijriDate.isNotEmpty
                                        ? _hijriDate
                                        : '22 Ramaḍān 1446',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    _gregorianDate.isNotEmpty
                                        ? _gregorianDate
                                        : '22 March 2025',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white.withOpacity(0.85),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Prayer Times Card
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            spreadRadius: 0,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 8,
                        ),
                        child:
                            _fajr.isEmpty &&
                                    _sunrise.isEmpty &&
                                    _dhuhr.isEmpty &&
                                    _maghrib.isEmpty &&
                                    _midnight.isEmpty
                                ? _buildPrayerTimesLoading()
                                : _buildModernPrayerTimesRow(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrayerTimesLoading() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Loading prayer times...',
          style: GoogleFonts.poppins(
            color: textSecondaryColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildModernPrayerTimesRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildModernPrayerTimeItem(
          icon: Icons.nightlight_outlined,
          time: _fajr.isNotEmpty ? _fajr : '05:38',
          label: 'Fajr',
        ),
        _buildModernPrayerTimeItem(
          icon: Icons.wb_sunny_outlined,
          time: _sunrise.isNotEmpty ? _sunrise : '06:32',
          label: 'Sunrise',
        ),
        _buildModernPrayerTimeItem(
          icon: Icons.sunny,
          time: _dhuhr.isNotEmpty ? _dhuhr : '12:38',
          label: 'Dhuhr',
        ),
        _buildModernPrayerTimeItem(
          icon: Icons.nightlight_round,
          time: _maghrib.isNotEmpty ? _maghrib : '18:44',
          label: 'Maghrib',
        ),
        _buildModernPrayerTimeItem(
          icon: Icons.bedtime_outlined,
          time: _midnight.isNotEmpty ? _midnight : '00:38',
          label: 'Midnight',
        ),
      ],
    );
  }

  Widget _buildModernPrayerTimeItem({
    required IconData icon,
    required String time,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: textSecondaryColor),
        const SizedBox(height: 6),
        Text(
          time,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textPrimaryColor,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: textSecondaryColor,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildTopZakirSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Top Zakirs and Noha Khans",
                      style: GoogleFonts.poppins(
                        color: textPrimaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () {
                    // Show snackbar instead of navigating to a new page
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Coming soon: Full profiles list'),
                        backgroundColor: primaryColor,
                      ),
                    );
                  },
                  child: Text(
                    "See All",
                    style: GoogleFonts.poppins(
                      color: primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Only show artist scrollable row if there are artists
          _artists.isEmpty
              ? Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Center(
                  child: Text(
                    "No profiles available at the moment",
                    style: GoogleFonts.poppins(
                      color: textSecondaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              )
              : SizedBox(
                height: 140,
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  itemCount: _artists.length,
                  controller: _artistScrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemBuilder: (context, index) {
                    final artist = _artists[index];
                    return Container(
                      width: 100,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              // Add debug print
                              debugPrint(
                                'Tapped profile with ID: ${artist.uniqueId}',
                              );

                              // Navigate to ViewProfileScreen with the profile data
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => ViewProfileScreen(
                                        profileId: artist.uniqueId,
                                      ),
                                ),
                              );
                            },
                            child: Container(
                              width: 75,
                              height: 75,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: primaryColor.withOpacity(0.3),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Hero(
                                tag: 'profile-${artist.uniqueId}',
                                child: ClipOval(
                                  child: Image.network(
                                    artist.imageUrl,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (
                                      context,
                                      child,
                                      loadingProgress,
                                    ) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        color: Colors.grey[100],
                                        child: const Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    primaryColor,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder:
                                        (context, url, error) => Container(
                                          color: Colors.grey[100],
                                          child: Icon(
                                            Icons.person,
                                            color: primaryColor.withOpacity(
                                              0.7,
                                            ),
                                            size: 30,
                                          ),
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  artist.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimaryColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    artist.category,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildContentSection(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Only show the banner section if posters are available
        if (_posters.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "Featured Content",
                  style: GoogleFonts.poppins(
                    color: textPrimaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          _buildBannerCarousel(),
          const SizedBox(height: 12),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "Explore",
                style: GoogleFonts.poppins(
                  color: textPrimaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        _buildFeatureGrid(),
        const SizedBox(height: 20),
        _buildFooter(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildBannerCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _posters.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 500),
                child: SlideAnimation(
                  horizontalOffset: 40.0,
                  child: FadeInAnimation(
                    child: _buildPosterCard(_posters[index]),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_posters.length, (index) {
            final isActive = index == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive ? primaryColor : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildPosterCard(PosterItem poster) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${poster.title} tapped!')));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 15,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Hero(
                tag: 'poster_${poster.title}',
                child: Image.network(
                  poster.imageUrl,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: double.infinity,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          value:
                              loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            primaryColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 15,
                left: 15,
                right: 15,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      poster.title,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            blurRadius: 3.0,
                            color: Colors.black.withOpacity(0.5),
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'Learn More',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: AnimationLimiter(
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 12,
          childAspectRatio: 1.05,
          children: List.generate(
            features.length,
            (index) => AnimationConfiguration.staggeredGrid(
              position: index,
              duration: const Duration(milliseconds: 500),
              columnCount: 3,
              child: ScaleAnimation(
                scale: 0.8,
                child: FadeInAnimation(
                  child: _buildFeatureCard(
                    features[index]['icon'],
                    features[index]['label'],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String label) {
    return GestureDetector(
      onTap: () {
        switch (label) {
          case 'Marsiya':
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder:
                    (context, animation, secondaryAnimation) =>
                        const MarsiyaScreen(),
                transitionsBuilder: (
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                ) {
                  return FadeTransition(opacity: animation, child: child);
                },
                transitionDuration: const Duration(milliseconds: 500),
              ),
            );
            break;
          case 'Noha':
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder:
                    (context, animation, secondaryAnimation) =>
                        const NohaScreen(),
                transitionsBuilder: (
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                ) {
                  return FadeTransition(opacity: animation, child: child);
                },
                transitionDuration: const Duration(milliseconds: 500),
              ),
            );
            break;
          case 'Zakir':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ZakirScreen()),
            );
            break;
          case 'Noha Khan':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NohaKhanScreen()),
            );
            break;
          case 'Events':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EventsScreen()),
            );
            break;
          case 'About Us':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AboutUsScreen()),
            );
            break;
          case 'Education':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EducationScreen()),
            );
            break;
          case 'Contact Us':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ContactUsScreen()),
            );
            break;
          case 'Favourites':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FavouritesScreen()),
            );
            break;
          case 'Help Us':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HelpUsScreen()),
            );
            break;
          case 'Community':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CommunityScreen()),
            );
            break;
          case 'History':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HistoryScreen()),
            );
            break;
          default:
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('$label tapped!')));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.12),
                    blurRadius: 6,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, size: 26, color: primaryColor),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: textPrimaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Create custom QuickActionsRow widget
  Widget _buildQuickActionsRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "Quick Access",
                style: GoogleFonts.poppins(
                  color: textPrimaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildQuickAccessCard(
                icon: Icons.music_note,
                title: 'Marsiya',
                subtitle: 'Explore',
                backgroundColor: primaryColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MarsiyaScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickAccessCard(
                icon: Icons.headphones,
                title: 'Noha',
                subtitle: 'Explore',
                backgroundColor: const Color(0xFF2C7695),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NohaScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAccessCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 130,
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              // Background decorative circles
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -15,
                left: -20,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              // Content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 22, color: Colors.white),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Add method to fetch paid promotions
  Future<void> _fetchPaidPromotions() async {
    try {
      final promotions = await PaidPromotion.fetchPaidPromotions();

      if (mounted) {
        setState(() {
          _adItems = promotions.map((promo) => promo.toAdBannerItem()).toList();
          // No more fallback ads - leave _adItems empty if no promotions found
          _isLoadingAds = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading paid promotions: $e');
      // Don't use fallback ads in case of error - leave _adItems empty
      if (mounted) {
        setState(() {
          _adItems = []; // Set to empty list instead of fallback ads
          _isLoadingAds = false;
        });
      }
    }
  }

  // Add a method to fetch artists from API
  Future<void> _fetchArtists() async {
    try {
      final url = Uri.parse(
        'https://algodream.in/admin/api/get_random_profiles.php?api_key=MOHAMMADASKERYMALIKFROMNOWLARI',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['status'] == 'success') {
          final List<dynamic> profilesData = jsonData['data'];
          final List<ArtistItem> loadedArtists =
              profilesData.map((p) {
                return ArtistItem(
                  name: p['name'] ?? '',
                  imageUrl: p['profile_image'] ?? '',
                  category: p['category'] ?? '',
                  uniqueId: p['unique_id'] ?? '',
                );
              }).toList();
          setState(() {
            _artists.clear();
            _artists.addAll(loadedArtists);
          });
        } else {
          // Clear artists if API response is not successful
          setState(() {
            _artists.clear();
          });
        }
      } else {
        debugPrint('Failed to load profiles: ${response.statusCode}');
        // Clear artists if API call fails
        setState(() {
          _artists.clear();
        });
      }
    } catch (e) {
      debugPrint('Error fetching profiles: $e');
      // Clear artists if any exception occurs
      setState(() {
        _artists.clear();
      });
    }
  }

  // Beautiful modern professional footer with team credits
  Widget _buildFooter() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main footer container with elegant design
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 55, 20, 30),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF00744E), // Slightly darker green
                const Color(0xFF00663F),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // App Branding
              Text(
                'Kashmiri Marsiya',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 5),
              Container(
                width: 70,
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Your premier source for spiritual content',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.9),
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 30),

              // Social media icons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSocialIcon(Icons.facebook),
                  _buildSocialIcon(Icons.phone_android),
                  _buildSocialIcon(Icons.send),
                  _buildSocialIcon(Icons.email_outlined),
                ],
              ),

              const SizedBox(height: 35),

              // ADTS Logo and Credits with enhanced design
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Image-based ADTS logo from assets with proper styling
                    Container(
                      height: 65,
                      width: 65,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(0xFF2C7695),
                              child: const Center(
                                child: Text(
                                  'ADTS',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Developed by Team ADTS',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textPrimaryColor,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Creating digital excellence since 2022',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: textSecondaryColor,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // Copyright notice with modern design
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.copyright,
                    size: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '2024 Kashmiri Marsiya • All Rights Reserved',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Floating app logo at the top
        Positioned(
          top: -40,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: primaryColor, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 12,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to icon if image fails to load
                      return Container(
                        height: 60,
                        width: 60,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.music_note,
                          color: Colors.white,
                          size: 34,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to build social media icons
  Widget _buildSocialIcon(IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 18),
        onPressed: () {
          // Social media action
        },
      ),
    );
  }

  // Islamic decorative corner element
  Widget _buildDecorativeCorner() {
    return SizedBox(
      width: 30,
      height: 30,
      child: CustomPaint(painter: IslamicCornerPainter(primaryColor)),
    );
  }
}

// Islamic corner decoration painter
class IslamicCornerPainter extends CustomPainter {
  final Color primaryColor;

  IslamicCornerPainter(this.primaryColor);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint =
        Paint()
          ..color = primaryColor.withOpacity(0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

    final Path path = Path();

    // Create decorative corner pattern
    path.moveTo(0, size.height * 0.5);
    path.quadraticBezierTo(
      size.width * 0.2,
      size.height * 0.5,
      size.width * 0.5,
      0,
    );

    path.moveTo(size.width * 0.5, 0);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.2,
      size.width,
      size.height * 0.5,
    );

    // Small decorative circle
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.width * 0.15,
      paint,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Add a custom painter for the header pattern
class HeaderPatternPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  HeaderPatternPainter(this.primaryColor, this.secondaryColor);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background gradient overlay
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final Paint gradientPaint =
        Paint()
          ..shader = LinearGradient(
            colors: [
              secondaryColor.withOpacity(0.6),
              primaryColor.withOpacity(0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(rect);

    canvas.drawRect(rect, gradientPaint);

    // Draw main wavy pattern
    Paint wavePaint =
        Paint()
          ..color = secondaryColor.withOpacity(0.4)
          ..style = PaintingStyle.fill;

    Path wavePath = Path();
    wavePath.moveTo(0, size.height * 0.7);

    // Create a smoother wavy path
    double amplitude = 15.0;
    double waveWidth = 35.0;
    for (int i = 0; i <= size.width.toInt(); i += 5) {
      double x = i.toDouble();
      double y = size.height * 0.7 + amplitude * sin(x / waveWidth * 3.14159);
      wavePath.lineTo(x, y);
    }

    wavePath.lineTo(size.width, size.height);
    wavePath.lineTo(0, size.height);
    wavePath.close();

    canvas.drawPath(wavePath, wavePaint);

    // Draw decorative circles
    _drawDecorativeCircles(canvas, size);
  }

  void _drawDecorativeCircles(Canvas canvas, Size size) {
    // Large translucent circles
    Paint largeBubblePaint =
        Paint()
          ..color = Colors.white.withOpacity(0.12)
          ..style = PaintingStyle.fill;

    // Small brighter circles
    Paint smallBubblePaint =
        Paint()
          ..color = Colors.white.withOpacity(0.18)
          ..style = PaintingStyle.fill;

    // Circle positions
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.3),
      25,
      largeBubblePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.25),
      20,
      largeBubblePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.8),
      30,
      largeBubblePaint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.25, size.height * 0.5),
      10,
      smallBubblePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.55),
      12,
      smallBubblePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.7),
      8,
      smallBubblePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.3, size.height * 0.8),
      15,
      smallBubblePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Light theme header pattern painter for white background
class LightHeaderPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Draw subtle light pattern
    final Paint dotPaint =
        Paint()
          ..color = const Color(0xFF00875A).withOpacity(0.05)
          ..style = PaintingStyle.fill;

    // Draw subtle dots pattern
    double dotSpacing = 25;
    double dotRadius = 4;
    for (double x = dotSpacing; x < size.width; x += dotSpacing) {
      for (double y = dotSpacing; y < size.height; y += dotSpacing) {
        // Add some randomness to dot size and opacity
        double randomFactor = 0.5 + (x * y) % 1.0;
        canvas.drawCircle(
          Offset(x, y),
          dotRadius * randomFactor,
          Paint()
            ..color = const Color(0xFF00875A).withOpacity(0.04 * randomFactor),
        );
      }
    }

    // Add a few larger decorative circles
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.5),
      20,
      Paint()..color = const Color(0xFF00875A).withOpacity(0.05),
    );

    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.2),
      15,
      Paint()..color = const Color(0xFF00875A).withOpacity(0.07),
    );

    canvas.drawCircle(
      Offset(size.width * 0.65, size.height * 0.7),
      25,
      Paint()..color = const Color(0xFF00875A).withOpacity(0.04),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
