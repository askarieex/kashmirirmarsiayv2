import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:iconly/iconly.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'home_screen.dart';
import 'marsiya_screen.dart';
import 'noha_screen.dart';
import 'search_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => MainNavigationScreenState();
}

class MainNavigationScreenState extends State<MainNavigationScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;

  // Animation controllers for tab transitions
  late final List<AnimationController> _animationControllers;
  late final List<Animation<double>> _scaleAnimations;
  late final List<Animation<double>> _rotationAnimations;

  // Controllers for ripple effect
  late final AnimationController _rippleController;
  late final Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();

    // Create animation controllers for each tab
    _animationControllers = List.generate(
      4,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );

    // Scale animations for icons
    _scaleAnimations =
        _animationControllers
            .map(
              (controller) => Tween<double>(begin: 1.0, end: 1.2).animate(
                CurvedAnimation(parent: controller, curve: Curves.elasticOut),
              ),
            )
            .toList();

    // Rotation animations for icons
    _rotationAnimations =
        _animationControllers
            .map(
              (controller) => Tween<double>(begin: 0.0, end: 0.05).animate(
                CurvedAnimation(parent: controller, curve: Curves.easeInOut),
              ),
            )
            .toList();

    // For ripple effect when switching tabs
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    // Start animation for the initial tab
    _animationControllers[_currentIndex].forward();
  }

  @override
  void dispose() {
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    _rippleController.dispose();
    super.dispose();
  }

  // Public method to allow other widgets to change the current tab
  void changeTab(int index) {
    if (index >= 0 && index < _screens.length) {
      _switchTab(index);
    }
  }

  void _switchTab(int newIndex) {
    if (newIndex == _currentIndex) return;

    // Reset previous tab animation
    _animationControllers[_currentIndex].reverse();

    setState(() {
      _currentIndex = newIndex;
    });

    // Start ripple effect
    _rippleController.reset();
    _rippleController.forward();

    // Start new tab animation
    _animationControllers[newIndex].reset();
    _animationControllers[newIndex].forward();
  }

  // List of screens corresponding to each tab.
  late final List<Widget> _screens = [
    const HomeScreen(),
    const MarsiyaScreen(),
    const NohaScreen(),
    const SearchScreen(),
  ];

  // Theme colors for the navigation
  static const Color primaryColor = Color(0xFF696083); // Grayish purple
  static const Color secondaryColor = Color(
    0xFF837D9B,
  ); // Lighter grayish purple
  static const Color accentColor = Color(0xFF7B8C9E); // Grayish blue
  static const Color backgroundColor = Colors.white;
  static const double navBarHeight = 64.0; // Reduced height

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      drawer: _buildSideDrawer(),
      body: IndexedStack(index: _currentIndex, children: _screens),
      extendBody: true,
      bottomNavigationBar: Container(
        height:
            navBarHeight +
            (bottomInset * 0.2), // Reduced height with bottom inset
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFF5F5F7),
              const Color(0xFFEEEFF2),
            ], // More grayish
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08), // More subtle shadow
              blurRadius: 15,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Less blur
            child: Padding(
              padding: EdgeInsets.only(
                bottom: bottomInset * 0.1,
              ), // Less padding
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildEnhancedNavItem(
                    0,
                    IconlyBold.home,
                    IconlyLight.home,
                    'Home',
                  ),
                  _buildEnhancedNavItem(
                    1,
                    IconlyBold.document,
                    IconlyLight.document,
                    'Marsiya',
                  ),
                  _buildEnhancedNavItem(
                    2,
                    IconlyBold.play,
                    IconlyLight.play,
                    'Noha',
                  ),
                  _buildEnhancedNavItem(
                    3,
                    IconlyBold.search,
                    IconlyLight.search,
                    'Search',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedNavItem(
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
  ) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _switchTab(index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 2), // Less padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated icon with scaling and rotation
              AnimatedBuilder(
                animation: Listenable.merge([
                  _scaleAnimations[index],
                  _rotationAnimations[index],
                ]),
                builder: (context, child) {
                  return Transform.scale(
                    scale: isSelected ? _scaleAnimations[index].value : 1.0,
                    child: Transform.rotate(
                      angle: isSelected ? _rotationAnimations[index].value : 0,
                      child: Container(
                        padding: const EdgeInsets.all(
                          7,
                        ), // Smaller icon container
                        decoration: BoxDecoration(
                          gradient:
                              isSelected
                                  ? LinearGradient(
                                    colors: [primaryColor, secondaryColor],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                  : null,
                          color: isSelected ? null : Colors.transparent,
                          shape: BoxShape.circle,
                          boxShadow:
                              isSelected
                                  ? [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(
                                        0.2,
                                      ), // Reduced shadow opacity
                                      blurRadius: 6,
                                      spreadRadius: 0,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                  : null,
                        ),
                        child: Icon(
                          isSelected ? activeIcon : inactiveIcon,
                          color:
                              isSelected ? Colors.white : Colors.grey.shade400,
                          size: 25, // Smaller icon size
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 1), // Less space between icon and text
              // Text with animated color change
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.poppins(
                  fontSize: 12, // Smaller text
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? primaryColor : Colors.grey.shade500,
                  letterSpacing: 0.1,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSideDrawer() {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF5F5F7),
              const Color(0xFFEEEFF2),
            ], // More grayish to match nav bar
          ),
        ),
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor,
                    Color(0xFF7A778A),
                  ], // More subtle gradient
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(
                            0.08,
                          ), // More subtle shadow
                          blurRadius: 10,
                          spreadRadius: 0,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.white,
                      child: Icon(
                        IconlyBold.paper,
                        color: primaryColor,
                        size: 34,
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
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(IconlyBold.home, "Home", 0),
            _buildDrawerItem(IconlyBold.paper, "Marsiya", 1),
            _buildDrawerItem(IconlyBold.voice, "Noha", 2),
            _buildDrawerItem(IconlyBold.search, "Search", 3),
            const Divider(),
            _buildDrawerItem(IconlyLight.info_circle, "About Us", -1),
            _buildDrawerItem(IconlyLight.message, "Contact Us", -2),
            _buildDrawerItem(IconlyLight.heart, "Favorites", -3),
            _buildDrawerItem(IconlyLight.user_1, "Community", -4),
            _buildDrawerItem(IconlyLight.time_circle, "History", -5),
            const Spacer(),
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    primaryColor,
                    Color(0xFF7A778A),
                  ], // Match drawer header gradient
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08), // More subtle shadow
                    blurRadius: 8,
                    spreadRadius: 0,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(IconlyBold.star, color: Colors.white, size: 18),
                  const SizedBox(width: 12),
                  Text(
                    'Rate our app',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    IconlyLight.arrow_right,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    final bool isSelected = index == _currentIndex && index >= 0;
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          gradient:
              isSelected
                  ? const LinearGradient(
                    colors: [primaryColor, Color(0xFF7A778A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                  : null,
          color: isSelected ? null : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 4,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.grey[700],
          size: 16,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: isSelected ? primaryColor : Colors.grey[800],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          fontSize: 12,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: isSelected ? primaryColor : Colors.grey.shade400,
        size: 14,
      ),
      onTap: () {
        Navigator.pop(context);
        if (index >= 0) {
          _switchTab(index);
        } else {
          switch (index) {
            case -1:
              Navigator.pushNamed(context, '/about');
              break;
            case -2:
              Navigator.pushNamed(context, '/contact');
              break;
            case -3:
              Navigator.pushNamed(context, '/favorites');
              break;
            case -4:
              Navigator.pushNamed(context, '/community');
              break;
            case -5:
              Navigator.pushNamed(context, '/history');
              break;
          }
        }
      },
    );
  }
}
