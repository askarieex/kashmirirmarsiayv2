import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FullNohaScreen extends StatefulWidget {
  const FullNohaScreen({Key? key}) : super(key: key);

  @override
  State<FullNohaScreen> createState() => _FullNohaScreenState();
}

class _FullNohaScreenState extends State<FullNohaScreen> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5F5F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFE5F5F8),
        centerTitle: false,
        title: Row(
          children: [
            Text(
              'نوحہ',
              style: GoogleFonts.notoNastaliqUrdu(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF00875A),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Complete Collection',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Text(
          'Coming Soon',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
