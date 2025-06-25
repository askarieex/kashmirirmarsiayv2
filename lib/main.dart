import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'screens/splash_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/about_us_screen.dart';
import 'screens/contact_us_screen.dart';
import 'screens/favourites_screen.dart';
import 'screens/community_screen.dart';
import 'screens/history_screen.dart';
import 'screens/full_marsiya_screen.dart';
import 'screens/marsiya_audio_screen.dart';
import 'screens/full_noha_audio_play.dart';
import 'screens/noha_audio_screen.dart';
import 'screens/view_profile_screen.dart';
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
  const MyApp({super.key});

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
      // Define static routes for screens that don't need parameters
      routes: {
        '/': (_) => const SplashScreen(),
        '/mainNav': (_) => const MainNavigationScreen(),
        '/about': (_) => const AboutUsScreen(),
        '/contact': (_) => const ContactUsScreen(),
        '/favorites': (_) => const FavouritesScreen(),
        '/community': (_) => const CommunityScreen(),
        '/history': (_) => const HistoryScreen(),
      },

      // Use onGenerateRoute to handle routes that require parameters
      onGenerateRoute: (settings) {
        // Extract route name and arguments
        final routeName = settings.name;
        final args = settings.arguments as Map<String, dynamic>?;

        switch (routeName) {
          case '/full_marsiya_screen':
            return MaterialPageRoute(
              builder: (_) => const FullMarsiyaScreen(),
              settings: settings,
            );

          case '/marsiya_audio_screen':
            return MaterialPageRoute(
              builder: (_) => const MarsiyaAudioScreen(),
              settings: settings,
            );

          case '/full_noha_screen':
            if (args != null && args.containsKey('id')) {
              return MaterialPageRoute(
                builder:
                    (_) => FullNohaAudioPlay(
                      nohaId: args['id'].toString(),
                      autoPlay: true,
                    ),
                settings: settings,
              );
            }
            return null;

          case '/noha_audio_screen':
            return MaterialPageRoute(
              builder: (_) => const NohaAudioScreen(),
              settings: settings,
            );

          case '/view_profile_screen':
            if (args != null && args.containsKey('id')) {
              return MaterialPageRoute(
                builder:
                    (_) => ViewProfileScreen(profileId: args['id'].toString()),
                settings: settings,
              );
            }
            return null;

          default:
            return null;
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
