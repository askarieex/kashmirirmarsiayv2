import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class IntikhaabScreen extends StatefulWidget {
  const IntikhaabScreen({super.key});
  static const Color accentTeal = Color(0xFF008F41);
  static const Color bgColor = Color(0xFFF5F7FA);
  @override
  State<IntikhaabScreen> createState() => _IntikhaabScreenState();
}

class _IntikhaabScreenState extends State<IntikhaabScreen>
    with SingleTickerProviderStateMixin {
  final String apiUrl =
      "https://algodream.in/admin/api/get_short_marsiya_pdf.php?api_key=MOHAMMADASKERYMALIKFROMNOWLARI";
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
      print("Error fetching Intikhaab PDFs: $e");
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
      final subtitle = item['subtitle']?.toString().toLowerCase() ?? "";
      final author = item['author']?.toString().toLowerCase() ?? "";
      return title.contains(_searchQuery.toLowerCase()) ||
          subtitle.contains(_searchQuery.toLowerCase()) ||
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
          hintText: 'Search by title, subtitle or author...',
          prefixIcon: const Icon(
            Icons.search,
            color: IntikhaabScreen.accentTeal,
          ),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    icon: const Icon(
                      Icons.clear,
                      color: IntikhaabScreen.accentTeal,
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
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(
              color: IntikhaabScreen.accentTeal,
              width: 1.5,
            ),
          ),
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
                            IntikhaabScreen.accentTeal,
                            IntikhaabScreen.accentTeal.withOpacity(0.7),
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
    String displayTitle = item['title']?.toString() ?? '';
    if (displayTitle.isEmpty) {
      displayTitle = "Untitled";
    }

    String displaySubtitle = item['subtitle']?.toString() ?? '';
    String displayAuthor = item['author']?.toString() ?? 'Unknown';
    String duration = item['duration']?.toString() ?? '';
    String views = item['views']?.toString() ?? '';
    String formattedDate = formatDate(item['uploaded_date'] ?? "");

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _onItemTap(item),
            splashColor: IntikhaabScreen.accentTeal.withOpacity(0.1),
            highlightColor: IntikhaabScreen.accentTeal.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PDF Icon with animated hover effect
                  Hero(
                    tag: 'pdf_icon_${item['id'] ?? DateTime.now().toString()}',
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            IntikhaabScreen.accentTeal,
                            const Color(0xFF006D2E),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: IntikhaabScreen.accentTeal.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.star, color: Colors.white, size: 30),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Content section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF2D3748),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textDirection: TextDirection.rtl,
                        ),
                        if (displaySubtitle.isNotEmpty)
                          Text(
                            displaySubtitle,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        const SizedBox(height: 8),
                        // Author section with icon
                        Row(
                          children: [
                            const Icon(
                              Icons.person,
                              size: 16,
                              color: IntikhaabScreen.accentTeal,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                "By $displayAuthor",
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Stats row
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              duration,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Icon(
                              Icons.visibility_outlined,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              views,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Arrow icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: IntikhaabScreen.accentTeal,
                      size: 24,
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

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 80),
            const SizedBox(height: 16),
            Text(
              "Oops! Something went wrong",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: fetchPdfList,
              icon: const Icon(Icons.refresh),
              label: const Text("Try Again"),
              style: ElevatedButton.styleFrom(
                backgroundColor: IntikhaabScreen.accentTeal,
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
                backgroundColor: IntikhaabScreen.accentTeal,
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
                          IntikhaabScreen.accentTeal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Refreshing...",
                      style: TextStyle(
                        color: IntikhaabScreen.accentTeal,
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
      backgroundColor: IntikhaabScreen.bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            children: [
              Text(
                'انتخاب',
                style: TextStyle(
                  color: IntikhaabScreen.accentTeal,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              SizedBox(width: 8),
              Text(
                '- Intikhaab',
                style: TextStyle(
                  color: Color(0xFF2D3748),
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: IntikhaabScreen.accentTeal,
            size: 28,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: IntikhaabScreen.accentTeal,
          indicatorWeight: 3,
          labelColor: IntikhaabScreen.accentTeal,
          unselectedLabelColor: Colors.grey.shade600,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          tabs: const [Tab(text: 'All PDFs'), Tab(text: 'Recently Uploaded')],
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
                        color: IntikhaabScreen.accentTeal,
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
                        color: IntikhaabScreen.accentTeal,
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
