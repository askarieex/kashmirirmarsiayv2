import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'dart:ui' as ui;

class TahtUlLafzScreen extends StatelessWidget {
  const TahtUlLafzScreen({super.key});

  static const Color accentTeal = Color(0xFF008F41);
  static const Color backgroundColor = Color(0xFFF2F7F7);

  final List<Map<String, String>> marsiyaList = const [
    {
      'title': 'مضمون قرآن نویں',
      'author': 'Irfan Haider',
      'duration': '4:08',
      'views': '9.2K',
      'language': 'Urdu',
      'type': 'pdf',
      'hasDownload': 'false',
    },
    {
      'title': 'مضمون ساز حمید',
      'author': 'Syed Raza Abbas Zaidi',
      'duration': '3:45',
      'views': '7.8K',
      'language': 'Urdu',
      'type': 'pdf',
      'hasDownload': 'false',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: backgroundColor,
        title: Text(
          'تحت اللفظ - Taht ul Lafz',
          style: GoogleFonts.nunitoSans(
            color: accentTeal,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(IconlyLight.arrow_left, color: accentTeal, size: 26),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: marsiyaList.length,
          itemBuilder: (context, index) {
            final item = marsiyaList[index];
            return _buildMarsiyaItem(item);
          },
        ),
      ),
    );
  }

  Widget _buildMarsiyaItem(Map<String, String> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: accentTeal.withOpacity(0.08),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: accentTeal.withOpacity(0.05), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Leading Icon Container
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentTeal, accentTeal.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: accentTeal.withOpacity(0.2),
                    blurRadius: 6,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                IconlyLight.document,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Content Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title with elegant text styling
                  Text(
                    item['title'] ?? '',
                    style: GoogleFonts.notoNastaliqUrdu(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      height: 1.9,
                    ),
                    textDirection: ui.TextDirection.rtl,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Author
                  Text(
                    'By ${item['author'] ?? ''}',
                    style: GoogleFonts.nunitoSans(
                      color: Colors.teal.shade700,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Stats row with smaller icons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDetailChip(
                        IconlyLight.time_circle,
                        item['duration'] ?? '',
                        Colors.teal.shade600,
                      ),
                      const SizedBox(width: 8),
                      _buildDetailChip(
                        IconlyLight.show,
                        item['views'] ?? '',
                        Colors.teal.shade600,
                      ),
                      const SizedBox(width: 8),
                      _buildDetailChip(
                        IconlyLight.document,
                        item['language'] ?? '',
                        Colors.teal.shade600,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Play Button
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: accentTeal.withOpacity(0.15),
                    blurRadius: 4,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(IconlyLight.play, color: accentTeal, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              color: color.withOpacity(0.8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
