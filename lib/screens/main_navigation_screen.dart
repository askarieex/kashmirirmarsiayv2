import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'marsiya_screen.dart';
import 'noha_screen.dart';
import 'search_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => MainNavigationScreenState();
}

class MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // Public method to allow other widgets to change the current tab
  void changeTab(int index) {
    if (index >= 0 && index < _screens.length) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  // List of screens corresponding to each tab.
  late final List<Widget> _screens = [
    const HomeScreen(),
    const MarsiyaScreen(),
    const NohaScreen(),
    const SearchScreen(),
  ];

  // Theme colors for the navigation.
  static const Color primaryColor = Color(0xFF0D9051);
  static const Color backgroundColor = Color(0xFF212121);
  static const Color inactiveColor = Color(0xFFAAAAAA);
  static const double navBarHeight = 60.0;
  static const double iconSize = 24.0;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      drawer: _buildSideDrawer(),
      body: IndexedStack(index: _currentIndex, children: _screens),
      extendBody: true,
      bottomNavigationBar: Container(
        height: navBarHeight + bottomInset,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(
            top: BorderSide(color: Colors.black.withOpacity(0.1), width: 0.5),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(0, Icons.home, 'Home'),
              _buildNavItem(1, Icons.music_note, 'Marsiya'),
              _buildNavItem(2, Icons.headphones, 'Noha'),
              _buildNavItem(3, Icons.search, 'Search'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? primaryColor : inactiveColor,
              size: iconSize,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? primaryColor : inactiveColor,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideDrawer() {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: primaryColor),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Kashmiri Marsiya',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            _buildDrawerItem(Icons.home, "Home", 0),
            _buildDrawerItem(Icons.music_note, "Marsiya", 1),
            _buildDrawerItem(Icons.headphones, "Noha", 2),
            _buildDrawerItem(Icons.search, "Search", 3),
            const Divider(),
            _buildDrawerItem(Icons.info_outline, "About Us", -1),
            _buildDrawerItem(Icons.contact_support_outlined, "Contact Us", -2),
            _buildDrawerItem(Icons.favorite_outline, "Favorites", -3),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    final bool isSelected = index == _currentIndex && index >= 0;
    return ListTile(
      leading: Icon(icon, color: isSelected ? primaryColor : Colors.grey[700]),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? primaryColor : Colors.grey[800],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        if (index >= 0) {
          setState(() => _currentIndex = index);
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$title tapped!')));
        }
      },
    );
  }
}
