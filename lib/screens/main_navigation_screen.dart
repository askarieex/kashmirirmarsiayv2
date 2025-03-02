import 'package:flutter/material.dart';
import 'home_screen.dart';

/// A main navigation screen with:
/// - A white side drawer.
/// - 4 bottom tabs: Home, Marsiya, Noha, Search.
/// - Bottom nav bar bigger, with bigger icons.
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    const HomeScreen(),
    // Placeholder screens for other tabs
    const Center(
      child: Text(
        'Marsiya Screen',
        style: TextStyle(color: Colors.grey, fontSize: 18),
      ),
    ),
    const Center(
      child: Text(
        'Noha Screen',
        style: TextStyle(color: Colors.grey, fontSize: 18),
      ),
    ),
    const Center(
      child: Text(
        'Search Screen',
        style: TextStyle(color: Colors.grey, fontSize: 18),
      ),
    ),
  ];

  // Increase bottom nav height
  static const double bottomNavHeight = 80;

  // White background for the nav bar
  static const Color bottomNavColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // White side drawer
      drawer: _buildSideDrawer(),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        height: bottomNavHeight,
        decoration: BoxDecoration(
          color: bottomNavColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          // Make icons bigger
          iconSize: 30,
          backgroundColor: Colors.transparent,
          elevation: 0,
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.teal, // Teal highlight for selected
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.music_note),
              label: 'Marsiya',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.headphones),
              label: 'Noha',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          ],
        ),
      ),
    );
  }

  /// A white side drawer with a clean design
  Widget _buildSideDrawer() {
    return Drawer(
      child: Column(
        children: [
          // A white DrawerHeader
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 6,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'Kashmiri Marsiya',
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Drawer items
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text("Home"),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 0);
            },
          ),
          ListTile(
            leading: const Icon(Icons.music_note),
            title: const Text("Marsiya"),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 1);
            },
          ),
          ListTile(
            leading: const Icon(Icons.headphones),
            title: const Text("Noha"),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 2);
            },
          ),
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text("Search"),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 3);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text("About Us"),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('About Us tapped!')));
            },
          ),
        ],
      ),
    );
  }
}
