import 'package:flutter/material.dart';
// Import your screens from the same folder (screens)
import 'full_marsiya_screen.dart';
import 'marsiya_audio_screen.dart';
import 'intikhaab_screen.dart';
import 'taht_ul_lafz_screen.dart';

class MarsiyaScreen extends StatelessWidget {
  const MarsiyaScreen({super.key});

  // Primary theme color (green)
  static const Color primaryColor = Color(0xFF388E3C);

  // Background color for the entire screen
  static const Color backgroundColor = Color(0xFFF5F5F5);

  // Text colors
  static const Color textDark = Color(0xFF333333);
  static const Color textLight = Color(0xFF757575);

  // Icon references
  static const IconData audioIcon = Icons.play_circle_filled;
  static const IconData marsiyaIcon = Icons.menu_book_rounded;
  static const IconData intikhaabIcon = Icons.favorite;
  static const IconData wordIcon = Icons.text_format;

  // Updated sections with your requested titles
  static List<Map<String, dynamic>> sections = [
    {
      'titleEn': '(Audios)',
      'titleUr': 'مع وزن',
      'icon': audioIcon,
      'screen': MarsiyaAudioScreen(), // points to marsiya_audio_screen.dart
    },
    {
      'titleEn': '(Full Marsiya)',
      'titleUr': 'مکمل مضمون',
      'icon': marsiyaIcon,
      'screen': FullMarsiyaScreen(), // points to full_marsiya_screen.dart
    },
    {
      'titleEn': '(Intikhaab)',
      'titleUr': 'انتخاب',
      'icon': intikhaabIcon,
      'screen': IntikhaabScreen(), // points to intikhaab_screen.dart
    },
    {
      'titleEn': '(Word by Word)',
      'titleUr': 'تحت اللفظ',
      'icon': wordIcon,
      'screen': TahtUlLafzScreen(), // points to taht_ul_lafz_screen.dart
    },
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isPortrait = size.height > size.width;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // --------------- GRADIENT HEADER SECTION ---------------
          Container(
            height: 160,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF4CAF50), // Lighter green
                  Color(0xFF388E3C), // Darker green
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.menu_book, color: Colors.white, size: 48),
                SizedBox(height: 10),
                Text(
                  'Marsiya Collection',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // --------------- CATEGORIES TITLE & DESCRIPTION ---------------
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Browse Categories',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Explore the world of Marsiya with these categories',
                  style: TextStyle(fontSize: 14, color: textLight),
                ),
              ],
            ),
          ),

          // --------------- GRID LAYOUT FOR SECTIONS ---------------
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: GridView.builder(
                itemCount: sections.length,
                physics: const BouncingScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isPortrait ? 2 : 4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemBuilder: (context, index) {
                  final section = sections[index];
                  return _buildCategoryCard(
                    context,
                    section['titleEn'] as String,
                    section['titleUr'] as String,
                    section['icon'] as IconData,
                    section['screen'] as Widget,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------- CATEGORY CARD BUILDER ---------------
  Widget _buildCategoryCard(
    BuildContext context,
    String titleEn,
    String titleUr,
    IconData icon,
    Widget screen,
  ) {
    return GestureDetector(
      onTap: () {
        // Navigate to the corresponding screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
      child: Material(
        // Use Material for a ripple effect on tap
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            // Subtle gradient for each card
            gradient: const LinearGradient(
              colors: [
                Color(0xFF66BB6A), // Lighter green
                Color(0xFF43A047), // Darker green
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                titleEn,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                titleUr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------- MAIN FUNCTION (for testing) -----------------------
// Use this if you want to run marsiya_screen.dart standalone:
// void main() {
//   runApp(const MaterialApp(
//     debugShowCheckedModeBanner: false,
//     home: MarsiyaScreen(),
//   ));
// }
