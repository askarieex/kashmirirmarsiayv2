import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/artist_item.dart';
import '../services/profile_service.dart';
import 'view_profile_screen.dart';

class AllProfilesScreen extends StatefulWidget {
  const AllProfilesScreen({super.key});

  @override
  State<AllProfilesScreen> createState() => _AllProfilesScreenState();
}

class _AllProfilesScreenState extends State<AllProfilesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  Map<String, List<ArtistItem>> _profilesByCategory = {
    'Zakir': [],
    'Noha Khan': [],
    'Both': [],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchProfiles();
  }

  Future<void> _fetchProfiles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use random profiles API instead of category-based
      print('AllProfilesScreen: Using random profiles API');
      final randomProfiles = await ProfileService.getRandomProfiles();

      if (randomProfiles.isEmpty) {
        print('AllProfilesScreen: No random profiles found');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Group profiles by category
      final Map<String, List<ArtistItem>> profiles = {
        'Zakir': [],
        'Noha Khan': [],
        'Both': [],
      };

      for (final profile in randomProfiles) {
        // Normalize category name to match our display categories
        String displayCategory;
        switch (profile.category.toLowerCase()) {
          case 'zakir':
            displayCategory = 'Zakir';
            break;
          case 'noha khan':
            displayCategory = 'Noha Khan';
            break;
          case 'both':
            displayCategory = 'Both';
            break;
          default:
            displayCategory = 'Other';
        }

        // Add to corresponding category
        if (profiles.containsKey(displayCategory)) {
          profiles[displayCategory]!.add(profile);
        } else if (displayCategory == 'Other') {
          // For other categories, decide where to place them
          if (profile.category.toLowerCase().contains('zakir')) {
            profiles['Zakir']!.add(profile);
          } else if (profile.category.toLowerCase().contains('noha')) {
            profiles['Noha Khan']!.add(profile);
          } else {
            // Default to Both if can't determine
            profiles['Both']!.add(profile);
          }
        }
      }

      // Make sure the "Both" category contains all profiles for the tab view
      profiles['Both'] = [...randomProfiles];

      print(
        'AllProfilesScreen: Processed ${randomProfiles.length} random profiles',
      );
      print(
        'AllProfilesScreen: By category - Zakir: ${profiles['Zakir']?.length}, Noha Khan: ${profiles['Noha Khan']?.length}, Both: ${profiles['Both']?.length}',
      );

      setState(() {
        _profilesByCategory = profiles;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching profiles: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'All Profiles',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF00875A),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: 'Zakirs'),
            Tab(text: 'Noha Khans'),
            Tab(text: 'Both'),
          ],
        ),
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    const Color(0xFF00875A),
                  ),
                ),
              )
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildProfileGrid(_profilesByCategory['Zakir'] ?? []),
                  _buildProfileGrid(_profilesByCategory['Noha Khan'] ?? []),
                  _buildProfileGrid(_profilesByCategory['Both'] ?? []),
                ],
              ),
    );
  }

  Widget _buildProfileGrid(List<ArtistItem> profiles) {
    if (profiles.isEmpty) {
      return Center(
        child: Text(
          'No profiles found in this category',
          style: GoogleFonts.poppins(color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchProfiles,
      color: const Color(0xFF00875A),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: profiles.length,
        itemBuilder: (context, index) {
          final profile = profiles[index];
          return _buildProfileItem(profile);
        },
      ),
    );
  }

  Widget _buildProfileItem(ArtistItem profile) {
    print(
      'Building profile item: ${profile.name}, imageUrl: ${profile.imageUrl}',
    );

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewProfileScreen(profileId: profile.id),
          ),
        );
      },
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF00875A), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: profile.imageUrl,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF00875A),
                            ),
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                  errorWidget: (context, url, error) {
                    print('Error loading image: $url, error: $error');
                    return Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.person, color: Colors.grey),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            profile.name,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF00875A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              profile.category,
              style: GoogleFonts.poppins(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF00875A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
