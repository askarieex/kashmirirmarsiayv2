import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({super.key});

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animationController;
  late List<Animation<double>> _featureAnimations;

  // Enhanced color palette with better contrast and harmony
  static const Color primaryGreen = Color(0xFF0A8E3D); // Deep Islamic green
  static const Color goldAccent = Color(0xFFD4AF37);
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color textDark = Color(0xFF212529);
  static const Color textLight = Color(0xFF6C757D);

  // List of onboarding content
  final List<OnboardingContent> _contents = [
    // First section - App identity and branding
    OnboardingContent(
      title: "Kashmiri\nMarsiya",
      description:
          "Embark on a spiritual journey through the timeless traditions of Marsiya and Noha recitations",
      image: "assets/images/logo.png",
      backgroundColor: lightBackground,
      isLogo: true,
    ),

    // Second section - Key features
    OnboardingContent(
      title: "Complete Collection",
      description:
          "Access a vast library of Marsiya and Noha audio recitations along with PDF transcripts from renowned Zakirs and Noha Khans",
      backgroundColor: lightBackground,
      features: [
        "Prayer Times with Islamic & Gregorian Dates",
        "Audio Recitations with Lyrics",
        "Top Zakirs and Noha Khans Collection",
        "Latest Updates and Events Calendar",
      ],
    ),

    // Third section - Get Started button
    OnboardingContent(
      title: "Experience\nDevotion",
      description:
          "Let the essence of Karbala inspire your soul with our extensive collection",
      image: "assets/images/karbala.jpg",
      backgroundColor: lightBackground,
      useAssetImage: true,
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Create animations for each feature
    _featureAnimations = List.generate(
      _contents[1].features?.length ?? 0,
      (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            index * 0.2, // Staggered start
            min(1.0, index * 0.2 + 0.5), // Ensure it completes within bounds
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );

    // Set status bar to transparent
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    // Listen for page changes to trigger animations
    _pageController.addListener(_handlePageChange);
  }

  void _handlePageChange() {
    // If approaching or on the second page
    if (_pageController.page != null) {
      if (_pageController.page! >= 0.5 && _pageController.page! <= 1.5) {
        _animationController.forward();
      } else {
        _animationController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_handlePageChange);
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen dimensions for responsive design
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final isSmallScreen = screenSize.height < 700;
    final safeHeight = screenSize.height - padding.top - padding.bottom;

    return Scaffold(
      body: Stack(
        children: [
          // Background with enhanced gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [lightBackground.withOpacity(0.8), Colors.white],
                stops: const [0.0, 0.8],
              ),
            ),
          ),

          // Page view for swipeable content with physics
          PageView.builder(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });

              // Trigger feature animations when second page is visible
              if (page == 1) {
                _animationController.forward();
              } else {
                _animationController.reset();
              }
            },
            physics: const BouncingScrollPhysics(),
            itemCount: _contents.length,
            itemBuilder: (context, index) {
              return _buildOnboardingPage(
                _contents[index],
                isSmallScreen,
                safeHeight,
              );
            },
          ),

          // Bottom navigation area with enhanced styling
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                bottom: padding.bottom > 0 ? padding.bottom + 16 : 24,
                top: 16,
                left: 24,
                right: 24,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0),
                    Colors.white.withOpacity(0.9),
                    Colors.white,
                  ],
                  stops: const [0.0, 0.4, 0.7],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page indicator dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _contents.length,
                      (index) => _buildDotIndicator(index),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Next/Get Started button with enhanced styling
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 2,
                        shadowColor: primaryGreen.withOpacity(0.3),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        if (_currentPage < _contents.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          Navigator.pushReplacementNamed(context, '/mainNav');
                        }
                      },
                      child: Text(
                        _currentPage < _contents.length - 1
                            ? "Next"
                            : "Get Started",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  // Skip button
                  if (_currentPage < _contents.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: TextButton(
                        onPressed: () {
                          _pageController.animateToPage(
                            _contents.length - 1,
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeInOut,
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: const Text(
                          "Skip",
                          style: TextStyle(
                            color: textLight,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
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
    );
  }

  // Build individual page with improved responsive layout
  Widget _buildOnboardingPage(
    OnboardingContent content,
    bool isSmallScreen,
    double safeHeight,
  ) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            double contentHeight = safeHeight - (isSmallScreen ? 150 : 180);
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: contentHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Content section (image/logo/features) with enhanced styling
                      Expanded(
                        flex: 5,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: isSmallScreen ? 12 : 24,
                          ),
                          child:
                              content.isLogo
                                  ? _buildLogoSection(content)
                                  : content.useAssetImage
                                  ? _buildImageSection(content)
                                  : content.features != null
                                  ? _buildFeaturesSection(content)
                                  : const SizedBox.shrink(),
                        ),
                      ),

                      // Text content with enhanced typography and spacing
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Title with enhanced typography
                              Text(
                                content.title,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 28 : 32,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                  height: 1.2,
                                  letterSpacing: -0.5,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.05),
                                      offset: const Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: isSmallScreen ? 16 : 20),

                              // Description with enhanced typography
                              Text(
                                content.description,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  color: textLight,
                                  height: 1.6,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Spacer at the bottom
                      SizedBox(height: isSmallScreen ? 100 : 130),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Build logo section with enhanced animation and visual effects
  Widget _buildLogoSection(OnboardingContent content) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Animated logo container
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.8, end: 1.0),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: primaryGreen.withOpacity(0.1),
                      blurRadius: 30,
                      spreadRadius: 5,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: goldAccent.withOpacity(0.05),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Hero(
                  tag: 'appLogo',
                  child: Image.asset(content.image, fit: BoxFit.contain),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 28),

        // Enhanced tagline container
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: primaryGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: primaryGreen.withOpacity(0.2),
                      width: 1,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primaryGreen.withOpacity(0.07),
                        primaryGreen.withOpacity(0.12),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryGreen.withOpacity(0.05),
                        blurRadius: 15,
                        spreadRadius: 0,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: primaryGreen.withOpacity(0.7),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Your Spiritual Companion",
                        style: TextStyle(
                          color: primaryGreen,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
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
    );
  }

  // Build features section with improved animation logic
  Widget _buildFeaturesSection(OnboardingContent content) {
    return FractionallySizedBox(
      widthFactor: 1.0,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: primaryGreen.withOpacity(0.03),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: primaryGreen.withOpacity(0.15), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with enhanced styling
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.96, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: primaryGreen.withOpacity(0.07),
                        border: Border(
                          bottom: BorderSide(
                            color: primaryGreen.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            primaryGreen.withOpacity(0.04),
                            primaryGreen.withOpacity(0.09),
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryGreen.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.library_books,
                              size: 20,
                              color: primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "Key Features",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Features list with fixed height and improved animation
              SizedBox(
                height:
                    220, // Increased height to ensure all features are visible
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  physics: const BouncingScrollPhysics(),
                  itemCount: content.features!.length,
                  itemBuilder: (context, index) {
                    // Use explicit animation controller for better control
                    return AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        // Always show features when on page 1
                        return Opacity(
                          opacity:
                              _currentPage == 1
                                  ? _featureAnimations[index].value
                                  : 0.0,
                          child: Transform.translate(
                            offset: Offset(
                              24 *
                                  (1 -
                                      (_currentPage == 1
                                          ? _featureAnimations[index].value
                                          : 0.0)),
                              0,
                            ),
                            child: _buildFeatureItem(content.features![index]),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build image section with enhanced effects and animation
  Widget _buildImageSection(OnboardingContent content) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.92, end: 1.0),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            height: 280,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 25,
                  spreadRadius: 0,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: goldAccent.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Main image with rounded corners
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Hero(
                    tag: 'karbalaImage',
                    child: Image.asset(
                      content.image,
                      fit: BoxFit.cover,
                      height: 280,
                      width: double.infinity,
                    ),
                  ),
                ),

                // Overlay gradient for better text contrast
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.center,
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                // Border glow effect
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                ),

                // Optional inspirational quote at the bottom
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Opacity(
                    opacity: value * value,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        "Discover the timeless wisdom of tradition",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: Colors.black38,
                              offset: Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Build individual feature item with enhanced styling
  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced check icon
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: primaryGreen.withOpacity(0.05),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: const Icon(Icons.check, size: 14, color: primaryGreen),
          ),
          const SizedBox(width: 16),

          // Feature text with enhanced typography
          Expanded(
            child: Text(
              feature,
              style: const TextStyle(
                fontSize: 15,
                color: textDark,
                height: 1.4,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build enhanced dot indicator with animation
  Widget _buildDotIndicator(int index) {
    bool isActive = index == _currentPage;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 6),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? primaryGreen : Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
        boxShadow:
            isActive
                ? [
                  BoxShadow(
                    color: primaryGreen.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ]
                : null,
      ),
    );
  }
}

// Enhanced content model
class OnboardingContent {
  final String title;
  final String description;
  final String image;
  final Color backgroundColor;
  final bool useAssetImage;
  final bool isLogo;
  final List<String>? features;

  OnboardingContent({
    required this.title,
    required this.description,
    this.image = "",
    required this.backgroundColor,
    this.useAssetImage = false,
    this.isLogo = false,
    this.features,
  });
}
