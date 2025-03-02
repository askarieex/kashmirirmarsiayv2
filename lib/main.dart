import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'screens/splash_screen.dart';
import 'screens/get_started_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'widgets/persistent_mini_player.dart';

// Use the navigator key from the persistent_mini_player.dart file
// Make sure it's the same instance in both files
import 'widgets/persistent_mini_player.dart' show navigatorKey;

final AudioPlayer globalAudioPlayer = AudioPlayer();

void main() {
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
        brightness: Brightness.dark,
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: spotifyGreen,
          onPrimary: Colors.white,
          secondary: spotifyGreen,
          onSecondary: Colors.white,
          error: Colors.red,
          onError: Colors.white,
          background: Color(0xFF121212),
          onBackground: Colors.white,
          surface: Color(0xFF121212),
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: spotifyGreen,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          elevation: 0,
        ),
      ),
      initialRoute: '/', // Start with the splash screen.
      routes: {
        '/': (_) => const SplashScreen(),
        '/getStarted': (_) => const GetStartedScreen(),
        '/mainNav': (_) => const MainNavigationScreen(),
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
