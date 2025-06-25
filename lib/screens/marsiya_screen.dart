import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'full_marsiya_screen.dart';
import 'marsiya_audio_screen.dart';
import 'intikhaab_screen.dart';
import 'taht_ul_lafz_screen.dart';
import 'main_navigation_screen.dart';

class MarsiyaScreen extends StatefulWidget {
  const MarsiyaScreen({super.key});

  @override
  State<MarsiyaScreen> createState() => _MarsiyaScreenState();
}

class _MarsiyaScreenState extends State<MarsiyaScreen>
    with SingleTickerProviderStateMixin {
  // Updated color palette with more elegant purple
  static const Color primaryColor = Color(0xFF696083); // Muted purple
  static const Color backgroundColor = Color(
    0xFFF5F5F7,
  ); // Light gray background
  static const Color cardBackground = Color(0xFFF5F5F5);
  static const Color textDark = Color(0xFF212121);
  static const Color textMedium = Color(0xFF757575);

  // Icons updated with Iconly
  static const IconData audioIcon = IconlyBold.voice;
  static const IconData bookIcon = IconlyBold.document;
  static const IconData bookmarkIcon = IconlyBold.bookmark;
  static const IconData wordIcon = IconlyBold.chat;

  late AnimationController _animationController;
  final List<Animation<double>> _animations = [];

  // Sections with refined titles
  final List<Map<String, dynamic>> sections = [
    {
      'titleEn': 'Audio Recitations',
      'titleUr': 'مع وزن',
      'icon': audioIcon,
      'screen': const MarsiyaAudioScreen(),
      'color': const Color(0xFF7B2CBF), // Purple
    },
    {
      'titleEn': 'Complete Marsiya',
      'titleUr': 'مکمل مضمون',
      'icon': bookIcon,
      'screen': const FullMarsiyaScreen(),
      'color': const Color(0xFF2C7BBF), // Blue
    },
    {
      'titleEn': 'Selected Verses',
      'titleUr': 'انتخاب',
      'icon': bookmarkIcon,
      'screen': const IntikhaabScreen(),
      'color': const Color(0xFF2CBF7B), // Green
    },
    {
      'titleEn': 'Word Meanings',
      'titleUr': 'تحت اللفظ',
      'icon': wordIcon,
      'screen': const TahtUlLafzScreen(),
      'color': const Color(0xFFBF7B2C), // Orange
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Create staggered animations for each grid item
    for (int i = 0; i < sections.length; i++) {
      final start = i * 0.15;
      final end = (start + 0.4) > 1.0 ? 1.0 : (start + 0.4);
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
      backgroundColor: backgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0), // Hide default AppBar
        child: AppBar(backgroundColor: backgroundColor, elevation: 0),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Custom app bar with back button
              Padding(
                padding: const EdgeInsets.only(top: 10, left: 16, right: 16),
                child: Row(
                  children: [
                    // Back button that matches the image
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.white, const Color(0xFFF8F9FF)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.15),
                            blurRadius: 4,
                            spreadRadius: 0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(
                          IconlyLight.arrow_left,
                          color: primaryColor,
                          size: 24,
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          // Check if we're on the root or nested navigation
                          final bool canPop = Navigator.of(context).canPop();

                          if (canPop) {
                            // If we can pop, we're in a nested navigation
                            Navigator.of(context).pop();
                          } else {
                            // If we can't pop, we're likely in a tab - try to find the parent navigator
                            final MainNavigationScreenState? parentState =
                                context
                                    .findAncestorStateOfType<
                                      MainNavigationScreenState
                                    >();

                            if (parentState != null) {
                              // Found the parent, switch to home tab
                              parentState.changeTab(0); // Switch to home tab
                            } else {
                              // Fallback - try to pop from root navigator
                              Navigator.of(context, rootNavigator: true).pop();
                            }
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Marsiya Collection',
                          style: GoogleFonts.nunitoSans(
                            color: textDark,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    // Empty container for balance
                    const SizedBox(width: 40),
                  ],
                ),
              ),

              // Header section
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 16,
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [primaryColor, primaryColor.withOpacity(0.8)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.25),
                            blurRadius: 10,
                            spreadRadius: 0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        IconlyBold.document,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'Explore the rich tradition of elegiac poetry',
                      style: GoogleFonts.nunitoSans(
                        color: primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Categories heading
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 5, 16, 10),
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
                      'Browse Categories',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),

              // Grid layout with category cards (white container)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.white, const Color(0xFFF8F9FF)],
                      ),
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
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: sections.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio:
                              1.15, // Increased from 1.05 to make cards smaller
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
                            section['color'] as Color,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              // Bottom padding to ensure content is visible above tab bar if needed
              const SizedBox(height: 10),
            ],
          ),
        ],
      ),
    );
  }

  // Category card
  Widget _buildCategoryCard(
    BuildContext context,
    String titleEn,
    String titleUr,
    IconData icon,
    Widget screen,
    Animation<double> animation,
    Color cardColor,
  ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animation.value)),
          child: Opacity(
            opacity: animation.value.clamp(0.0, 1.0),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => screen,
                    maintainState: true,
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cardColor,
                      cardColor.withOpacity(0.8),
                      cardColor.withOpacity(0.6),
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: cardColor.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    children: [
                      // Background patterns
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
                        left: -15,
                        top: -15,
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
                        padding: const EdgeInsets.all(
                          10,
                        ), // Reduced padding from 12 to 10
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(
                                8,
                              ), // Reduced padding from 10 to 8
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 5,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(
                                icon,
                                size: 22, // Reduced size from 24 to 22
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              titleEn,
                              style: GoogleFonts.nunitoSans(
                                fontSize: 14, // Reduced from 15 to 14
                                fontWeight:
                                    FontWeight
                                        .w700, // Increased from w600 to w700
                                color: Colors.white, // Already bright
                                letterSpacing: 0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              titleUr,
                              style: GoogleFonts.notoNastaliqUrdu(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color:
                                    Colors
                                        .white, // Increased from withOpacity(0.8) to full white for brightness
                              ),
                              textAlign: TextAlign.left,
                              textDirection: TextDirection.rtl,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            // Small arrow indicator
                            Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                width: 22, // Reduced from 24 to 22
                                height: 22, // Reduced from 24 to 22
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(
                                    0.25,
                                  ), // Increased opacity from 0.2 to 0.25
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(
                                    IconlyLight.arrow_right,
                                    color: Colors.white,
                                    size: 12, // Reduced from 14 to 12
                                  ),
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
            ),
          ),
        );
      },
    );
  }
}
