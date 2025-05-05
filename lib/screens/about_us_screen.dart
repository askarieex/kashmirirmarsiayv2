import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'About Us',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF00875A),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildContent(context),
              _buildContactSection(context),
              _buildWhatsAppButton(context),
              _buildSocialLinks(context),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          height: 150,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF00875A), Color(0xFF007A50)],
            ),
          ),
        ),
        Container(
          height: 25,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(8),
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
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => Container(
                        color: const Color(0xFF00875A).withOpacity(0.1),
                        child: const Icon(
                          Icons.music_note,
                          color: Color(0xFF00875A),
                          size: 50,
                        ),
                      ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'ABOUT US',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF333333),
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildParagraph(
            'Kashmiri Marsiya App is a community initiative dedicated to preserving and promoting great works of Kashmiri Marsiya and Nohas. Our mission is to digitalize these significant religious and cultural works, making them easily accessible to everyone and ensuring they endure for future generations.',
          ),
          const SizedBox(height: 16),
          _buildParagraph(
            'Our team at ADTS is committed to the success of this project. We are currently in the development stage and continuously working to enhance the app.',
          ),
          const SizedBox(height: 16),
          _buildParagraph(
            'We welcome any support you can provide. If you have Marsiya or Nohas in PDF format, ideas for improvement, or wish to support us financially, please get in touch with us.',
          ),
        ],
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 15,
        color: Colors.black87,
        height: 1.5,
      ),
      textAlign: TextAlign.justify,
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'CONNECT WITH US',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF333333),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          _buildContactTile(
            icon: Icons.email_outlined,
            text: 'info@algodream.in',
            onTap: () => _launchEmail('info@algodream.in'),
          ),
          const Divider(height: 20),
          _buildContactTile(
            icon: Icons.phone,
            text: '+91 9682366790 / +91 7889704442',
            onTap: () => _launchWhatsApp('+919682366790'),
            color: const Color(0xFF25D366), // WhatsApp color
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (color ?? const Color(0xFF00875A)).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color ?? const Color(0xFF00875A),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatsAppButton(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: ElevatedButton.icon(
        onPressed: () => _launchWhatsApp('+917889704442'),
        icon: Icon(Icons.chat_outlined, color: Colors.white),
        label: Text(
          'Message us on WhatsApp',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF25D366),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildSocialLinks(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSocialButton(
                icon: Icons.language,
                color: Colors.blue.shade800,
                onTap: () => _launchUrl('https://algodream.in'),
              ),
              _buildSocialButton(
                icon: Icons.facebook,
                color: const Color(0xFF1877F2),
                onTap:
                    () => _launchUrl('https://facebook.com/kashmiri.marsiya'),
              ),
              _buildSocialButton(
                icon: Icons.play_circle_fill,
                color: Colors.red,
                onTap: () => _launchUrl('https://youtube.com/@kashmirimarsiya'),
              ),
              _buildSocialButton(
                icon: Icons.camera_alt,
                color: const Color(0xFFE1306C),
                onTap:
                    () => _launchUrl('https://instagram.com/kashmiri.marsiya'),
              ),
              _buildSocialButton(
                icon: Icons.alternate_email,
                color: Colors.black87,
                onTap: () => _launchUrl('https://x.com/kashmirimarsiya'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF00875A).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Join us in preserving our Kashmiri culture.',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF00875A),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 26),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 32),
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Text(
            '© ADTS All rights reserved',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Version 1.0.0',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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
}
