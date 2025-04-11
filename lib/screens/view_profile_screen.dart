import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/artist_item.dart';
import '../services/profile_service.dart';

class ViewProfileScreen extends StatefulWidget {
  final String profileId;

  const ViewProfileScreen({Key? key, required this.profileId})
    : super(key: key);

  @override
  State<ViewProfileScreen> createState() => _ViewProfileScreenState();
}

class _ViewProfileScreenState extends State<ViewProfileScreen> {
  bool _isLoading = true;
  ArtistItem? _profile;
  List<dynamic> _content = [];

  @override
  void initState() {
    super.initState();
    _fetchProfileDetails();
  }

  Future<void> _fetchProfileDetails() async {
    try {
      // First try to find profile from cached random profiles
      final randomProfiles = await ProfileService.getRandomProfiles();
      final matchingProfile =
          randomProfiles.where((p) => p.id == widget.profileId).toList();

      if (matchingProfile.isNotEmpty) {
        setState(() {
          _profile = matchingProfile.first;
          _isLoading = false;
        });
        print('Found profile in random profiles cache: ${_profile?.name}');
        return;
      }

      // If not found, try to fetch from API
      print(
        'Profile not found in cache, fetching from API: ${widget.profileId}',
      );
      final url = Uri.parse(
        'https://algodream.in/admin/api/get_profile_details.php?api_key=MOHAMMADASKERYMALIKFROMNOWLARI&profile_id=${widget.profileId}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        print('API Response: ${response.body}');
        final jsonData = jsonDecode(response.body);

        if (jsonData['status'] == 'success') {
          final profileData = jsonData['profile'];
          final contentData = jsonData['content'] ?? [];

          setState(() {
            _profile = ArtistItem.fromJson(profileData);
            _content = contentData;
            _isLoading = false;
          });
          print('Successfully loaded profile from API: ${_profile?.name}');
        } else {
          print('API returned error status: ${jsonData['message']}');
          setState(() => _isLoading = false);
        }
      } else {
        print('Failed to load profile, status code: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching profile details: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isLoading ? 'Loading Profile...' : _profile?.name ?? 'Profile',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF00875A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00875A)),
                ),
              )
              : _profile == null
              ? Center(
                child: Text(
                  'Failed to load profile',
                  style: GoogleFonts.poppins(),
                ),
              )
              : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      color: const Color(0xFF00875A),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: _profile!.imageUrl,
                                fit: BoxFit.cover,
                                placeholder:
                                    (context, url) => Container(
                                      color: Colors.grey.shade200,
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                errorWidget: (context, url, error) {
                                  print(
                                    'Error loading profile image: $url, error: $error',
                                  );
                                  return Container(
                                    color: Colors.grey.shade200,
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.grey,
                                      size: 50,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _profile!.name,
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              _profile!.category,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_profile!.description != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 8,
                              ),
                              child: Text(
                                _profile!.description!,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),

                  // Profile stats
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00875A),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Profile Information",
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Profile stats cards
                          Row(
                            children: [
                              _buildStatCard(
                                "Total Views",
                                "${_profile?.category == 'Zakir' ? 'Marsiya' : 'Noha'} Views",
                                Icons.visibility_outlined,
                                "0",
                              ),
                              const SizedBox(width: 16),
                              _buildStatCard(
                                "Total Plays",
                                "Audio Plays",
                                Icons.play_circle_outline,
                                "0",
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Content section
                  SliverToBoxAdapter(
                    child:
                        _content.isEmpty
                            ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Text(
                                  'No content available for this profile yet.',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                            : Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 4,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00875A),
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Content",
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                  ),

                  _content.isEmpty
                      ? SliverToBoxAdapter(child: SizedBox())
                      : SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final item = _content[index];
                          return _buildContentItem(item);
                        }, childCount: _content.length),
                      ),
                ],
              ),
    );
  }

  Widget _buildStatCard(
    String title,
    String subtitle,
    IconData icon,
    String value,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: const Color(0xFF00875A)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF00875A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentItem(dynamic item) {
    // This will depend on your content structure
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          item['title'] ?? 'Untitled',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle:
            item['description'] != null
                ? Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    item['description'],
                    style: GoogleFonts.poppins(),
                  ),
                )
                : null,
        onTap: () {
          // Navigate to content details page
        },
      ),
    );
  }
}
