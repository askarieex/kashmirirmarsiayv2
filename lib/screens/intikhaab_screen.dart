import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';

class IntikhaabScreen extends StatefulWidget {
  static const Color accentTeal = Color(0xFF008F41);
  const IntikhaabScreen({Key? key}) : super(key: key);

  @override
  State<IntikhaabScreen> createState() => _IntikhaabScreenState();
}

class _IntikhaabScreenState extends State<IntikhaabScreen> {
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
              'انتخاب',
              style: GoogleFonts.notoNastaliqUrdu(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF00875A),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Selected Verses',
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

class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String title;

  const PdfViewerScreen({Key? key, required this.pdfUrl, required this.title})
    : super(key: key);

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late PDFViewController _pdfViewController;
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isInitialized = false;
  bool _isLoading = true;
  String? _localPath;

  @override
  void initState() {
    super.initState();
    _loadPdf();

    // Show in-app notification when PDF is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInAppNotification();
    });
  }

  Future<void> _loadPdf() async {
    try {
      final response = await http.get(Uri.parse(widget.pdfUrl));
      final bytes = response.bodyBytes;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/document.pdf');
      await file.writeAsBytes(bytes);
      setState(() {
        _localPath = file.path;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading PDF: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showInAppNotification() {
    Fluttertoast.showToast(
      msg: "This PDF is available exclusively in this app",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: IntikhaabScreen.accentTeal,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void _sharePdf() {
    Share.share(
      'Check out this amazing Marsiya: ${widget.title}. Available exclusively in our app!',
      subject: 'Sharing Marsiya PDF: ${widget.title}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: IntikhaabScreen.accentTeal,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _sharePdf,
            tooltip: 'Share',
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_localPath != null)
            PDFView(
              filePath: _localPath!,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageFling: true,
              onRender: (pages) {
                setState(() {
                  _totalPages = pages!;
                  _isInitialized = true;
                });
              },
              onViewCreated: (PDFViewController controller) {
                _pdfViewController = controller;
              },
              onPageChanged: (int? page, int? total) {
                if (page != null) {
                  setState(() {
                    _currentPage = page + 1;
                  });
                }
              },
            )
          else
            const Center(child: Text('Failed to load PDF')),
          if (_isInitialized)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Page $_currentPage of $_totalPages',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton:
          _isInitialized
              ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton.small(
                    onPressed: () {
                      if (_currentPage > 1) {
                        _pdfViewController.setPage(_currentPage - 2);
                      }
                    },
                    backgroundColor: IntikhaabScreen.accentTeal,
                    foregroundColor: Colors.white,
                    heroTag: 'prevPage',
                    child: const Icon(Icons.arrow_upward),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    onPressed: () {
                      if (_currentPage < _totalPages) {
                        _pdfViewController.setPage(_currentPage);
                      }
                    },
                    backgroundColor: IntikhaabScreen.accentTeal,
                    foregroundColor: Colors.white,
                    heroTag: 'nextPage',
                    child: const Icon(Icons.arrow_downward),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    onPressed: () {
                      // Zoom not directly supported in flutter_pdfview
                      // We can implement custom zoom in future
                    },
                    backgroundColor: IntikhaabScreen.accentTeal,
                    foregroundColor: Colors.white,
                    heroTag: 'zoom',
                    child: const Icon(Icons.zoom_in),
                  ),
                ],
              )
              : null,
    );
  }
}
