import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../widgets/wavy_header_clipper.dart';
import '../widgets/ultra_beautiful_loading_animation.dart';
import '../models/poster_item.dart';
import '../models/artist_item.dart';
import '../models/popup_message.dart'; // Import PopupMessage
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const Color accentTeal = Color(0xFF008F41);

  final PageController _pageController = PageController(viewportFraction: 0.9);
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

  // Popup message properties

  final List<PosterItem> _posters = [
    PosterItem(
      title: "Upcoming Event",
      imageUrl:
          "https://via.placeholder.com/600x300/aaaaaa/000000?text=Banner+1",
    ),
    PosterItem(
      title: "Latest News",
      imageUrl:
          "https://via.placeholder.com/600x300/cccccc/000000?text=Banner+2",
    ),
    PosterItem(
      title: "Announcement",
      imageUrl:
          "https://via.placeholder.com/600x300/aaaaaa/000000?text=Banner+3",
    ),
  ];

  final List<ArtistItem> _artists = [
    ArtistItem(
      name: "Zakir One",
      imageUrl: "https://via.placeholder.com/150/FF5722/FFFFFF?text=Z1",
    ),
    ArtistItem(
      name: "Noha Khan Two",
      imageUrl: "https://via.placeholder.com/150/3F51B5/FFFFFF?text=N2",
    ),
    ArtistItem(
      name: "Zakir Three",
      imageUrl: "https://via.placeholder.com/150/009688/FFFFFF?text=Z3",
    ),
    ArtistItem(
      name: "Noha Khan Four",
      imageUrl: "https://via.placeholder.com/150/E91E63/FFFFFF?text=N4",
    ),
    ArtistItem(
      name: "Zakir Five",
      imageUrl: "https://via.placeholder.com/150/4CAF50/FFFFFF?text=Z5",
    ),
    ArtistItem(
      name: "Noha Khan Six",
      imageUrl: "https://via.placeholder.com/150/2196F3/FFFFFF?text=N6",
    ),
    ArtistItem(
      name: "Zakir Seven",
      imageUrl: "https://via.placeholder.com/150/FFC107/000000?text=Z7",
    ),
    ArtistItem(
      name: "Noha Khan Eight",
      imageUrl: "https://via.placeholder.com/150/9C27B0/FFFFFF?text=N8",
    ),
    ArtistItem(
      name: "Zakir Nine",
      imageUrl: "https://via.placeholder.com/150/607D8B/FFFFFF?text=Z9",
    ),
    ArtistItem(
      name: "Noha Khan Ten",
      imageUrl: "https://via.placeholder.com/150/795548/FFFFFF?text=N10",
    ),
  ];

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

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutQuad),
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _animController.forward();
    });

    _startAutoScroll();
    _startArtistAutoScroll();

    _fetchPrayerTimes();
    _fetchPosters();
    _setupPopupMessage(); // Initialize popup message
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
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
      _currentArtistIndex = (_currentArtistIndex + 1) % _artists.length;
      const double offsetPerItem = 95.0;
      if (mounted) {
        _artistScrollController.animateTo(
          _currentArtistIndex * offsetPerItem,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _refreshData() async {
    await _fetchPrayerTimes();
    await _fetchPosters();
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
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: accentTeal),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.contact_mail),
              title: const Text('Contact Us'),
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
            ListTile(
              leading: const Icon(Icons.school),
              title: const Text('Education'),
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
          ],
        ),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshData,
            child: Container(
              color: Colors.white,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        ClipPath(
                          clipper: WavyHeaderClipper(),
                          child: Container(
                            height: 270,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.teal.shade50,
                                  Colors.teal.shade100,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                        ),
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.menu,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () {
                                        Scaffold.of(context).openDrawer();
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.notifications,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Notifications tapped!',
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    _hijriDate.isNotEmpty &&
                                            _gregorianDate.isNotEmpty
                                        ? '$_hijriDate ($_gregorianDate)'
                                        : 'Loading date...',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildPrayerTimesCard(screenWidth),
                                const SizedBox(height: 16),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    "Top Zakirs and Noha Khans",
                                    style: TextStyle(
                                      color: Colors.grey[900],
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white,
                                        Colors.teal.shade50.withOpacity(0.6),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.shade300,
                                        blurRadius: 6,
                                        offset: const Offset(2, 2),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 10,
                                    ),
                                    child: SizedBox(
                                      height: 90,
                                      child: ListView.separated(
                                        controller: _artistScrollController,
                                        scrollDirection: Axis.horizontal,
                                        physics: const BouncingScrollPhysics(),
                                        separatorBuilder:
                                            (_, __) =>
                                                const SizedBox(width: 16),
                                        itemCount: _artists.length,
                                        itemBuilder: (context, index) {
                                          final artist = _artists[index];
                                          return Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder:
                                                          (context) =>
                                                              ViewProfileScreen(
                                                                artist: artist,
                                                              ),
                                                    ),
                                                  );
                                                },
                                                child: CircleAvatar(
                                                  radius: 30,
                                                  backgroundImage: NetworkImage(
                                                    artist.imageUrl,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                artist.name,
                                                style: TextStyle(
                                                  color: Colors.grey[800],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 190,
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: _posters.length,
                              onPageChanged: (index) {
                                setState(() => _currentPage = index);
                              },
                              itemBuilder: (context, index) {
                                return _buildPosterCard(_posters[index]);
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
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                width: isActive ? 14 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isActive ? accentTeal : Colors.grey,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        child: GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 3,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          children:
                              features.map((feature) {
                                return _buildFeatureCard(
                                  feature['icon'],
                                  feature['label'],
                                );
                              }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildPrayerTimesCard(double screenWidth) {
    if (_fajr.isEmpty &&
        _sunrise.isEmpty &&
        _dhuhr.isEmpty &&
        _maghrib.isEmpty &&
        _midnight.isEmpty) {
      return Container(
        width: screenWidth * 0.9,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 6,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Text(
          'Loading prayer times...',
          style: TextStyle(color: Colors.grey[800], fontSize: 14),
        ),
      );
    }
    return Container(
      width: screenWidth * 0.9,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 6,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildPrayerTimeItem('Fajr', _fajr, Icons.wb_twighlight),
            _verticalDivider(),
            _buildPrayerTimeItem('Sunrise', _sunrise, Icons.wb_sunny),
            _verticalDivider(),
            _buildPrayerTimeItem('Dhuhr', _dhuhr, Icons.sunny),
            _verticalDivider(),
            _buildPrayerTimeItem('Maghrib', _maghrib, Icons.nightlight_round),
            _verticalDivider(),
            _buildPrayerTimeItem('Midnight', _midnight, Icons.bedtime),
          ],
        ),
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.grey.shade300,
    );
  }

  Widget _buildPrayerTimeItem(String label, String time, IconData iconData) {
    return Row(
      children: [
        Icon(iconData, color: accentTeal, size: 20),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              time,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 6,
              offset: const Offset(2, 2),
            ),
          ],
          image: DecorationImage(
            image: NetworkImage(poster.imageUrl),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [Colors.black.withOpacity(0.25), Colors.transparent],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                poster.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 3,
                      color: Colors.black45,
                    ),
                  ],
                  fontWeight: FontWeight.w600,
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
              MaterialPageRoute(builder: (context) => const MarsiyaScreen()),
            );
            break;
          case 'Noha':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NohaScreen()),
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
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 6,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: accentTeal),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: const Center(child: UltraBeautifulLoadingAnimation()),
    );
  }
}
