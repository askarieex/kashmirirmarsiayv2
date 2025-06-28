import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AboutUsScreen extends StatefulWidget {
  const AboutUsScreen({super.key});

  @override
  State<AboutUsScreen> createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen>
    with SingleTickerProviderStateMixin {
  // Colors
  static const Color primaryColor = Color(0xFF008C5F);
  static const Color accentColor = Color(0xFF00A97F);
  static const Color backgroundColor = Color(0xFFF5F5F7);
  static const Color textDark = Color(0xFF212121);
  static const Color textMedium = Color(0xFF757575);

  late AnimationController _controller;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      ),
      body: Stack(
        children: [
          // Animated background pattern
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(color: backgroundColor),
              child: CustomPaint(
                painter: BackgroundPatternPainter(
                  primaryColor: primaryColor.withOpacity(0.05),
                ),
              ),
            ),
          ),

          // Main content
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Custom app bar with animation
              SliverToBoxAdapter(child: _buildAnimatedHeader()),

              // Content sections
              SliverToBoxAdapter(child: _buildTeamSection()),

              SliverToBoxAdapter(child: _buildMissionSection()),

              SliverToBoxAdapter(child: _buildContactSection()),

              SliverToBoxAdapter(child: _buildFooter()),
            ],
          ),

          // Floating back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: _buildBackButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Container(
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
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
          ),
        )
        .animate(controller: _controller)
        .fadeIn(delay: 200.ms, duration: 400.ms)
        .slideX(
          begin: -20,
          end: 0,
          delay: 200.ms,
          duration: 400.ms,
          curve: Curves.easeOutQuad,
        );
  }

  Widget _buildAnimatedHeader() {
    return Stack(
      children: [
        // Main header background
        Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [primaryColor, accentColor],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
            )
            .animate(controller: _controller)
            .fadeIn(duration: 600.ms)
            .slideY(
              begin: -0.1,
              end: 0,
              duration: 600.ms,
              curve: Curves.easeOut,
            ),

        // Curved bottom decoration
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 30,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
          ),
        ),

        // Animated content
        Positioned(
          top: MediaQuery.of(context).padding.top + 60,
          left: 0,
          right: 0,
          child: Column(
            children: [
              // Logo container with pulse animation
              Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) => Container(
                                color: primaryColor.withOpacity(0.1),
                                child: Icon(
                                  IconlyBold.document,
                                  color: primaryColor,
                                  size: 30,
                                ),
                              ),
                        ),
                      ),
                    ),
                  )
                  .animate(controller: _controller)
                  .fadeIn(duration: 800.ms)
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1, 1),
                    duration: 800.ms,
                    curve: Curves.easeOut,
                  )
                  .shimmer(
                    color: Colors.white.withOpacity(0.3),
                    size: 0.3,
                    angle: 45,
                    duration: 1500.ms,
                    delay: 1000.ms,
                  ),

              const SizedBox(height: 20),

              // Title with typewriter effect
              Text(
                    "KASHMIRI MARSIYA",
                    style: GoogleFonts.nunitoSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  )
                  .animate(controller: _controller)
                  .fadeIn(delay: 400.ms, duration: 800.ms)
                  .shimmer(
                    delay: 400.ms,
                    duration: 1200.ms,
                    color: Colors.white.withOpacity(0.8),
                  ),

              const SizedBox(height: 5),

              // Subtitle with slide animation
              Text(
                    "Preserving Our Heritage",
                    style: GoogleFonts.nunitoSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  )
                  .animate(controller: _controller)
                  .fadeIn(delay: 500.ms, duration: 800.ms)
                  .slideY(
                    delay: 500.ms,
                    begin: 10,
                    end: 0,
                    duration: 800.ms,
                    curve: Curves.easeOutQuad,
                  ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeamSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Animated icon
          Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  IconlyBold.info_circle,
                  color: primaryColor,
                  size: 28,
                ),
              )
              .animate(controller: _controller)
              .fadeIn(delay: 600.ms, duration: 600.ms)
              .scale(
                delay: 600.ms,
                begin: const Offset(0.5, 0.5),
                end: const Offset(1.0, 1.0),
                duration: 600.ms,
                curve: Curves.elasticOut,
              ),

          const SizedBox(height: 16),

          // Section title
          Text(
                "ABOUT US",
                style: GoogleFonts.nunitoSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                  letterSpacing: 1,
                ),
              )
              .animate(controller: _controller)
              .fadeIn(delay: 700.ms, duration: 600.ms),

          const SizedBox(height: 20),

          // Content paragraphs with staggered animations
          _buildAnimatedParagraph(
            "Kashmiri Marsiya App is a community initiative dedicated to preserving and promoting great works of Kashmiri Marsiya and Nohas. Our mission is to digitalize these significant religious and cultural works, making them easily accessible to everyone.",
            delay: 800,
          ),

          const SizedBox(height: 16),

          _buildAnimatedParagraph(
            "Our team at ADTS is committed to the success of this project. We are continuously working to enhance the app and ensure these important cultural traditions endure for future generations.",
            delay: 900,
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedParagraph(String text, {required int delay}) {
    return Text(
          text,
          style: GoogleFonts.nunitoSans(
            fontSize: 15,
            height: 1.6,
            color: textMedium,
          ),
          textAlign: TextAlign.center,
        )
        .animate(controller: _controller)
        .fadeIn(delay: delay.ms, duration: 800.ms)
        .slideY(
          delay: delay.ms,
          begin: 20,
          end: 0,
          duration: 800.ms,
          curve: Curves.easeOutQuad,
        );
  }

  Widget _buildMissionSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Animated icon
          Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  IconlyBold.paper,
                  color: primaryColor,
                  size: 28,
                ),
              )
              .animate(controller: _controller)
              .fadeIn(delay: 1000.ms, duration: 600.ms)
              .scale(
                delay: 1000.ms,
                begin: const Offset(0.5, 0.5),
                end: const Offset(1.0, 1.0),
                duration: 600.ms,
                curve: Curves.elasticOut,
              ),

          const SizedBox(height: 16),

          // Section title
          Text(
                "OUR MISSION",
                style: GoogleFonts.nunitoSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                  letterSpacing: 1,
                ),
              )
              .animate(controller: _controller)
              .fadeIn(delay: 1100.ms, duration: 600.ms),

          const SizedBox(height: 20),

          // Content paragraph
          _buildAnimatedParagraph(
            "We welcome any support you can provide. If you have Marsiya or Nohas in PDF format, ideas for improvement, or wish to support us financially, please get in touch with us.",
            delay: 1200,
          ),

          const SizedBox(height: 24),

          // Call to action button with animation
          ElevatedButton.icon(
                onPressed: () => _launchWhatsApp('+917889704442'),
                icon: const Icon(IconlyBold.message, size: 20),
                label: Text(
                  "Join Our Mission",
                  style: GoogleFonts.nunitoSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              )
              .animate(controller: _controller)
              .fadeIn(delay: 1300.ms, duration: 800.ms)
              .scaleXY(
                delay: 1300.ms,
                begin: 0.9,
                end: 1,
                duration: 800.ms,
                curve: Curves.easeOutBack,
              ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
          margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.white, const Color(0xFFF9FFFC)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                spreadRadius: 1,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Section title with animated elements
              Stack(
                alignment: Alignment.center,
                children: [
                  // Background decoration
                  Positioned(
                    top: 0,
                    child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.06),
                            shape: BoxShape.circle,
                          ),
                        )
                        .animate(controller: _controller)
                        .scale(
                          delay: 1390.ms,
                          duration: 800.ms,
                          begin: const Offset(0, 0),
                          end: const Offset(1, 1),
                          curve: Curves.elasticOut,
                        ),
                  ),

                  // Main title group
                  Column(
                    children: [
                      // Icon and text
                      Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      IconlyBold.call,
                                      color: primaryColor,
                                      size: 22,
                                    ),
                                  )
                                  .animate(controller: _controller)
                                  .scale(
                                    delay: 1400.ms,
                                    duration: 600.ms,
                                    curve: Curves.elasticOut,
                                  ),

                              const SizedBox(width: 12),

                              Text(
                                "CONNECT WITH US",
                                style: GoogleFonts.nunitoSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: textDark,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          )
                          .animate(controller: _controller)
                          .fadeIn(delay: 1400.ms, duration: 600.ms),

                      // Animated underline
                      Container(
                            height: 3,
                            width: 100,
                            margin: const EdgeInsets.only(top: 10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primaryColor,
                                  primaryColor.withOpacity(0.7),
                                  primaryColor.withOpacity(0.3),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(1.5),
                            ),
                          )
                          .animate(controller: _controller)
                          .fadeIn(delay: 1450.ms, duration: 300.ms)
                          .scaleX(
                            begin: 0.2,
                            end: 1,
                            delay: 1450.ms,
                            duration: 800.ms,
                            curve: Curves.easeOutBack,
                          ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Contact cards with enhanced styling
              _buildEnhancedContactCard(
                icon: IconlyBold.message,
                title: "Email Us",
                text: 'info@algodream.in',
                onTap: () => _launchEmail('info@algodream.in'),
                delay: 1500,
              ),

              const SizedBox(height: 16),

              // Phone contact card
              _buildEnhancedContactCard(
                icon: IconlyBold.call,
                title: "Call Us",
                text: '+91 9682366790 / +91 7889704442',
                onTap: () => _launchWhatsApp('+919682366790'),
                color: const Color(0xFF25D366), // WhatsApp color
                delay: 1600,
              ),

              const SizedBox(height: 30),

              // WhatsApp button with enhanced animations
              Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 10),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        _launchWhatsApp('+917889704442');
                      },
                      icon: const Icon(IconlyBold.chat, size: 22),
                      label: Text(
                        'Message us on WhatsApp',
                        style: GoogleFonts.nunitoSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 5,
                        shadowColor: const Color(0xFF25D366).withOpacity(0.4),
                      ),
                    ),
                  )
                  .animate(controller: _controller)
                  .fadeIn(delay: 1700.ms, duration: 600.ms)
                  .shimmer(
                    delay: 2300.ms,
                    duration: 1800.ms,
                    color: Colors.white.withOpacity(0.3),
                  )
                  .slideY(delay: 1700.ms, begin: 20, end: 0, duration: 600.ms),
            ],
          ),
        )
        .animate(controller: _controller)
        .fadeIn(delay: 1350.ms, duration: 800.ms)
        .slideY(
          delay: 1350.ms,
          begin: 40,
          end: 0,
          duration: 1000.ms,
          curve: Curves.easeOutQuart,
        );
  }

  // Enhanced contact card with animation and improved styling
  Widget _buildEnhancedContactCard({
    required IconData icon,
    required String title,
    required String text,
    required VoidCallback onTap,
    required int delay,
    Color? color,
  }) {
    return InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
            decoration: BoxDecoration(
              color: (color ?? primaryColor).withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (color ?? primaryColor).withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (color ?? primaryColor).withOpacity(0.15),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (color ?? primaryColor).withOpacity(0.1),
                        blurRadius: 8,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: color ?? primaryColor, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.nunitoSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        text,
                        style: GoogleFonts.nunitoSans(
                          fontSize: 15,
                          color: textMedium,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  IconlyLight.arrow_right_circle,
                  size: 20,
                  color: (color ?? primaryColor).withOpacity(0.7),
                ),
              ],
            ),
          ),
        )
        .animate(controller: _controller)
        .fadeIn(delay: delay.ms, duration: 800.ms)
        .slideX(
          delay: delay.ms,
          begin: 30,
          end: 0,
          duration: 800.ms,
          curve: Curves.easeOutQuad,
        )
        .animate(delay: delay.ms + 600.ms)
        .shimmer(
          delay: 0.ms,
          duration: 1200.ms,
          color: (color ?? primaryColor).withOpacity(0.1),
        );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 32),
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            offset: const Offset(0, -3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
                '© ADTS All rights reserved',
                style: GoogleFonts.nunitoSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textMedium,
                ),
                textAlign: TextAlign.center,
              )
              .animate(controller: _controller)
              .fadeIn(delay: 2200.ms, duration: 600.ms),

          const SizedBox(height: 4),

          Text(
                'Version 1.0.0',
                style: GoogleFonts.nunitoSans(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              )
              .animate(controller: _controller)
              .fadeIn(delay: 2300.ms, duration: 600.ms),
        ],
      ),
    );
  }

  // URL launcher methods
  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    )) {
      debugPrint('Could not launch $url');
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailLaunchUri = Uri(scheme: 'mailto', path: email);
    launchUrl(emailLaunchUri);
  }

  Future<void> _launchWhatsApp(String phone) async {
    String url = "https://wa.me/$phone";
    if (!await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    )) {
      debugPrint('Could not launch WhatsApp');
    }
  }
}

// Background pattern painter for visual interest
class BackgroundPatternPainter extends CustomPainter {
  final Color primaryColor;

  BackgroundPatternPainter({required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = primaryColor
          ..strokeWidth = 1.5
          ..style = PaintingStyle.fill;

    const double spacing = 25;
    const double radius = 3;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
