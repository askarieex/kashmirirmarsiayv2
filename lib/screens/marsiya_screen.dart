import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'full_marsiya_screen.dart';
import 'marsiya_audio_screen.dart';
import 'intikhaab_screen.dart';
import 'taht_ul_lafz_screen.dart';
import 'main_navigation_screen.dart';

class MarsiyaScreen extends StatefulWidget {
  const MarsiyaScreen({Key? key}) : super(key: key);

  @override
  State<MarsiyaScreen> createState() => _MarsiyaScreenState();
}

class _MarsiyaScreenState extends State<MarsiyaScreen>
    with SingleTickerProviderStateMixin {
  // Updated color palette to match the image
  static const Color primaryColor = Color(0xFF008C5F);
  static const Color backgroundColor = Color(0xFFBCE4E1);
  static const Color cardBackground = Color(0xFFF5F5F5);
  static const Color textDark = Color(0xFF212121);
  static const Color textMedium = Color(0xFF757575);

  // Icons
  static const IconData audioIcon = Icons.headphones_rounded;
  static const IconData bookIcon = Icons.book_rounded;
  static const IconData bookmarkIcon = Icons.bookmark_rounded;
  static const IconData wordIcon = Icons.translate_rounded;

  late AnimationController _animationController;
  final List<Animation<double>> _animations = [];

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
      'icon': bookIcon,
      'screen': const FullMarsiyaScreen(),
    },
    {
      'titleEn': 'Selected Verses',
      'titleUr': 'انتخاب',
      'icon': bookmarkIcon,
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.chevron_left,
                          color: Colors.black,
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
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Marsiya Collection',
                          style: TextStyle(
                            color: textDark,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
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
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.menu_book,
                        color: primaryColor,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Explore the rich tradition of elegiac poetry',
                      style: TextStyle(
                        color: textDark,
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
                    const Text(
                      'Browse Categories',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textDark,
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
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
                          childAspectRatio: 1.0,
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
                  ),
                ),
              ),
              // Bottom padding to ensure content is visible above tab bar if needed
              SizedBox(height: 10),
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
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => screen,
                    maintainState: true,
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: backgroundColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 28, color: primaryColor),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        titleEn,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        titleUr,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textMedium,
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
}
