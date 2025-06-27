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
import '../widgets/universal_image.dart';
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
import 'community_screen.dart';
import 'history_screen.dart';
import '../widgets/quick_actions_bar.dart';
import '../widgets/sponsored_ad_banner.dart';
import '../widgets/skeleton_loader.dart'; // Add import for SkeletonLoader
import 'all_profiles_screen.dart'; // Add this import
import 'all_zakirs_screen.dart';
import 'all_noha_khans_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:iconly/iconly.dart'; // Add IconlyLight icons
import 'package:shimmer/shimmer.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'full_marsiya_audio_play.dart';
import 'full_noha_audio_play.dart';
import '../services/view_tracking_service.dart';

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
  final int _currentArtistIndex = 0;

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
  bool _isRefreshing = false;

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

  // Real data for Recommended Marsiya from API
  List<dynamic> _recommendedMarsiya = [];
  bool _isLoadingRecommendations = true;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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

    // Initialize data before the widget is displayed
    _preloadData();
  }

  // Preload data before the animation starts
  Future<void> _preloadData() async {
    // Set initial loading state
    _isLoading = true;
    _isLoadingAds = true;
    _isLoadingProfiles = true;

    try {
      // Start fetching data in parallel
      await Future.wait([
        _fetchPrayerTimes(),
        _fetchPosters(),
        _fetchPaidPromotions(),
        _fetchProfilesByCategory(),
        _fetchMarsiyaRecommendations(),
      ]);
    } catch (e) {
      debugPrint('Error preloading data: $e');
    }

    // Only animate and start auto-scroll if still mounted
    if (mounted) {
      // Now that data is loaded, start animations
      _animController.forward();
      _startAutoScroll();

      // Setup popup with retry
      _setupPopupMessageWithRetry();

      // Update the state to reflect loaded data
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_posters.isEmpty || !mounted) return;
      _currentPage = (_currentPage + 1) % _posters.length;
      if (_pageController.hasClients && mounted) {
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
      _isRefreshing = true;
      _isLoading = true;
      _isLoadingAds = true;
      _isLoadingProfiles = true;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 1000));
      await _fetchPrayerTimes();
      await _fetchPosters();
      await _fetchPaidPromotions();
      await _fetchProfilesByCategory();
    } finally {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
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

  // Fetch Marsiya Recommendations using ViewTrackingService
  Future<void> _fetchMarsiyaRecommendations() async {
    try {
      setState(() => _isLoadingRecommendations = true);

      final recommendations =
          await ViewTrackingService.getMarsiyaRecommendations();

      if (mounted) {
        setState(() {
          _recommendedMarsiya = recommendations;
          _isLoadingRecommendations = false;
        });

        print('✅ Fetched ${recommendations.length} marsiya recommendations');
      }
    } catch (e) {
      print('❌ Error fetching marsiya recommendations: $e');
      if (mounted) {
        setState(() => _isLoadingRecommendations = false);
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
  static const String _popupShownKey = 'welcome_popup_shown';

  // Check if popup has been shown before
  Future<bool> _hasPopupBeenShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_popupShownKey) ?? false;
  }

  // Mark popup as shown
  Future<void> _markPopupAsShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_popupShownKey, true);
    debugPrint('Popup marked as shown in persistent storage');
  }

  // Reset popup status (for testing purposes)
  // To test the popup again during development, call this method
  // For example: await _resetPopupStatus(); before _preloadData()
  Future<void> _resetPopupStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_popupShownKey);
    debugPrint('Popup status reset - will show again next time');
  }

  Future<void> _showTestPopupIfNeeded() async {
    // Check if popup has been shown before
    final hasBeenShown = await _hasPopupBeenShown();

    if (!hasBeenShown && !_popupShown && mounted) {
      debugPrint('Showing fallback test popup message for the first time');
      _showBeautifulPopup(
        context,
        'Welcome to Kashmiri Marsiya! Check out our latest content and features. Stay updated with our app for more information.',
      );
      _popupShown = true;
      // Mark as shown permanently
      await _markPopupAsShown();
    } else {
      debugPrint('Popup already shown before, skipping');
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
            // Check if popup has been shown before
            final hasBeenShown = await _hasPopupBeenShown();
            if (!hasBeenShown) {
              Future.delayed(const Duration(milliseconds: 800), () async {
                if (mounted) {
                  debugPrint('Showing API popup now');
                  _showBeautifulPopup(context, popupMessage.message);
                  _popupShown = true;
                  // Mark as shown permanently
                  await _markPopupAsShown();
                }
              });
            } else {
              debugPrint('API popup already shown before, skipping');
            }
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
              onClose: () async {
                Navigator.of(ctx).pop();
                // Mark popup as shown when user closes it
                await _markPopupAsShown();
                _popupShown = true;
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

    // Set the status bar to transparent with light icons
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // for Android
        statusBarBrightness: Brightness.dark, // for iOS
      ),
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: backgroundColor,
      drawer: _buildBeautifulDrawer(),
      bottomNavigationBar: _buildBottomNavigationBar(),
      body:
          _isRefreshing
              ? Container(
                color: Colors.white, // Fully opaque
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Text(
                      '–– Refreshing… ––',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              )
              : Stack(
                children: [
                  AnimatedBuilder(
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
                                          child: _buildCustomHeader(),
                                        ),

                                        // Quick Actions - with enhanced UI
                                        SliverToBoxAdapter(
                                          child: AnimationConfiguration.staggeredList(
                                            position: 1,
                                            duration: const Duration(
                                              milliseconds: 700,
                                            ),
                                            child: SlideAnimation(
                                              verticalOffset: 30,
                                              child: FadeInAnimation(
                                                child:
                                                    _buildQuickAccessSection(),
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Recommended Zakirs section with adjusted spacing
                                        SliverToBoxAdapter(
                                          child:
                                              AnimationConfiguration.staggeredList(
                                                position: 3,
                                                duration: const Duration(
                                                  milliseconds: 900,
                                                ),
                                                child: SlideAnimation(
                                                  verticalOffset: 50,
                                                  child: FadeInAnimation(
                                                    child:
                                                        _buildArtistsSection(),
                                                  ),
                                                ),
                                              ),
                                        ),

                                        // Content section
                                        SliverToBoxAdapter(
                                          child:
                                              AnimationConfiguration.staggeredList(
                                                position: 4,
                                                duration: const Duration(
                                                  milliseconds: 1000,
                                                ),
                                                child: SlideAnimation(
                                                  verticalOffset: 60,
                                                  child: FadeInAnimation(
                                                    child: _buildContentSection(
                                                      screenWidth,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                        ),

                                        // Footer section
                                        SliverToBoxAdapter(
                                          child:
                                              AnimationConfiguration.staggeredList(
                                                position: 5,
                                                duration: const Duration(
                                                  milliseconds: 1100,
                                                ),
                                                child: SlideAnimation(
                                                  verticalOffset: 70,
                                                  child: FadeInAnimation(
                                                    child: _buildFooter(),
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
                ],
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
                    style: GoogleFonts.nunitoSans(
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
                      icon: IconlyLight.home,
                      title: 'Home',
                      onTap: () => Navigator.pop(context),
                    ),
                    _buildDrawerItem(
                      icon: IconlyLight.document,
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
                      icon: IconlyLight.paper,
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
                      icon: IconlyLight.user,
                      title: 'Zakirs',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AllZakirsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: IconlyLight.user_1,
                      title: 'Noha Khans',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AllNohaKhansScreen(),
                          ),
                        );
                      },
                    ),

                    _buildDrawerItem(
                      icon: IconlyLight.info_circle,
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
                      icon: IconlyLight.message,
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

  // Add a custom bottom navigation bar using IconlyLight icons
  Widget _buildBottomNavigationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFF0F0F0), Colors.white],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B2CBF).withOpacity(0.15),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildAnimatedNavItem(IconlyBold.home, IconlyLight.home, 'Home', 0),
          _buildAnimatedNavItem(
            IconlyBold.play,
            IconlyLight.play,
            'Marsiya',
            1,
          ),
          _buildAnimatedNavItem(IconlyBold.voice, IconlyLight.voice, 'Noha', 2),
          _buildAnimatedNavItem(
            IconlyBold.search,
            IconlyLight.search,
            'Search',
            3,
          ),
        ],
      ),
    );
  }

  // Current active tab index
  int _activeTabIndex = 0;

  // Animated navigation item
  Widget _buildAnimatedNavItem(
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
    int index,
  ) {
    final bool isActive = _activeTabIndex == index;

    // Colors for animation
    final Color activeColor = const Color(0xFF7B2CBF); // Purple
    final Color inactiveColor = Colors.grey.shade400;

    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTabIndex = index;
        });

        // Handle tab changes here
        switch (index) {
          case 1: // Marsiya
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MarsiyaScreen()),
            );
            break;
          case 2: // Noha
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NohaScreen()),
            );
            break;
          case 3: // Search
            // Implement search functionality
            break;
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding:
              isActive
                  ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
                  : const EdgeInsets.all(0),
          decoration: BoxDecoration(
            color: isActive ? activeColor.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated icon with scaling effect
              TweenAnimationBuilder(
                tween: Tween<double>(
                  begin: isActive ? 0.8 : 1.0,
                  end: isActive ? 1.0 : 0.8,
                ),
                curve: Curves.easeOutBack,
                duration: const Duration(milliseconds: 400),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: ShaderMask(
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          colors:
                              isActive
                                  ? [activeColor, const Color(0xFF9747FF)]
                                  : [inactiveColor, inactiveColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds);
                      },
                      child: Icon(
                        isActive ? activeIcon : inactiveIcon,
                        color: Colors.white, // Color is applied by shader mask
                        size: 24,
                      ),
                    ),
                  );
                },
              ),

              // Animated text that shows/hides
              ClipRect(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: SizedBox(
                    width: isActive ? null : 0,
                    child: Padding(
                      padding: EdgeInsets.only(left: isActive ? 8.0 : 0),
                      child: Text(
                        isActive ? label : '',
                        style: GoogleFonts.poppins(
                          color: activeColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // This is the exact implementation from the reference code
  Widget _buildCustomHeader() {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 105, 50, 144), // purple-ish
            Color(0xFFa044ff),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1) Silhouette at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: 0.3,
              child: Image.asset(
                'assets/images/mosque_image.jpeg',
                fit: BoxFit.cover,
                height: 100,
              ),
            ),
          ),

          // 2) Row with menu & notifications icons
          Positioned(
            top: 45,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Menu icon - open drawer
                Builder(
                  builder:
                      (ctx) => IconButton(
                        onPressed: () {
                          Scaffold.of(ctx).openDrawer(); // open the drawer
                        },
                        icon: const Icon(
                          IconlyLight.category,
                          color: Colors.white,
                        ),
                      ),
                ),
                // Notification icon
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notifications tapped!')),
                    );
                  },
                  icon: const Icon(
                    IconlyLight.notification,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // 3) The date text + prayer times in the middle
          Positioned(
            left: 16,
            right: 16,
            top: 95,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The date
                Text(
                  _hijriDate.isNotEmpty ? _hijriDate : 'Loading date...',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),

                // Row of prayer times
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildPrayerTimeColumn(
                      "Fajr",
                      _fajr.isNotEmpty ? _fajr : "--:--",
                    ),
                    _buildPrayerTimeColumn(
                      "Sunrise",
                      _sunrise.isNotEmpty ? _sunrise : "--:--",
                    ),
                    _buildPrayerTimeColumn(
                      "Dhuhr",
                      _dhuhr.isNotEmpty ? _dhuhr : "--:--",
                    ),
                    _buildPrayerTimeColumn(
                      "Maghrib",
                      _maghrib.isNotEmpty ? _maghrib : "--:--",
                    ),
                    _buildPrayerTimeColumn(
                      "MidNight",
                      _midnight.isNotEmpty ? _midnight : "--:--",
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 4) Search bar overlapping at the bottom with animated text
          Positioned(
            bottom: -25,
            left: 16,
            right: 16,
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Coming Soon!',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    backgroundColor: const Color(0xFF7B2CBF), // Purple
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      IconlyLight.search,
                      color: Colors.grey.shade500,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: _buildAnimatedSearchText()),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Animated search text widget
  Widget _buildAnimatedSearchText() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(seconds: 3),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              colors: const [
                Color(0xFF7B2CBF), // Purple
                Color(0xFF9747FF), // Light purple
                Colors.blue,
                Color(0xFF7B2CBF), // Purple again
              ],
              stops: [0.0, 0.3, 0.6, 1.0],
              begin: Alignment(-1.0 + 2 * value, 0),
              end: Alignment(1.0 + 2 * value, 0),
            ).createShader(rect);
          },
          child: Text(
            "marsiya.ai",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white, // Color doesn't matter due to shader mask
            ),
          ),
        );
      },
      onEnd: () {
        // Rebuild to restart the animation when it completes
        if (mounted) setState(() {});
      },
    );
  }

  // Helper method to build a prayer time column matching the reference code
  Widget _buildPrayerTimeColumn(String label, String time) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.nunitoSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: GoogleFonts.nunitoSans(
            fontSize: 13,
            color: const Color.fromARGB(255, 255, 241, 241),
          ),
        ),
      ],
    );
  }

  // Create custom QuickActionsRow widget with only Marsiya and Noha cards
  Widget _buildQuickAccessSection() {
    return Container(
      margin: const EdgeInsets.only(top: 30, bottom: 24),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B2CBF), // Purple
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "Quick Access",
                  style: GoogleFonts.nunitoSans(
                    color: textPrimaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Only Marsiya and Noha cards with enhanced design
          Container(
            height: 160,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildEnhancedQuickAccessCard(
                    icon: IconlyBold.paper,
                    title: 'Marsiya',
                    description: 'Explore elegies and poetry',
                    color: const Color(0xFF7B2CBF), // Purple
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
                const SizedBox(width: 16),
                Expanded(
                  child: _buildEnhancedQuickAccessCard(
                    icon: IconlyBold.voice,
                    title: 'Noha',
                    description: 'Discover lamentation hymns',
                    color: const Color(0xFF2B6EFF), // Blue
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NohaScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced card design with animations
  Widget _buildEnhancedQuickAccessCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.95, end: 1.0),
        duration: const Duration(milliseconds: 300),
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color,
                    color.withOpacity(0.8),
                    color.withOpacity(0.6),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 0,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // Background decoration
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -30,
                      top: -30,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon with glow effect
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.1),
                                  blurRadius: 12,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Icon(icon, color: Colors.white, size: 24),
                          ),
                          const Spacer(),

                          // Title
                          Text(
                            title,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 5),

                          // Description
                          Text(
                            description,
                            style: GoogleFonts.nunitoSans(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Explore button
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Explore',
                              style: GoogleFonts.nunitoSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              IconlyLight.arrow_right,
                              color: Colors.white,
                              size: 14,
                            ),
                          ],
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
                          "Recommended Zakirs",
                          style: GoogleFonts.nunitoSans(
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
                            style: GoogleFonts.nunitoSans(
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
                            style: GoogleFonts.nunitoSans(
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
                          "Recommended Noha Khans",
                          style: GoogleFonts.nunitoSans(
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
                            style: GoogleFonts.nunitoSans(
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
                      child: UniversalImage(
                        imageUrl: artist.imageUrl,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        placeholder: Container(
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
                        errorWidget: Container(
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
                  style: GoogleFonts.nunitoSans(
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
        SizedBox(height: 210, child: _buildBannerCarousel()),
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
                style: GoogleFonts.nunitoSans(
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
        const SizedBox(height: 24),
        // Recommended Marsiya Section
        _buildRecommendedMarsiyaSection(),
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
            itemCount: _posters.isNotEmpty ? _posters.length : 1,
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
                      style: GoogleFonts.nunitoSans(
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
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              spreadRadius: 2,
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
                child: UniversalImage(
                  imageUrl: poster.imageUrl,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.fill,
                  placeholder: Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.purple.shade100, Colors.blue.shade100],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF7B2CBF),
                        ),
                      ),
                    ),
                  ),
                  errorWidget: Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.purple.shade50, Colors.blue.shade50],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey.shade400,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
              // Add shine effect
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.3),
                        Colors.white.withOpacity(0.0),
                        Colors.white.withOpacity(0.0),
                        Colors.white.withOpacity(0.2),
                      ],
                      stops: const [0.0, 0.3, 0.8, 1.0],
                    ),
                  ),
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
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.95,
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
                    _getColorForIndex(index),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Build Recommended Marsiya Section
  Widget _buildRecommendedMarsiyaSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7B2CBF), // Purple accent
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Recommended Marsiya",
                      style: GoogleFonts.nunitoSans(
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
                    // Navigate to Marsiya screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MarsiyaScreen(),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Text(
                        "View All",
                        style: GoogleFonts.nunitoSans(
                          color: const Color(0xFF7B2CBF),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Color(0xFF7B2CBF),
                        size: 12,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Horizontal Scrollable Cards
          SizedBox(
            height: 240, // Adjusted height for clean card design
            child:
                _isLoadingRecommendations
                    ? _buildRecommendationLoadingState()
                    : _recommendedMarsiya.isEmpty
                    ? _buildEmptyRecommendationsState()
                    : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _recommendedMarsiya.length,
                      itemBuilder: (context, index) {
                        final marsiya = _recommendedMarsiya[index];
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 600),
                          delay: Duration(milliseconds: 100 * index),
                          child: SlideAnimation(
                            horizontalOffset: 50,
                            child: FadeInAnimation(
                              child: _buildMarsiyaCard(marsiya, index),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  // Build individual Marsiya Card - Clean & Beautiful Design
  Widget _buildMarsiyaCard(Map<String, dynamic> marsiya, int index) {
    // Clean, modern color palette
    final List<List<Color>> cleanGradients = [
      [const Color(0xFF6366F1), const Color(0xFF8B5CF6)], // Indigo-Purple
      [const Color(0xFFEC4899), const Color(0xFFF97316)], // Pink-Orange
      [const Color(0xFF06B6D4), const Color(0xFF3B82F6)], // Cyan-Blue
      [const Color(0xFF10B981), const Color(0xFF059669)], // Emerald-Green
      [const Color(0xFFF59E0B), const Color(0xFFEF4444)], // Amber-Red
    ];

    final gradientColors = cleanGradients[index % cleanGradients.length];

    // Get default poster image from assets if no image_url provided
    String imageUrl = '';
    if (marsiya['image_url'] != null &&
        marsiya['image_url'].toString().isNotEmpty) {
      imageUrl = marsiya['image_url'].toString();
    }

    return GestureDetector(
      onTap: () {
        final audioId = marsiya['id']?.toString() ?? '';
        if (audioId.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FullMarsiyaAudioPlay(audioId: audioId),
            ),
          );
        }
      },
      child: Container(
        width: 180, // Slightly wider for better content
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.15),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section with better design
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                ),
                child: Stack(
                  children: [
                    // Background pattern
                    Positioned(
                      right: -15,
                      top: -15,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -10,
                      bottom: -10,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),

                    // Main image or default poster
                    if (imageUrl.isNotEmpty)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) => Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: gradientColors,
                                    ),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                            errorWidget:
                                (context, url, error) => Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: gradientColors,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      IconlyBold.document,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  ),
                                ),
                          ),
                        ),
                      )
                    else
                      // Default beautiful poster with Islamic/Marsiya theme
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: gradientColors,
                            ),
                          ),
                          child: Stack(
                            children: [
                              // Islamic pattern background
                              Center(
                                child: Icon(
                                  IconlyBold.document,
                                  color: Colors.white.withOpacity(0.3),
                                  size: 50,
                                ),
                              ),
                              // Beautiful overlay text
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.mosque_outlined,
                                      color: Colors.white.withOpacity(0.8),
                                      size: 32,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'مرثیہ',
                                      style: GoogleFonts.inter(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Play button overlay
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          IconlyBold.play,
                          color: gradientColors[0],
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content Section - Clean and minimalist
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        marsiya['title'] ?? 'Unknown Title',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF1F2937),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      // Author
                      Text(
                        marsiya['manual_author']?.toString().isNotEmpty == true
                            ? marsiya['manual_author']
                            : marsiya['author_name'] ?? 'Unknown Artist',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF6B7280),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const Spacer(),

                      // Bottom info - Clean design
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Duration
                          Row(
                            children: [
                              Icon(
                                IconlyLight.time_circle,
                                color: const Color(0xFF9CA3AF),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                marsiya['duration'] ?? '--:--',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF6B7280),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),

                          // Views
                          Row(
                            children: [
                              Icon(
                                IconlyLight.show,
                                color: const Color(0xFF9CA3AF),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                ViewTrackingService.formatViewCount(
                                  int.tryParse(
                                        marsiya['views']?.toString() ?? '0',
                                      ) ??
                                      0,
                                ),
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF6B7280),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
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
            ],
          ),
        ),
      ),
    );
  }

  // Build recommendation loading state - Updated for clean design
  Widget _buildRecommendationLoadingState() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: 3, // Show 3 skeleton loaders
      itemBuilder: (context, index) {
        return Container(
          width: 180,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder - matches new height
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
              ),

              // Content section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title placeholder
                      Container(
                        height: 16,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Second line of title
                      Container(
                        height: 16,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Author placeholder
                      Container(
                        height: 14,
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),

                      const Spacer(),

                      // Bottom info placeholder
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            height: 12,
                            width: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          Container(
                            height: 12,
                            width: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Build empty recommendations state
  Widget _buildEmptyRecommendationsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(IconlyLight.document, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No recommendations available',
            style: GoogleFonts.nunitoSans(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for personalized content',
            style: GoogleFonts.nunitoSans(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForIndex(int index) {
    final List<Color> colors = [
      const Color(0xFF7B2CBF), // Purple
      const Color(0xFF2C7BBF), // Blue
      const Color(0xFF2CBF7B), // Green
      const Color(0xFFBF7B2C), // Orange
      const Color(0xFFBF2C7B), // Pink
      const Color(0xFF7B2CBF), // Purple again
    ];
    return colors[index % colors.length];
  }

  Widget _buildFeatureCard(IconData icon, String label, Color themeColor) {
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              themeColor,
              themeColor.withOpacity(0.8),
              themeColor.withOpacity(0.6),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: themeColor.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              // Background decoration pattern
              Positioned(
                right: -20,
                bottom: -20,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                left: -15,
                top: -15,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            spreadRadius: 0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _getIconlyIcon(label, Colors.white),
                    ),
                    const Spacer(),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              // Small arrow at bottom
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      IconlyLight.arrow_right,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getIconlyIcon(String label, Color color) {
    switch (label) {
      case 'About Us':
        return Icon(IconlyBold.info_circle, color: color, size: 24);
      case 'Education':
        return Icon(IconlyBold.document, color: color, size: 24);
      case 'Contact Us':
        return Icon(IconlyBold.chat, color: color, size: 24);
      default:
        return Icon(IconlyBold.star, color: color, size: 24);
    }
  }

  // Build footer section
  Widget _buildFooter() {
    return Container(
      margin: const EdgeInsets.only(top: 24, bottom: 24),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Background design
              Container(
                height: 180,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color.fromARGB(255, 41, 2, 75).withOpacity(0.8),
                      const Color.fromARGB(255, 31, 3, 67).withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 1,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Stack(
                    children: [
                      // Abstract pattern overlay
                      Positioned(
                        right: -30,
                        bottom: -30,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                      Positioned(
                        left: -20,
                        top: -20,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                      // Shimmering effect layer
                      Positioned.fill(
                        child: ShaderMask(
                          shaderCallback: (rect) {
                            return LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.1),
                                Colors.white.withOpacity(0.05),
                                Colors.white.withOpacity(0.0),
                              ],
                            ).createShader(rect);
                          },
                          child: Container(color: Colors.white),
                        ),
                      ),

                      // Tap indicator
                      Positioned(
                        bottom: 15,
                        right: 15,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Visit',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                IconlyLight.arrow_right_circle,
                                color: Colors.white,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content overlaid on top
              GestureDetector(
                onTap: () => _launchUrl('https://algodream.in'),
                child: Column(
                  children: [
                    // Logo with glowing effect
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.8),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/adts-circle.png',
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Tagline with gradient
                    ShaderMask(
                      shaderCallback: (rect) {
                        return LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.white, Colors.white.withOpacity(0.9)],
                        ).createShader(rect);
                      },
                      child: Text(
                        'Designed & Developed by',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Company name with dramatic styling
                    Text(
                      'ADTS',
                      style: GoogleFonts.poppins(
                        fontSize: 30,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3.0,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Website URL with sleek styling
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'algodream.in',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '© 2025 AlgoDream Technical Services',
            style: GoogleFonts.nunitoSans(
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

  // Build Prayer Times Loading widget
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

      // ✅ FIXED: Remove problematic fallback logic to maintain proper categorization
      // Each artist should only appear in their correct category
      // Empty categories will show "No content available" message instead of wrong data

      // Categories remain strictly separated - no cross-mixing
      print(
        'Final counts: ${profiles['Zakir']!.length} Zakirs, ${profiles['Noha Khan']!.length} Noha Khans',
      );

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
