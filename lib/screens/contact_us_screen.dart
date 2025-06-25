import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconly/iconly.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final ScrollController _scrollController = ScrollController();

  // Colors
  static const Color primaryColor = Color(0xFF00875A);
  static const Color accentColor = Color(0xFF009E6A);
  static const Color backgroundColor = Color(0xFFF8FCFA);
  static const Color textDark = Color(0xFF212121);
  static const Color textLight = Color(0xFF757575);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

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
                painter: ContactBackgroundPainter(
                  primaryColor: primaryColor.withOpacity(0.04),
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

              // Contact options section
              SliverToBoxAdapter(child: _buildContactOptions()),

              // Contact form section
              SliverToBoxAdapter(child: _buildContactForm()),

              // Social connections section
              SliverToBoxAdapter(child: _buildSocialConnections()),

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
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.1),
                blurRadius: 6,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(
              IconlyLight.arrow_left,
              color: primaryColor,
              size: 22,
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
        // Main header gradient background
        Container(
              height: 250,
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
              child: Stack(
                children: [
                  // Background decorative elements
                  Positioned(
                    top: -30,
                    right: -30,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 30,
                    left: -20,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                ],
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

        // Center content for header
        Center(
          child: Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + 60),

              // Icon container with animations
              Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      IconlyBold.chat,
                      color: Colors.white,
                      size: 32,
                    ),
                  )
                  .animate(controller: _controller)
                  .fadeIn(duration: 800.ms)
                  .scale(
                    begin: const Offset(0.0, 0.0),
                    end: const Offset(1.0, 1.0),
                    duration: 800.ms,
                    curve: Curves.easeOutBack,
                  ),

              const SizedBox(height: 20),

              // Title with animated appearance
              Text(
                    "GET IN TOUCH",
                    style: GoogleFonts.nunitoSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  )
                  .animate(controller: _controller)
                  .fadeIn(delay: 400.ms, duration: 800.ms)
                  .slideY(delay: 400.ms, begin: 20, end: 0, duration: 800.ms),

              const SizedBox(height: 10),

              // Subtitle with delayed animation

              // Animated divider
              Container(
                    width: 80,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )
                  .animate(controller: _controller)
                  .fadeIn(delay: 800.ms, duration: 600.ms)
                  .scaleX(delay: 800.ms, begin: 0.2, end: 1, duration: 600.ms),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title with animation
          Row(
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
                    "CONTACT OPTIONS",
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              )
              .animate(controller: _controller)
              .fadeIn(delay: 1000.ms, duration: 600.ms)
              .slideX(delay: 1000.ms, begin: -20, end: 0, duration: 600.ms),

          const SizedBox(height: 20),

          // Contact cards row
          Row(
            children: [
              Expanded(
                child: _buildContactCard(
                  "Email Us",
                  IconlyBold.message,
                  "Send us an email anytime",
                  const Color(0xFF4285F4),
                  () => _launchEmail('info@algodream.in'),
                  1100,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildContactCard(
                  "WhatsApp",
                  IconlyBold.chat,
                  "Chat with us directly",
                  const Color(0xFF25D366),
                  () => _launchWhatsApp('+917889704442'),
                  1200,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildContactCard(
                  "Call Us",
                  IconlyBold.calling,
                  "Speak to our team",
                  const Color(0xFF00875A),
                  () => _makePhoneCall('+919682366790'),
                  1300,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(
    String title,
    IconData icon,
    String description,
    Color color,
    VoidCallback onTap,
    int delay,
  ) {
    return InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: color.withOpacity(0.1), width: 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon container with gradient
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color.withOpacity(0.8), color],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 0,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 6),

                // Description
                Text(
                  description,
                  style: GoogleFonts.nunitoSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: textLight,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        )
        .animate(controller: _controller)
        .fadeIn(delay: delay.ms, duration: 600.ms)
        .scale(
          delay: delay.ms,
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
          duration: 600.ms,
          curve: Curves.easeOutBack,
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .shimmer(
          delay: delay.ms + 1000.ms,
          duration: 1800.ms,
          color: color.withOpacity(0.1),
        );
  }

  Widget _buildContactForm() {
    return Container(
          margin: const EdgeInsets.fromLTRB(20, 30, 20, 0),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.white, const Color(0xFFF8FFFC)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.05),
                blurRadius: 15,
                spreadRadius: 0,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section title with icon
              Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          IconlyBold.paper,
                          color: primaryColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "FIND US",
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  )
                  .animate(controller: _controller)
                  .fadeIn(delay: 1400.ms, duration: 600.ms)
                  .slideY(delay: 1400.ms, begin: 10, end: 0, duration: 600.ms),

              const SizedBox(height: 24),

              // Info rows with staggered animations
              _buildInfoRow(
                IconlyBold.message,
                "Email",
                "info@algodream.in",
                () => _launchEmail('info@algodream.in'),
                1500,
              ),

              const SizedBox(height: 16),

              _buildInfoRow(
                IconlyBold.calling,
                "Phone",
                "+91 9682366790 / +91 7889704442",
                () => _makePhoneCall('+919682366790'),
                1600,
              ),

              const SizedBox(height: 16),

              _buildInfoRow(
                IconlyBold.discovery,
                "Website",
                "www.algodream.in",
                () => _launchUrl('https://algodream.in'),
                1700,
                isWebsite: true,
              ),

              const SizedBox(height: 16),

              // Feedback button
              SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          () => _launchEmail(
                            'feedback@algodream.in?subject=Feedback',
                          ),
                      icon: const Icon(IconlyBold.edit, size: 20),
                      label: Text(
                        "Send Feedback",
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  )
                  .animate(controller: _controller)
                  .fadeIn(delay: 1800.ms, duration: 600.ms)
                  .slideY(delay: 1800.ms, begin: 20, end: 0, duration: 600.ms)
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  )
                  .shimmer(
                    delay: 3000.ms,
                    duration: 2000.ms,
                    color: Colors.white.withOpacity(0.2),
                  ),
            ],
          ),
        )
        .animate(controller: _controller)
        .fadeIn(delay: 1350.ms, duration: 800.ms)
        .slideY(delay: 1350.ms, begin: 30, end: 0, duration: 800.ms);
  }

  Widget _buildInfoRow(
    IconData icon,
    String title,
    String text,
    VoidCallback onTap,
    int delay, {
    bool isWebsite = false,
  }) {
    return InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: primaryColor, size: 18),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        text,
                        style: GoogleFonts.nunitoSans(
                          fontSize: 15,
                          fontWeight:
                              isWebsite ? FontWeight.w600 : FontWeight.w400,
                          color: isWebsite ? primaryColor : textLight,
                          decoration:
                              isWebsite ? TextDecoration.underline : null,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  IconlyLight.arrow_right_circle,
                  size: 20,
                  color: primaryColor.withOpacity(0.5),
                ),
              ],
            ),
          ),
        )
        .animate(controller: _controller)
        .fadeIn(delay: delay.ms, duration: 600.ms)
        .slideX(
          delay: delay.ms,
          begin: 20,
          end: 0,
          duration: 600.ms,
          curve: Curves.easeOutQuad,
        );
  }

  Widget _buildSocialConnections() {
    return Container(
          margin: const EdgeInsets.fromLTRB(20, 30, 20, 0),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryColor.withOpacity(0.08),
                primaryColor.withOpacity(0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // Title with icon
              Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(IconlyBold.activity, color: primaryColor, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        "CONNECT WITH US",
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textDark,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  )
                  .animate(controller: _controller)
                  .fadeIn(delay: 1900.ms, duration: 600.ms),

              const SizedBox(height: 5),

              // Subtitle
              Text(
                    "Follow us on social media",
                    style: GoogleFonts.nunitoSans(
                      fontSize: 14,
                      color: textLight,
                    ),
                    textAlign: TextAlign.center,
                  )
                  .animate(controller: _controller)
                  .fadeIn(delay: 2000.ms, duration: 600.ms),

              const SizedBox(height: 24),

              // Social media icons with animations
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSocialIcon(
                    FontAwesomeIcons.facebook,
                    const Color(0xFF1877F2),
                    () => _launchUrl('https://facebook.com/kashmiri.marsiya'),
                    2100,
                  ),
                  const SizedBox(width: 20),
                  _buildSocialIcon(
                    FontAwesomeIcons.youtube,
                    const Color(0xFFFF0000),
                    () => _launchUrl('https://youtube.com/@kashmirimarsiya'),
                    2200,
                  ),
                  const SizedBox(width: 20),
                  _buildSocialIcon(
                    FontAwesomeIcons.instagram,
                    const Color(0xFFE1306C),
                    () => _launchUrl('https://instagram.com/kashmiri.marsiya'),
                    2300,
                  ),
                  const SizedBox(width: 20),
                  _buildSocialIcon(
                    FontAwesomeIcons.twitter,
                    const Color(0xFF1DA1F2),
                    () => _launchUrl('https://x.com/kashmirimarsiya'),
                    2400,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Partnership button with animation
              InkWell(
                    onTap:
                        () => _launchEmail(
                          'partners@algodream.in?subject=Partnership%20Inquiry',
                        ),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 24,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [primaryColor, accentColor],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.2),
                            blurRadius: 8,
                            spreadRadius: 0,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            IconlyBold.heart,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Partner with us",
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .animate(controller: _controller)
                  .fadeIn(delay: 2500.ms, duration: 800.ms)
                  .slideY(delay: 2500.ms, begin: 20, end: 0, duration: 800.ms)
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  )
                  .shimmer(
                    delay: 3500.ms,
                    duration: 2000.ms,
                    color: Colors.white.withOpacity(0.3),
                  ),
            ],
          ),
        )
        .animate(controller: _controller)
        .fadeIn(delay: 1850.ms, duration: 800.ms)
        .slideY(delay: 1850.ms, begin: 30, end: 0, duration: 800.ms);
  }

  Widget _buildSocialIcon(
    IconData icon,
    Color color,
    VoidCallback onTap,
    int delay,
  ) {
    return InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withOpacity(0.9), color],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: FaIcon(icon, color: Colors.white, size: 20),
          ),
        )
        .animate(controller: _controller)
        .fadeIn(delay: delay.ms, duration: 600.ms)
        .scale(
          delay: delay.ms,
          begin: const Offset(0.5, 0.5),
          end: const Offset(1.0, 1.0),
          duration: 600.ms,
          curve: Curves.easeOutBack,
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .custom(
          duration: 2000.ms,
          delay: delay.ms + 1000.ms,
          builder:
              (context, value, child) =>
                  Transform.scale(scale: 1.0 + 0.05 * value, child: child),
        );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.grey.shade50, Colors.grey.shade100],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
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
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '© ADTS All rights reserved',
            style: GoogleFonts.nunitoSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Version 1.0.0',
            style: GoogleFonts.nunitoSans(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate(controller: _controller).fadeIn(delay: 2600.ms, duration: 800.ms);
  }

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

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (!await launchUrl(phoneUri)) {
      debugPrint('Could not launch $phoneUri');
    }
  }
}

// Background pattern for visual interest
class ContactBackgroundPainter extends CustomPainter {
  final Color primaryColor;

  ContactBackgroundPainter({required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = primaryColor
          ..strokeWidth = 1.5
          ..style = PaintingStyle.fill;

    const double spacing = 30;
    const double radius = 2;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
