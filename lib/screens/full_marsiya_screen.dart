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
import 'package:iconly/iconly.dart';
import 'dart:ui' as ui;

class FullMarsiyaScreen extends StatefulWidget {
  const FullMarsiyaScreen({super.key});
  static const Color accentTeal = Color(0xFF008F41);
  static const Color bgColor = Color(0xFFF2F7F7);
  @override
  State<FullMarsiyaScreen> createState() => _FullMarsiyaScreenState();
}

class _FullMarsiyaScreenState extends State<FullMarsiyaScreen>
    with SingleTickerProviderStateMixin {
  final String apiUrl =
      "https://algodream.in/admin/api/get_full_marsiya_pdf.php?api_key=MOHAMMADASKERYMALIKFROMNOWLARI";
  bool _isLoading = true;
  bool _isError = false;
  String _errorMessage = '';
  List<dynamic> _pdfList = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    fetchPdfList();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels < -100 && !_isRefreshing) {
      setState(() {
        _isRefreshing = true;
      });
      fetchPdfList().then((_) {
        setState(() {
          _isRefreshing = false;
        });
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchPdfList() async {
    setState(() {
      _isLoading = true;
      _isError = false;
    });
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == 'success') {
          setState(() {
            _pdfList = jsonData['data'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _isError = true;
            _errorMessage = jsonData['message'] ?? 'Failed to load data';
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _isError = true;
          _errorMessage = 'Server error: ${response.statusCode}';
        });
      }
    } catch (e) {
      print("Error fetching PDFs: $e");
      setState(() {
        _isLoading = false;
        _isError = true;
        _errorMessage = 'Network error: $e';
      });
    }
  }

  // Filter the list based on the search query
  List<dynamic> get filteredPdfList {
    if (_searchQuery.isEmpty) return _pdfList;
    return _pdfList.where((item) {
      final title = item['title']?.toString().toLowerCase() ?? "";
      final author =
          (item['manual_author'] ?? item['author_name'] ?? "")
              .toString()
              .toLowerCase();
      return title.contains(_searchQuery.toLowerCase()) ||
          author.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  // Return list sorted by uploaded_date in descending order
  List<dynamic> get recentlyUploadedPdfList {
    List<dynamic> list = List.from(filteredPdfList);
    list.sort((a, b) {
      DateTime dateA =
          DateTime.tryParse(a['uploaded_date'] ?? "") ?? DateTime(1970);
      DateTime dateB =
          DateTime.tryParse(b['uploaded_date'] ?? "") ?? DateTime(1970);
      return dateB.compareTo(dateA);
    });
    return list;
  }

  // Format the uploaded date string
  String formatDate(String dateStr) {
    try {
      DateTime dt = DateTime.parse(dateStr);
      return "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return dateStr;
    }
  }

  // Handle tap on a PDF item
  void _onItemTap(Map<String, dynamic> item) {
    if (item['pdf_url'] != null && item['pdf_url'].toString().isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => PdfViewerScreen(
                pdfUrl: item['pdf_url'],
                title: item['title'] ?? 'PDF Viewer',
              ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF not available'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Build the search bar
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by title or author...',
          hintStyle: GoogleFonts.nunitoSans(
            color: Colors.grey.shade400,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(
            IconlyLight.search,
            color: FullMarsiyaScreen.accentTeal,
            size: 22,
          ),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    icon: const Icon(
                      IconlyBold.close_square,
                      color: FullMarsiyaScreen.accentTeal,
                      size: 20,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                  : null,
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(
              color: FullMarsiyaScreen.accentTeal,
              width: 1.5,
            ),
          ),
        ),
        style: GoogleFonts.nunitoSans(
          color: Colors.grey.shade800,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // A shimmer loading effect for list items
  Widget _buildShimmerLoading() {
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 500),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            FullMarsiyaScreen.accentTeal,
                            FullMarsiyaScreen.accentTeal.withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    title: Container(
                      height: 20,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        Container(
                          height: 16,
                          width: 150,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 16,
                          width: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Build a single PDF list item
  Widget _buildMarsiyaItem(Map<String, dynamic> item) {
    String displayAuthor = "";
    if (item['manual_author'] != null &&
        item['manual_author'].toString().isNotEmpty) {
      displayAuthor = item['manual_author'];
    } else if (item['author_id'] != null &&
        item['author_id'].toString() == "1") {
      displayAuthor = item['author_name'] ?? "Askery";
    } else {
      displayAuthor = item['author_name'] ?? "Unknown";
    }

    String displayTitle = item['title']?.toString() ?? '';
    if (displayTitle.isEmpty) {
      displayTitle = "Untitled Marsiya";
    }

    String formattedDate = formatDate(item['uploaded_date'] ?? "");
    String views = item['views']?.toString() ?? "0";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF9747FF).withOpacity(0.12),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.7),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(-3, -3),
          ),
        ],
        border: Border.all(color: Color(0xFF9747FF).withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _onItemTap(item),
            splashColor: Color(0xFF9747FF).withOpacity(0.1),
            highlightColor: Color(0xFF9747FF).withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // PDF Icon with rich gradient
                  Hero(
                    tag: 'pdf_icon_${item['id'] ?? DateTime.now().toString()}',
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF9747FF),
                            Color(0xFF7E42D9),
                            Color(0xFF6B38C1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF9747FF).withOpacity(0.25),
                            blurRadius: 12,
                            spreadRadius: 0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          IconlyLight.document,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Content section with improved typography
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title with improved typography
                        Text(
                          displayTitle,
                          style: GoogleFonts.notoNastaliqUrdu(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            height: 1.8,
                            color: const Color(0xFF2D3748),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textDirection: ui.TextDirection.rtl,
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 10),

                        // Author badge with purple theme
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xFF9747FF).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Color(0xFF9747FF).withOpacity(0.1),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                IconlyLight.profile,
                                size: 12,
                                color: Color(0xFF9747FF),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  displayAuthor != "null"
                                      ? displayAuthor
                                      : "Unknown",
                                  style: GoogleFonts.poppins(
                                    color: Color(0xFF9747FF).withOpacity(0.9),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Info row with colorful chips
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _buildInfoChip(
                              IconlyLight.calendar,
                              formattedDate,
                              Colors.orange.shade400,
                            ),
                            _buildInfoChip(
                              IconlyLight.show,
                              "$views views",
                              Colors.blue.shade400,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Read/View button with beautiful styling
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color.fromARGB(255, 241, 238, 245).withOpacity(0.7),
                          Color.fromARGB(255, 248, 245, 253),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromARGB(
                            255,
                            250,
                            250,
                            250,
                          ).withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: 0,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        IconlyLight.arrow_right_circle,
                        color: Color.fromARGB(255, 146, 80, 232),
                        size: 25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
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
            style: GoogleFonts.nunitoSans(
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

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(IconlyBold.danger, color: Colors.red.shade400, size: 80),
            const SizedBox(height: 16),
            Text(
              "Oops! Something went wrong",
              style: GoogleFonts.nunitoSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage,
              style: GoogleFonts.nunitoSans(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: fetchPdfList,
              icon: const Icon(IconlyBold.arrow_right_circle),
              label: Text(
                "Try Again",
                style: GoogleFonts.nunitoSans(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: FullMarsiyaScreen.accentTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyListView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, color: Colors.grey.shade400, size: 80),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? "No matching results found"
                : "No PDFs available",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isNotEmpty
                ? "Try adjusting your search criteria"
                : "Check back later for new content",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isNotEmpty) const SizedBox(height: 24),
          if (_searchQuery.isNotEmpty)
            ElevatedButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
              icon: const Icon(Icons.clear),
              label: const Text("Clear Search"),
              style: ElevatedButton.styleFrom(
                backgroundColor: FullMarsiyaScreen.accentTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRefreshIndicator() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isRefreshing ? 80 : 0,
      child: Center(
        child:
            _isRefreshing
                ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          FullMarsiyaScreen.accentTeal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Refreshing...",
                      style: TextStyle(
                        color: FullMarsiyaScreen.accentTeal,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
                : const SizedBox.shrink(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FullMarsiyaScreen.bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            children: [
              Text(
                'مکمل مرثیہ',
                style: GoogleFonts.notoNastaliqUrdu(
                  color: FullMarsiyaScreen.accentTeal,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  height: 1.9,
                ),
                textDirection: ui.TextDirection.rtl,
              ),
              const SizedBox(width: 8),
              Text(
                '- Full Marsiya PDF',
                style: GoogleFonts.nunitoSans(
                  color: const Color(0xFF2D3748),
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            IconlyLight.arrow_left,
            color: FullMarsiyaScreen.accentTeal,
            size: 26,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: FullMarsiyaScreen.accentTeal,
          indicatorWeight: 3,
          labelColor: FullMarsiyaScreen.accentTeal,
          unselectedLabelColor: Colors.grey.shade600,
          labelStyle: GoogleFonts.nunitoSans(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(IconlyLight.document, size: 16),
                  const SizedBox(width: 4),
                  Text('All PDFs', style: const TextStyle(height: 1)),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(IconlyLight.time_circle, size: 16),
                  const SizedBox(width: 4),
                  Text('Recently Uploaded', style: const TextStyle(height: 1)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            _buildSearchBar(),
            // Pull-to-refresh indicator
            _buildRefreshIndicator(),
            // Main content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // All PDFs tab
                  _isLoading
                      ? _buildShimmerLoading()
                      : _isError
                      ? _buildErrorView()
                      : filteredPdfList.isEmpty
                      ? _buildEmptyListView()
                      : RefreshIndicator(
                        onRefresh: fetchPdfList,
                        color: FullMarsiyaScreen.accentTeal,
                        child: AnimationLimiter(
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            itemCount: filteredPdfList.length,
                            itemBuilder: (context, index) {
                              final item = filteredPdfList[index];
                              return AnimationConfiguration.staggeredList(
                                position: index,
                                duration: const Duration(milliseconds: 500),
                                child: SlideAnimation(
                                  verticalOffset: 50.0,
                                  child: FadeInAnimation(
                                    child: _buildMarsiyaItem(item),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                  // Recently uploaded tab
                  _isLoading
                      ? _buildShimmerLoading()
                      : _isError
                      ? _buildErrorView()
                      : recentlyUploadedPdfList.isEmpty
                      ? _buildEmptyListView()
                      : RefreshIndicator(
                        onRefresh: fetchPdfList,
                        color: FullMarsiyaScreen.accentTeal,
                        child: AnimationLimiter(
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            itemCount: recentlyUploadedPdfList.length,
                            itemBuilder: (context, index) {
                              final item = recentlyUploadedPdfList[index];
                              return AnimationConfiguration.staggeredList(
                                position: index,
                                duration: const Duration(milliseconds: 500),
                                child: SlideAnimation(
                                  verticalOffset: 50.0,
                                  child: FadeInAnimation(
                                    child: _buildMarsiyaItem(item),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String title;

  const PdfViewerScreen({super.key, required this.pdfUrl, required this.title});

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
      backgroundColor: FullMarsiyaScreen.accentTeal,
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
          style: GoogleFonts.notoNastaliqUrdu(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            height: 1.9,
          ),
          overflow: TextOverflow.ellipsis,
          textDirection: ui.TextDirection.rtl,
        ),
        backgroundColor: FullMarsiyaScreen.accentTeal,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(IconlyBold.send),
            onPressed: _sharePdf,
            tooltip: 'Share',
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: FullMarsiyaScreen.accentTeal,
              ),
            )
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
            Center(
              child: Text(
                'Failed to load PDF',
                style: GoogleFonts.nunitoSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
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
                    style: GoogleFonts.nunitoSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
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
                    backgroundColor: FullMarsiyaScreen.accentTeal,
                    foregroundColor: Colors.white,
                    heroTag: 'prevPage',
                    child: const Icon(IconlyLight.arrow_up_2),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    onPressed: () {
                      if (_currentPage < _totalPages) {
                        _pdfViewController.setPage(_currentPage);
                      }
                    },
                    backgroundColor: FullMarsiyaScreen.accentTeal,
                    foregroundColor: Colors.white,
                    heroTag: 'nextPage',
                    child: const Icon(IconlyLight.arrow_down_2),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    onPressed: () {
                      // Zoom not directly supported in flutter_pdfview
                      // We can implement custom zoom in future
                    },
                    backgroundColor: FullMarsiyaScreen.accentTeal,
                    foregroundColor: Colors.white,
                    heroTag: 'zoom',
                    child: const Icon(IconlyBold.show),
                  ),
                ],
              )
              : null,
    );
  }
}
