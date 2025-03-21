import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuickActionsBar extends StatelessWidget {
  const QuickActionsBar({Key? key}) : super(key: key);

  // Define colors for consistency
  static const Color primaryColor = Color(0xFF00875A);
  static const Color primaryDarkColor = Color(0xFF005C41);
  static const Color textColor = Color(0xFF212529);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Row(
            children: [
              Container(
                height: 15,
                width: 4,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
                margin: const EdgeInsets.only(right: 8),
              ),
              Text(
                'Quick Access',
                style: GoogleFonts.poppins(
                  color: primaryColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionItem(
                context,
                'Marsiya',
                'Explore',
                Icons.music_note_rounded,
                () => _navigateToMarsiya(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickActionItem(
                context,
                'Noha',
                'Explore',
                Icons.headphones_rounded,
                () => _navigateToNoha(context),
                isAlt: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isAlt = false,
  }) {
    final Color bgColor =
        isAlt ? const Color(0xFFE8F5F0) : const Color(0xFFF0F9F6);
    final Color iconBgColor = isAlt ? primaryDarkColor : primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              spreadRadius: 0,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: textColor.withOpacity(0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: iconBgColor, size: 14),
          ],
        ),
      ),
    );
  }

  void _navigateToMarsiya(BuildContext context) {
    // Navigate to Marsiya screen
  }

  void _navigateToNoha(BuildContext context) {
    // Navigate to Noha screen
  }
}
