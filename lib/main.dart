import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'screens/splash_screen.dart';
import 'screens/get_started_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/network_check_screen.dart';
import 'widgets/persistent_mini_player.dart';

// Use the navigator key from the persistent_mini_player.dart file
// Make sure it's the same instance in both files
import 'widgets/persistent_mini_player.dart' show navigatorKey;

final AudioPlayer globalAudioPlayer = AudioPlayer();

void main() {
  // Ensure Flutter is initialized before running app
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

/// Root widget with a permanent Spotify-like dark theme.
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // Spotify signature color.
  static const Color spotifyGreen = Color(0xFF1DB954);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kashmiri Marsiya',
      debugShowCheckedModeBanner: false,
      // Use the navigator key from persistent_mini_player.dart
      navigatorKey: navigatorKey,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: spotifyGreen,
        colorScheme: ColorScheme.light(
          primary: spotifyGreen,
          secondary: spotifyGreen,
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      // Start with splash screen directly (not network check)
      home: const SplashScreen(),
      onGenerateRoute: (settings) {
        // Handle navigation routes
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const SplashScreen());
          case '/getStarted':
            return MaterialPageRoute(builder: (_) => const GetStartedScreen());
          case '/mainNav':
            return MaterialPageRoute(
              builder: (_) => const MainNavigationScreen(),
            );
          case '/networkCheck':
            return MaterialPageRoute(
              builder: (_) => const NetworkCheckScreen(),
            );
          default:
            return MaterialPageRoute(builder: (_) => const SplashScreen());
        }
      },
      // Wrap every route with the persistent mini player.
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            // Position the persistent audio player at the bottom.
            const Align(
              alignment: Alignment.bottomCenter,
              child: PersistentMiniPlayer(),
            ),
          ],
        );
      },
    );
  }
}
