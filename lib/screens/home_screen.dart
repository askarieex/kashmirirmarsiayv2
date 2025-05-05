import 'dart:async';
import 'dart:convert';
import 'dart:math'; // Add this import for math functions
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/wavy_header_clipper.dart';
import '../widgets/ultra_beautiful_loading_animation.dart';
import '../models/poster_item.dart';
import '../models/artist_item.dart';
import '../models/popup_message.dart'; // Import PopupMessage
import '../models/paid_promotion.dart'; // Import PaidPromotion
import '../widgets/beautiful_popup.dart'; // Import BeautifulPopup
import '../services/profile_service.dart'; // Import the profile service
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
import 'all_profiles_screen.dart'; // Add this import
import 'all_zakirs_screen.dart';
import 'all_noha_khans_screen.dart';

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
  bool _isLoadingProfiles = true;
  bool _isAdDismissed = false;

  // Updated poster and ad items
  final List<PosterItem> _posters = [];
  late List<AdBannerItem> _adItems = [];

  // Updated profile categories with proper capitalization
  Map<String, List<ArtistItem>> _profilesByCategory = {
    'Zakir': [],
    'Noha Khan': [],
    'Both': [],
  };

  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  final List<Map<String, dynamic>> features = [
    {'label': 'About Us', 'icon': Icons.info_outline},
    {'label': 'Education', 'icon': Icons.school},
    {'label': 'Contact Us', 'icon': Icons.contact_mail},
  ];

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

    // Set initial loading state
    _isLoading = true;
    _isLoadingAds = true;
    _isLoadingProfiles = true;

    // Delay data fetching to show skeleton loader
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _fetchPrayerTimes();
        _fetchPosters();
        _fetchPaidPromotions();
        _fetchProfilesByCategory();

        // Try to fetch popup message with retries
        _setupPopupMessageWithRetry();
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

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
      _isLoadingAds = true;
      _isLoadingProfiles = true;
    });

    try {
      // Add a small delay to ensure the skeleton loader is visible
      await Future.delayed(const Duration(milliseconds: 1000));
      await _fetchPrayerTimes();
      await _fetchPosters();
      await _fetchPaidPromotions();
      await _fetchProfilesByCategory();
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
        }
      } else {
        debugPrint('Failed to load posters: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching posters: $e');
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
  void _setupPopupMessageWithRetry() {
    _fetchPopupMessage();

    // Fallback - if we don't get a response or if there's an issue, try again after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      debugPrint('Checking if popup was shown...');
      // Try to show a default popup message if API call failed
      // This is just a safety measure to ensure something shows up
      _showTestPopupIfNeeded();
    });
  }

  bool _popupShown = false;

  void _showTestPopupIfNeeded() {
    if (!_popupShown && mounted) {
      debugPrint('Showing fallback test popup message');
      _showBeautifulPopup(
        context,
        'Welcome to Kashmiri Marsiya! Check out our latest content and features. Stay updated with our app for more information.',
      );
      _popupShown = true;
    }
  }

  Future<void> _fetchPopupMessage() async {
    try {
      final url = Uri.parse(
        'https://algodream.in/admin/api/get_popup_message.php',
      );

      // Mark that we're attempting to fetch the popup
      debugPrint('Attempting to fetch popup message from API');

      final response = await http.get(url);
      debugPrint('Popup message API response status: ${response.statusCode}');
      debugPrint('Popup message API response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        debugPrint('Popup message parsed JSON: $jsonData');

        if (jsonData['status'] == 'success') {
          final messageData = jsonData['data'];
          debugPrint('Popup message data: $messageData');

          final popupMessage = PopupMessage.fromJson(messageData);
          debugPrint('Popup message should display: ${popupMessage.display}');
          debugPrint('Popup message content: ${popupMessage.message}');

          setState(() {});

          if (popupMessage.display) {
            debugPrint('Should show popup: true');
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) {
                debugPrint('Showing popup now');
                _showBeautifulPopup(context, popupMessage.message);
                _popupShown = true;
              }
            });
          } else {
            debugPrint('Popup display flag is false, not showing popup');
          }
        } else {
          debugPrint(
            'Popup message API status not success: ${jsonData['status']}',
          );
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
                            // Top padding to create space
                            SliverToBoxAdapter(child: SizedBox(height: 15)),

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
                                    child: _buildQuickAccessSection(),
                                  ),
                                ),
                              ),
                            ),

                            // Sponsored Ad Banner
                            SliverToBoxAdapter(
                              child: AnimationConfiguration.staggeredList(
                                position: 2,
                                duration: const Duration(milliseconds: 800),
                                child: SlideAnimation(
                                  verticalOffset: 40,
                                  child: FadeInAnimation(
                                    child:
                                        !_isAdDismissed
                                            ? Padding(
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
                                                      : Stack(
                                                        children: [
                                                          SponsoredAdBanner(
                                                            adItems: _adItems,
                                                            height: 140,
                                                            margin:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      16,
                                                                ),
                                                          ),
                                                          Positioned(
                                                            top: 8,
                                                            right: 24,
                                                            child: GestureDetector(
                                                              onTap: () {
                                                                setState(() {
                                                                  _isAdDismissed =
                                                                      true;
                                                                });
                                                              },
                                                              child: Container(
                                                                padding:
                                                                    const EdgeInsets.all(
                                                                      4,
                                                                    ),
                                                                decoration: BoxDecoration(
                                                                  color: Colors
                                                                      .white
                                                                      .withOpacity(
                                                                        0.8,
                                                                      ),
                                                                  shape:
                                                                      BoxShape
                                                                          .circle,
                                                                ),
                                                                child: Icon(
                                                                  Icons.close,
                                                                  color:
                                                                      Colors
                                                                          .grey
                                                                          .shade700,
                                                                  size: 16,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                            )
                                            : const SizedBox.shrink(),
                                  ),
                                ),
                              ),
                            ),

                            // Top Zakirs section with adjusted spacing
                            SliverToBoxAdapter(
                              child: AnimationConfiguration.staggeredList(
                                position: 3,
                                duration: const Duration(milliseconds: 900),
                                child: SlideAnimation(
                                  verticalOffset: 50,
                                  child: FadeInAnimation(
                                    child: _buildArtistsSection(),
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

                            // Footer section
                            SliverToBoxAdapter(
                              child: AnimationConfiguration.staggeredList(
                                position: 5,
                                duration: const Duration(milliseconds: 1100),
                                child: SlideAnimation(
                                  verticalOffset: 70,
                                  child: FadeInAnimation(child: _buildFooter()),
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
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white,
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 50,
                        width: 50,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Kashmiri Marsiya',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
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
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
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
                      icon: Icons.music_note_outlined,
                      title: 'Marsiya',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MarsiyaScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.headphones_outlined,
                      title: 'Noha',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NohaScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.person_outline,
                      title: 'Zakirs',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ZakirScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.mic_outlined,
                      title: 'Noha Khans',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NohaKhanScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.event_outlined,
                      title: 'Events',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EventsScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(),
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
                      icon: Icons.history_outlined,
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
                      icon: Icons.contact_support_outlined,
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Icon(icon, color: primaryColor, size: 24),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.grey[800],
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: primaryColor,
        size: 16,
      ),
      onTap: onTap,
    );
  }

  Widget _buildHeaderSection(double screenWidth, double screenHeight) {
    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            margin: const EdgeInsets.fromLTRB(10, 5, 10, 5),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    Scaffold.of(context).openDrawer();
                  },
                  child: Icon(Icons.menu, color: primaryColor, size: 28),
                ),
                Text(
                  'Kashmiri Marsiya',
                  style: GoogleFonts.poppins(
                    color: primaryColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notifications tapped!')),
                    );
                  },
                  child: Icon(
                    Icons.notifications_none_rounded,
                    color: primaryColor,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Add a small space between the top bar and date card
        SizedBox(height: 10),

        // Islamic Date Card - Exact green style from image
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _hijriDate.isNotEmpty ? _hijriDate : '13 Shawwál 1446',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _gregorianDate.isNotEmpty
                        ? _gregorianDate
                        : '11 April 2025',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Clean Prayer Times Section - Matching exactly the UI shown
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child:
              _fajr.isEmpty &&
                      _sunrise.isEmpty &&
                      _dhuhr.isEmpty &&
                      _maghrib.isEmpty &&
                      _midnight.isEmpty
                  ? _buildPrayerTimesLoading()
                  : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPrayerTimeItem(
                        'Fajr',
                        _fajr.isNotEmpty ? _fajr : '05:09',
                        Icons.nightlight_outlined,
                      ),
                      _buildPrayerTimeItem(
                        'Sunrise',
                        _sunrise.isNotEmpty ? _sunrise : '06:05',
                        Icons.wb_sunny_outlined,
                      ),
                      _buildPrayerTimeItem(
                        'Dhuhr',
                        _dhuhr.isNotEmpty ? _dhuhr : '12:32',
                        Icons.sunny,
                      ),
                      _buildPrayerTimeItem(
                        'Maghrib',
                        _maghrib.isNotEmpty ? _maghrib : '18:59',
                        Icons.nightlight_round,
                      ),
                      _buildPrayerTimeItem(
                        'Midnight',
                        _midnight.isNotEmpty ? _midnight : '00:32',
                        Icons.bedtime_outlined,
                      ),
                    ],
                  ),
        ),
      ],
    );
  }

  Widget _buildPrayerTimeItem(String name, String time, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: primaryColor.withOpacity(0.7), size: 18),
        const SizedBox(height: 6),
        Text(
          time,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: textPrimaryColor,
          ),
        ),
        Text(
          name,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: textSecondaryColor,
          ),
        ),
      ],
    );
  }

  // Create custom QuickActionsRow widget
  Widget _buildQuickAccessSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
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
                const SizedBox(width: 10),
                Text(
                  "Quick Access",
                  style: GoogleFonts.poppins(
                    color: textPrimaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickAccessItem(
                  icon: Icons.music_note,
                  title: 'Marsiya',
                  color: const Color(0xFF00875A), // Primary green
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MarsiyaScreen(),
                      ),
                    );
                  },
                ),
                _buildQuickAccessItem(
                  icon: Icons.headphones,
                  title: 'Noha',
                  color: const Color(0xFF2196F3), // Bright blue
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NohaScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 110,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.25),
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(child: Icon(icon, color: Colors.white, size: 24)),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Explore',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w400,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.white.withOpacity(0.9),
                    size: 14,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArtistsSection() {
    return Column(
      children: [
        // Zakirs Section
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
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
                          "Top Zakirs",
                          style: GoogleFonts.poppins(
                            color: textPrimaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AllZakirsScreen(),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Text(
                            "View All",
                            style: GoogleFonts.poppins(
                              color: primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: primaryColor,
                            size: 12,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 102,
                child:
                    _isLoadingProfiles
                        ? Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                primaryColor,
                              ),
                              strokeWidth: 2,
                            ),
                          ),
                        )
                        : _profilesByCategory['Zakir']?.isEmpty ?? true
                        ? Center(
                          child: Text(
                            'No Zakirs available',
                            style: GoogleFonts.poppins(
                              color: textSecondaryColor,
                              fontSize: 14,
                            ),
                          ),
                        )
                        : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(left: 16),
                          itemCount: _profilesByCategory['Zakir']?.length ?? 0,
                          itemBuilder: (context, index) {
                            final profile =
                                _profilesByCategory['Zakir']![index];
                            return AnimationConfiguration.staggeredList(
                              position: index,
                              duration: const Duration(milliseconds: 400),
                              delay: Duration(milliseconds: 50 * index),
                              child: SlideAnimation(
                                horizontalOffset: 30,
                                child: FadeInAnimation(
                                  child: _buildEnhancedArtistCard(
                                    profile,
                                    primaryColor,
                                    "Zakir",
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        ),

        // Noha Khans Section
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Top Noha Khans",
                          style: GoogleFonts.poppins(
                            color: textPrimaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AllNohaKhansScreen(),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Text(
                            "View All",
                            style: GoogleFonts.poppins(
                              color: accentColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: accentColor,
                            size: 12,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 102,
                child:
                    _isLoadingProfiles
                        ? Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                accentColor,
                              ),
                              strokeWidth: 2,
                            ),
                          ),
                        )
                        : _profilesByCategory['Noha Khan']?.isEmpty ?? true
                        ? Center(
                          child: Text(
                            'No Noha Khans available',
                            style: GoogleFonts.poppins(
                              color: textSecondaryColor,
                              fontSize: 14,
                            ),
                          ),
                        )
                        : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(left: 16),
                          itemCount:
                              _profilesByCategory['Noha Khan']?.length ?? 0,
                          itemBuilder: (context, index) {
                            final profile =
                                _profilesByCategory['Noha Khan']![index];
                            return AnimationConfiguration.staggeredList(
                              position: index,
                              duration: const Duration(milliseconds: 400),
                              delay: Duration(milliseconds: 50 * index),
                              child: SlideAnimation(
                                horizontalOffset: 30,
                                child: FadeInAnimation(
                                  child: _buildEnhancedArtistCard(
                                    profile,
                                    accentColor,
                                    "Noha Khan",
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedArtistCard(
    ArtistItem artist,
    Color themeColor,
    String type,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewProfileScreen(profileId: artist.id),
          ),
        );
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Profile Image with animation
            TweenAnimationBuilder(
              duration: const Duration(milliseconds: 300),
              tween: Tween<double>(begin: 0.9, end: 1.0),
              builder: (context, double scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: Stack(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          themeColor.withOpacity(0.2),
                          themeColor.withOpacity(0.1),
                        ],
                      ),
                      border: Border.all(
                        color: themeColor.withOpacity(0.8),
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: artist.imageUrl,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => Container(
                              color: Colors.grey.shade100,
                              child: Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      themeColor,
                                    ),
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                        errorWidget:
                            (context, url, error) => Container(
                              color: Colors.grey.shade100,
                              child: Icon(
                                Icons.person,
                                color: Colors.grey.shade300,
                                size: 24,
                              ),
                            ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 2,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          type == "Zakir"
                              ? Icons.record_voice_over
                              : Icons.mic_external_on,
                          color: themeColor,
                          size: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Name
            Text(
              artist.name,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textPrimaryColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // Category badge
            Text(
              type,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: themeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSection(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          margin: const EdgeInsets.only(top: 8), // Added top margin for spacing
          child: Padding(
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
        ),
        // Added container with fixed height to prevent overflow
        Container(height: 210, child: _buildBannerCarousel()),
        // Rest of content remains the same
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        const SizedBox(height: 20), // Add extra space at the bottom
      ],
    );
  }

  Widget _buildBannerCarousel() {
    return Column(
      mainAxisSize: MainAxisSize.min, // Use min size to prevent expansion
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _posters.length > 0 ? _posters.length : 1,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              if (_posters.isEmpty) {
                // Handle empty state
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(
                      'No content available',
                      style: GoogleFonts.poppins(
                        color: textSecondaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }

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
        if (_posters.length >
            1) // Only show indicators if there are multiple posters
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize:
                  MainAxisSize.min, // Use min size to prevent expansion
              children: List.generate(_posters.length, (index) {
                final isActive = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 20 : 6, // Slightly smaller dots
                  height: 6, // Fixed smaller height
                  decoration: BoxDecoration(
                    color: isActive ? primaryColor : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              }),
            ),
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
                  errorBuilder: (context, error, stackTrace) {
                    print('Error loading poster image: $error');
                    return Container(
                      width: double.infinity,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                          size: 40,
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
                        fontSize: 18,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  // Add method to fetch paid promotions
  Future<void> _fetchPaidPromotions() async {
    try {
      final promotions = await PaidPromotion.fetchPaidPromotions();

      final List<AdBannerItem> adItems =
          promotions.map((promo) => promo.toAdBannerItem()).toList();

      setState(() {
        _adItems = adItems;
        _isLoadingAds = false;
      });
    } catch (e) {
      debugPrint('Error fetching paid promotions: $e');
      setState(() => _isLoadingAds = false);
    }
  }

  Future<void> _fetchProfilesByCategory() async {
    try {
      // Create Map to store profiles by category
      final Map<String, List<ArtistItem>> profiles = {
        'Zakir': [],
        'Noha Khan': [],
        'Both': [],
      };

      // Fetch recommended Zakirs
      final recommendedZakirsUrl = Uri.parse(
        'https://algodream.in/admin/api/get_recommended_zakir.php?api_key=MOHAMMADASKERYMALIKFROMNOWLARI&limit=10',
      );

      // Fetch recommended Noha Khans
      final recommendedNohaKhansUrl = Uri.parse(
        'https://algodream.in/admin/api/get_recommended_noha_khan.php?api_key=MOHAMMADASKERYMALIKFROMNOWLARI&limit=10',
      );

      // Make parallel API calls for better performance
      final zakirResponse = await http.get(recommendedZakirsUrl);
      final nohaKhanResponse = await http.get(recommendedNohaKhansUrl);

      // Process Zakirs response
      if (zakirResponse.statusCode == 200) {
        final jsonData = jsonDecode(zakirResponse.body);
        if (jsonData['status'] == 'success' && jsonData['data'] != null) {
          final List<dynamic> zakirData = jsonData['data'];
          final List<ArtistItem> zakirs =
              zakirData.map((data) => ArtistItem.fromJson(data)).toList();
          profiles['Zakir'] = zakirs;
          print('Fetched ${zakirs.length} recommended Zakirs');
        } else {
          print('No recommended Zakirs found or invalid response format');
        }
      } else {
        print(
          'Failed to fetch recommended Zakirs: ${zakirResponse.statusCode}',
        );
      }

      // Process Noha Khans response
      if (nohaKhanResponse.statusCode == 200) {
        final jsonData = jsonDecode(nohaKhanResponse.body);
        if (jsonData['status'] == 'success' && jsonData['data'] != null) {
          final List<dynamic> nohaKhanData = jsonData['data'];
          final List<ArtistItem> nohaKhans =
              nohaKhanData.map((data) => ArtistItem.fromJson(data)).toList();
          profiles['Noha Khan'] = nohaKhans;
          print('Fetched ${nohaKhans.length} recommended Noha Khans');
        } else {
          print('No recommended Noha Khans found or invalid response format');
        }
      } else {
        print(
          'Failed to fetch recommended Noha Khans: ${nohaKhanResponse.statusCode}',
        );
      }

      // If any category is empty, use profiles from the other category as fallback
      if (profiles['Zakir']!.isEmpty && profiles['Noha Khan']!.isNotEmpty) {
        print('No Zakirs found, using some Noha Khans as fallback');
        profiles['Zakir'] = [...profiles['Noha Khan']!.take(3)];
      }

      if (profiles['Noha Khan']!.isEmpty && profiles['Zakir']!.isNotEmpty) {
        print('No Noha Khans found, using some Zakirs as fallback');
        profiles['Noha Khan'] = [...profiles['Zakir']!.take(3)];
      }

      // Combined profiles for "Both" category if needed elsewhere
      profiles['Both'] = [...profiles['Zakir']!, ...profiles['Noha Khan']!];

      setState(() {
        _profilesByCategory = profiles;
        _isLoadingProfiles = false;
      });
    } catch (e) {
      debugPrint('Error fetching profiles: $e');
      setState(() => _isLoadingProfiles = false);
    }
  }

  // Build footer section
  Widget _buildFooter() {
    return Container(
      margin: const EdgeInsets.only(top: 24, bottom: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: GestureDetector(
              onTap: () => _launchUrl('https://algodream.in'),
              child: Column(
                children: [
                  // Logo image
                  ClipOval(
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/adts-circle.png',
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Designed & Developed by',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: textSecondaryColor,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'ADTS',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      color: primaryColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'https://algodream.in',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.open_in_new, color: primaryColor, size: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '© 2024 AlgoDream Technologies',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: textSecondaryColor,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not launch $url')));
    }
  }
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
