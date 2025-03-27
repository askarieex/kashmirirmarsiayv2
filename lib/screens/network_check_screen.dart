import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

class NetworkCheckScreen extends StatefulWidget {
  const NetworkCheckScreen({super.key});

  @override
  State<NetworkCheckScreen> createState() => _NetworkCheckScreenState();
}

class _NetworkCheckScreenState extends State<NetworkCheckScreen>
    with SingleTickerProviderStateMixin {
  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _scaleAnimation;

  // State variables
  bool _isCheckingConnection = false;
  bool _isNavigating = false;
  Timer? _autoCheckTimer;

  @override
  void initState() {
    super.initState();
    debugPrint('Network check screen initialized');

    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.7, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();

    // Start periodic connectivity check with a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _startPeriodicConnectivityCheck();
      }
    });
  }

  @override
  void dispose() {
    _autoCheckTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  // Start periodic connectivity check every 5 seconds
  void _startPeriodicConnectivityCheck() {
    // Check immediately once
    _checkInternetConnection();

    // Then check every 5 seconds
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || _isNavigating) {
        timer.cancel();
        return;
      }
      _checkInternetConnection();
    });
  }

  // Check internet connectivity
  Future<void> _checkInternetConnection() async {
    if (_isCheckingConnection || _isNavigating) return;

    setState(() {
      _isCheckingConnection = true;
    });

    // Always clear the checking flag after a timeout to prevent getting stuck
    Timer(const Duration(milliseconds: 1500), () {
      if (mounted && _isCheckingConnection) {
        setState(() {
          _isCheckingConnection = false;
        });
      }
    });

    try {
      // First check device connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      debugPrint('Periodic connectivity check: $connectivityResult');

      // If device shows as connected, try to reach internet
      if (connectivityResult != ConnectivityResult.none) {
        try {
          final response = await http
              .get(Uri.parse('https://google.com'))
              .timeout(const Duration(seconds: 1));

          if (response.statusCode == 200) {
            // Internet is available, navigate to splash screen
            _navigateToSplashScreen();
            return;
          }
        } catch (e) {
          debugPrint('Connection test failed: $e');
        }
      }

      // If we get here, we're still offline
      if (mounted) {
        setState(() {
          _isCheckingConnection = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingConnection = false;
        });
      }
    }
  }

  // Navigate back to splash screen when connection is restored
  void _navigateToSplashScreen() {
    if (!mounted || _isNavigating) return;

    setState(() {
      _isNavigating = true;
    });

    debugPrint('Internet connection restored, navigating to splash screen');

    // Use pushNamedAndRemoveUntil to clear navigation stack and prevent issues
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  // Retry connection check manually
  void _retryConnection() {
    if (_isNavigating || _isCheckingConnection) return;
    _checkInternetConnection();
  }

  // Continue to app without internet
  void _continueOffline() {
    if (_isNavigating) return;

    setState(() {
      _isNavigating = true;
    });

    debugPrint('User chose to continue without internet');
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Prevent back button from exiting this screen
      onWillPop: () async => false,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF121212), Color(0xFF1E1E1E)],
            ),
          ),
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Error icon instead of animation
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            color: Colors.red.shade800,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.wifi_off_rounded,
                            color: Colors.white,
                            size: 70,
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // App title
                      FadeTransition(
                        opacity: _fadeInAnimation,
                        child: Text(
                          'Kashmiri Marsiya',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      const Text(
                        'No Internet Connection',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'Please check your internet connection to access all features',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),

                      const SizedBox(height: 40),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed:
                                _isCheckingConnection ? null : _retryConnection,
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: const Color(
                                0xFF1DB954,
                              ), // Spotify Green
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _isCheckingConnection
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                    : const Icon(Icons.refresh),
                                const SizedBox(width: 8),
                                const Text(
                                  'Try Again',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: _continueOffline,
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.grey[800],
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.offline_bolt),
                                SizedBox(width: 8),
                                Text(
                                  'Continue Offline',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      Text(
                        'Auto-checking for connection...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
