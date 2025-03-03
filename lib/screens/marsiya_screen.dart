import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'full_marsiya_screen.dart';
import 'marsiya_audio_screen.dart';
import 'intikhaab_screen.dart';
import 'taht_ul_lafz_screen.dart';

class MarsiyaScreen extends StatefulWidget {
  const MarsiyaScreen({Key? key}) : super(key: key);

  @override
  State<MarsiyaScreen> createState() => _MarsiyaScreenState();
}

class _MarsiyaScreenState extends State<MarsiyaScreen>
    with SingleTickerProviderStateMixin {
  // Updated color palette for better visibility
  static const Color primaryColor = Color(0xFF1E5128);
  static const Color secondaryColor = Color(0xFF4E9F3D);
  static const Color textWhite = Colors.white;
  static const Color textGray = Color(0xFFE0E0E0);
  static const Color cardBackground = Color(0xFF121212);
  static const Color iconBackgroundColor = Color(0xFF2C2C2C);
  static const Color iconHighlightColor = Color(0xFF3A7D44);

  // Icons
  static const IconData audioIcon = Icons.headset_rounded;
  static const IconData marsiyaIcon = Icons.auto_stories_rounded;
  static const IconData intikhaabIcon = Icons.bookmark_rounded;
  static const IconData wordIcon = Icons.text_fields_rounded;

  late AnimationController _animationController;
  final List<Animation<double>> _animations = [];

  // Mini audio player state
  String currentSong = "Askery";
  String currentTime = "04:15";
  String totalTime = "09:49";
  bool isPlaying = true;

  // Sections with refined titles
  final List<Map<String, dynamic>> sections = [
    {
      'titleEn': 'Audio Recitations',
      'titleUr': 'مع وزن',
      'icon': audioIcon,
      'screen': const MarsiyaAudioScreen(),
    },
    {
      'titleEn': 'Complete Marsiya',
      'titleUr': 'مکمل مضمون',
      'icon': marsiyaIcon,
      'screen': const FullMarsiyaScreen(),
    },
    {
      'titleEn': 'Selected Verses',
      'titleUr': 'انتخاب',
      'icon': intikhaabIcon,
      'screen': const IntikhaabScreen(),
    },
    {
      'titleEn': 'Word Meanings',
      'titleUr': 'تحت اللفظ',
      'icon': wordIcon,
      'screen': const TahtUlLafzScreen(),
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Create staggered animations
    for (int i = 0; i < sections.length; i++) {
      final start = i * 0.15;
      final end = start + 0.4 > 1.0 ? 1.0 : start + 0.4;
      _animations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(start, end, curve: Curves.easeOut),
          ),
        ),
      );
    }

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isPortrait = size.height > size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Marsiya Collection',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // Search functionality
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(bottom: 80), // Space for the player
            children: [
              // Header section
              Container(
                color: primaryColor,
                padding: const EdgeInsets.only(bottom: 25, top: 15),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_stories_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Explore the rich tradition of elegiac poetry',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // Categories heading
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 25, 15, 20),
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
                    const Text(
                      'Browse Categories',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF212121),
                      ),
                    ),
                  ],
                ),
              ),
              // Grid layout with cards
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sections.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isPortrait ? 2 : 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.95, // Adjusted to prevent overflow
                  ),
                  itemBuilder: (context, index) {
                    final section = sections[index];
                    return _buildCategoryCard(
                      context,
                      section['titleEn'] as String,
                      section['titleUr'] as String,
                      section['icon'] as IconData,
                      section['screen'] as Widget,
                      _animations[index],
                    );
                  },
                ),
              ),
            ],
          ),
          // Mini player at bottom
          Positioned(bottom: 0, left: 0, right: 0, child: _buildMiniPlayer()),
        ],
      ),
    );
  }

  // Category card with better contrast
  Widget _buildCategoryCard(
    BuildContext context,
    String titleEn,
    String titleUr,
    IconData icon,
    Widget screen,
    Animation<double> animation,
  ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animation.value)),
          child: Opacity(
            opacity: animation.value.clamp(0.0, 1.0),
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => screen),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: cardBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: iconBackgroundColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 28, color: iconHighlightColor),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        titleEn,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textWhite,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        titleUr,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: textGray,
                        ),
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Mini player at the bottom
  Widget _buildMiniPlayer() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Album art
          Container(
            width: 60,
            height: 60,
            margin: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              image: const DecorationImage(
                image: AssetImage('assets/placeholder.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Song info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    currentSong,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$currentTime / $totalTime",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Controls
          IconButton(
            icon: const Icon(
              Icons.skip_previous,
              color: Colors.white,
              size: 28,
            ),
            onPressed: () {},
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: primaryColor,
                size: 24,
              ),
              onPressed: () {
                setState(() {
                  isPlaying = !isPlaying;
                });
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.skip_next, color: Colors.white, size: 28),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
