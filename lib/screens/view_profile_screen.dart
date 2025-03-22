import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import '../models/artist_item.dart';

class ViewProfileScreen extends StatefulWidget {
  final String profileId;

  const ViewProfileScreen({super.key, required this.profileId});

  @override
  State<ViewProfileScreen> createState() => _ViewProfileScreenState();
}

class _ViewProfileScreenState extends State<ViewProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;
  late TabController _tabController;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchProfileData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfileData() async {
    try {
      debugPrint('Fetching profile with ID: ${widget.profileId}');

      // Let's try both API endpoints to get the profile data
      final randomProfilesUrl = Uri.parse(
        'https://algodream.in/admin/api/get_random_profiles.php?api_key=MOHAMMADASKERYMALIKFROMNOWLARI',
      );

      final response = await http.get(randomProfilesUrl);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['status'] == 'success' && jsonData['data'] != null) {
          final List<dynamic> profilesData = jsonData['data'];

          // Try to find the profile with matching ID
          Map<String, dynamic>? matchingProfile;

          // Print all profile IDs for debugging
          debugPrint(
            'Available profile IDs: ${profilesData.map((p) => p['unique_id']).toList()}',
          );

          for (var profile in profilesData) {
            if (profile['unique_id'] == widget.profileId) {
              matchingProfile = Map<String, dynamic>.from(profile);
              break;
            }
          }

          if (matchingProfile != null) {
            setState(() {
              _profileData = matchingProfile;
              _isLoading = false;
            });
          } else {
            // If no matching profile, show a detailed error
            debugPrint('Profile not found with ID: ${widget.profileId}');
            setState(() => _isLoading = false);
          }
        } else {
          debugPrint('API returned status: ${jsonData['status']}');
          setState(() => _isLoading = false);
        }
      } else {
        debugPrint('Failed to load profiles: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF00875A);

    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _profileData == null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_off_outlined,
                        size: 70,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Profile not found',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'We couldn\'t find the profile you\'re looking for. Please try again later.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ID: ${widget.profileId}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00875A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: const Text('Go Back'),
                      ),
                    ],
                  ),
                ),
              )
              : NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      expandedHeight: 220.0,
                      floating: false,
                      pinned: true,
                      stretch: true,
                      backgroundColor: primaryColor,
                      iconTheme: const IconThemeData(color: Colors.white),
                      actions: [
                        IconButton(
                          icon: Icon(Icons.share_outlined, color: Colors.white),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Share functionality coming soon',
                                ),
                                backgroundColor: primaryColor,
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            _isFollowing
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              _isFollowing = !_isFollowing;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  _isFollowing
                                      ? 'Added to favorites'
                                      : 'Removed from favorites',
                                ),
                                backgroundColor: primaryColor,
                              ),
                            );
                          },
                        ),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Gradient background
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    primaryColor,
                                    primaryColor.withOpacity(0.8),
                                  ],
                                ),
                              ),
                            ),
                            // Pattern overlay
                            Opacity(
                              opacity: 0.1,
                              child: Image.network(
                                'https://www.transparenttextures.com/patterns/cubes.png',
                                repeat: ImageRepeat.repeat,
                              ),
                            ),
                            // Profile image and name
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Hero(
                                        tag: 'profile-${widget.profileId}',
                                        child: Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.2,
                                                ),
                                                blurRadius: 10,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                          child: ClipOval(
                                            child:
                                                _profileData?['profile_image'] !=
                                                        null
                                                    ? Image.network(
                                                      _profileData!['profile_image'],
                                                      fit: BoxFit.cover,
                                                    )
                                                    : Container(
                                                      color: Colors.grey[300],
                                                      child: const Icon(
                                                        Icons.person,
                                                        size: 40,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _profileData?['name'] ??
                                                  'Unknown',
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                shadows: [
                                                  Shadow(
                                                    blurRadius: 3.0,
                                                    color: Colors.black
                                                        .withOpacity(0.3),
                                                    offset: const Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(
                                                  0.2,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: Text(
                                                _profileData?['category'] ??
                                                    'Artist',
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      bottom: TabBar(
                        controller: _tabController,
                        indicatorColor: Colors.white,
                        indicatorWeight: 3,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white.withOpacity(0.7),
                        labelStyle: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        tabs: const [
                          Tab(text: 'Profile'),
                          Tab(text: 'Content'),
                          Tab(text: 'Stats'),
                        ],
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildProfileTab(),
                    _buildContentTab(),
                    _buildStatsTab(),
                  ],
                ),
              ),
    );
  }

  Widget _buildProfileTab() {
    final bio =
        "This is a talented ${_profileData?['category'] ?? 'artist'} "
        "known for spiritual content and devotional performances. "
        "Follow for more inspiring content.";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats cards
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  label: 'Views',
                  value: _profileData?['total_views'] ?? '0',
                  icon: Icons.visibility_outlined,
                ),
                _buildVerticalDivider(),
                _buildStatColumn(
                  label: 'Plays',
                  value: _profileData?['total_plays'] ?? '0',
                  icon: Icons.play_circle_outline,
                ),
                _buildVerticalDivider(),
                _buildStatColumn(
                  label: 'Content',
                  value: '0',
                  icon: Icons.library_music_outlined,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Bio section
          _buildSectionTitle('Biography'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Text(
              bio,
              style: GoogleFonts.poppins(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey[800],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Contact Info Section
          _buildSectionTitle('Contact Information'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                _buildContactItem(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: _profileData?['email'] ?? 'Not available',
                ),
                Divider(height: 1, color: Colors.grey[200]),
                _buildContactItem(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: _profileData?['phone'] ?? 'Not available',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Social links section
          _buildSectionTitle('Social Media'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSocialButton(Icons.facebook, Colors.blue),
                _buildSocialButton(Icons.phone_android, Colors.green),
                _buildSocialButton(Icons.send, Colors.blue[400]!),
                _buildSocialButton(Icons.language, Colors.orange),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Member since info
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Member since: ${_profileData?['created_at']?.substring(0, 10) ?? 'Unknown'}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildContentTab() {
    // Placeholder for content
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.queue_music, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No content available yet',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for updates',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                _buildStatisticRow(
                  'Total Views',
                  _profileData?['total_views'] ?? '0',
                  Icons.visibility_outlined,
                ),
                const Divider(height: 30),
                _buildStatisticRow(
                  'Total Plays',
                  _profileData?['total_plays'] ?? '0',
                  Icons.play_circle_outline,
                ),
                const Divider(height: 30),
                _buildStatisticRow(
                  'Content Count',
                  '0',
                  Icons.library_music_outlined,
                ),
                const Divider(height: 30),
                _buildStatisticRow('Engagement Rate', '0%', Icons.trending_up),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Detailed analytics coming soon',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF00875A), size: 22),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF00875A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 50, width: 1, color: Colors.grey[200]);
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF00875A)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, Color color) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Social link coming soon'),
            backgroundColor: const Color(0xFF00875A),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  Widget _buildStatisticRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF00875A).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF00875A), size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF00875A),
          ),
        ),
      ],
    );
  }
}
