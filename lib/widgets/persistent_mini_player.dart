import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';
import 'package:marquee/marquee.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../screens/full_marsiya_audio_play.dart';
import '../screens/full_noha_audio_play.dart';

/// Global notifier to control the visibility of the persistent mini player.
ValueNotifier<bool> showPersistentMiniPlayerNotifier = ValueNotifier<bool>(
  true,
);

/// Function to ensure mini-player is shown when audio is playing
void showMiniPlayer() {
  showPersistentMiniPlayerNotifier.value = true;
}

/// Coordinate playback between Noha and Marsiya players to ensure only one is active
void coordPlayerPlayback(bool playNoha) {
  if (playNoha) {
    // If we want to play noha, pause marsiya player if it's playing
    if (globalAudioPlayer.playing) {
      globalAudioPlayer.pause();
      print("Paused Marsiya player to play Noha");
    }
  } else {
    // If we want to play marsiya, pause noha player if it's playing
    if (globalNohaPlayer.playing) {
      globalNohaPlayer.pause();
      print("Paused Noha player to play Marsiya");
    }
  }
}

/// Pause all audio players (useful when you want to silence everything)
void pauseAllPlayers() {
  if (globalAudioPlayer.playing) {
    globalAudioPlayer.pause();
  }
  if (globalNohaPlayer.playing) {
    globalNohaPlayer.pause();
  }
}

/// Global metadata variables for marsiya
String globalTrackTitle = "Now Playing: Some Title";
String globalArtistName = "zakir";
String? globalImageUrl = 'https://algodream.in/admin/uploads/default_art.png';

/// Global metadata variables for noha (using ValueNotifier for reactivity)
ValueNotifier<String> globalNohaTitle = ValueNotifier("Unknown Noha");
ValueNotifier<String> globalNohaArtistName = ValueNotifier("Unknown Artist");
ValueNotifier<String> globalNohaImageUrl = ValueNotifier(
  'https://algodream.in/admin/uploads/default_art.png',
);

// Reference to the navigator key defined in main.dart
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Constants matching MainNavigationScreen values
const double navBarHeight = 60.0;
const Color primaryColor = Color(0xFF0D9051); // App green color

class PersistentMiniPlayer extends StatefulWidget {
  const PersistentMiniPlayer({super.key});

  @override
  _PersistentMiniPlayerState createState() => _PersistentMiniPlayerState();
}

class _PersistentMiniPlayerState extends State<PersistentMiniPlayer>
    with SingleTickerProviderStateMixin {
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  bool _isBuffering = false;
  late AnimationController _animationController;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<bool>? _shuffleModeEnabledSubscription;
  StreamSubscription<LoopMode>? _loopModeSubscription;

  // Add subscriptions to monitor both players
  StreamSubscription<PlayerState>? _marsiyaPlayerStateSubscription;
  StreamSubscription<PlayerState>? _nohaPlayerStateSubscription;

  // Flag to track which player is active
  bool _isNohaPlayerActive = false;

  // Reference to the active player
  AudioPlayer get _player =>
      _isNohaPlayerActive ? globalNohaPlayer : globalAudioPlayer;

  @override
  void initState() {
    super.initState();
    // Check which player is active
    _checkActivePlayer();

    // Initialize animation controller for the play/pause button
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    // Set initial animation state based on player
    if (_player.playing) {
      _animationController.forward();
    }

    // ✅ FIX: Add listeners to global ValueNotifiers for reactive updates
    globalNohaTitle.addListener(_updateUI);
    globalNohaArtistName.addListener(_updateUI);
    globalNohaImageUrl.addListener(_updateUI);

    // Monitor both players to detect changes in active player
    _setupPlayerMonitoring();

    // Subscribe to the player's streams
    _setupPlayerListeners();
  }

  void _updateUI() {
    if (mounted) {
      setState(() {
        // This will trigger a rebuild when global variables change
        print("Mini-player rebuilding due to global variable change");
      });
    }
  }

  void _setupPlayerMonitoring() {
    // Monitor both players to detect changes in active status
    _marsiyaPlayerStateSubscription = globalAudioPlayer.playerStateStream.listen(
      (state) {
        if (state.playing && _isNohaPlayerActive) {
          // Marsiya player started playing, switch to it
          setState(() {
            _isNohaPlayerActive = false;
            _setupPlayerListeners(); // Re-attach listeners to the active player
          });
        }
      },
    );

    _nohaPlayerStateSubscription = globalNohaPlayer.playerStateStream.listen((
      state,
    ) {
      if (state.playing && !_isNohaPlayerActive) {
        // Noha player started playing, switch to it
        setState(() {
          _isNohaPlayerActive = true;
          _setupPlayerListeners(); // Re-attach listeners to the active player
        });
      }
    });
  }

  void _checkActivePlayer() {
    // Check if Noha player has content
    final nohaSource = globalNohaPlayer.audioSource;
    final marsiyaSource = globalAudioPlayer.audioSource;
    final nohaPlaying = globalNohaPlayer.playing;
    final marsiyaPlaying = globalAudioPlayer.playing;

    // If one is playing, use that one
    if (nohaPlaying && !marsiyaPlaying) {
      _isNohaPlayerActive = true;
    } else if (marsiyaPlaying && !nohaPlaying) {
      _isNohaPlayerActive = false;
    }
    // If both or neither are playing, check if they have content
    else {
      // If both have content, prefer the one more recently played or the noha player
      if (nohaSource != null && marsiyaSource != null) {
        _isNohaPlayerActive = nohaPlaying || !marsiyaPlaying;
      } else {
        // Otherwise use the one that has content
        _isNohaPlayerActive = nohaSource != null;
      }
    }

    // For debugging
    print("Active player: ${_isNohaPlayerActive ? 'Noha' : 'Marsiya'}");
    print("Noha player has content: ${nohaSource != null}");
    print("Marsiya player has content: ${marsiyaSource != null}");
    print("Noha player is playing: $nohaPlaying");
    print("Marsiya player is playing: $marsiyaPlaying");
  }

  void _setupPlayerListeners() {
    // Cancel any existing subscriptions
    _disposePlayerListeners();

    // Subscribe to the active player's streams
    _positionSubscription = _player.positionStream.listen((pos) {
      if (mounted) {
        setState(() => _position = pos);
      }
    });

    _durationSubscription = _player.durationStream.listen((dur) {
      if (mounted) {
        setState(() => _duration = dur ?? Duration.zero);
      }
    });

    _playerStateSubscription = _player.playerStateStream.listen((playerState) {
      if (mounted) {
        setState(() {
          _isPlaying = playerState.playing;
          _isBuffering =
              playerState.processingState == ProcessingState.buffering;
          // Update animation controller based on playing state
          if (_isPlaying) {
            _animationController.forward();
          } else {
            _animationController.reverse();
          }
        });
      }
    });

    // Subscribe to shuffle mode changes
    _shuffleModeEnabledSubscription = _player.shuffleModeEnabledStream.listen((
      enabled,
    ) {
      if (mounted) setState(() {});
    });

    // Subscribe to loop mode changes
    _loopModeSubscription = _player.loopModeStream.listen((loopMode) {
      if (mounted) setState(() {});
    });
  }

  void _disposePlayerListeners() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _shuffleModeEnabledSubscription?.cancel();
    _loopModeSubscription?.cancel();
  }

  @override
  void dispose() {
    _disposePlayerListeners();
    _marsiyaPlayerStateSubscription?.cancel();
    _nohaPlayerStateSubscription?.cancel();
    _animationController.dispose();

    // ✅ FIX: Remove listeners to prevent memory leaks
    globalNohaTitle.removeListener(_updateUI);
    globalNohaArtistName.removeListener(_updateUI);
    globalNohaImageUrl.removeListener(_updateUI);

    super.dispose();
  }

  /// Format a [Duration] into mm:ss.
  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  String _getAudioIdFromPlayer() {
    final audioSource = _player.audioSource;
    if (audioSource is UriAudioSource) {
      final tag = audioSource.tag as Map<String, dynamic>?;
      // For noha player
      if (_isNohaPlayerActive) {
        return tag?['nohaId']?.toString() ?? "1"; // Default to "1" if not found
      }
      // For marsiya player
      return tag?['audioId']?.toString() ?? "1"; // Default to "1" if not found
    }
    return "1"; // Default audio ID
  }

  void _navigateToFullPlayer() {
    // Get the current playing audio ID
    String audioId = _getAudioIdFromPlayer();

    // Navigate to the appropriate player screen
    if (_isNohaPlayerActive) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder:
              (context) => FullNohaAudioPlay(nohaId: audioId, autoPlay: true),
        ),
      );
    } else {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder:
              (context) =>
                  FullMarsiyaAudioPlay(audioId: audioId, autoPlay: true),
        ),
      );
    }
  }

  Future<void> _handleNextTrack() async {
    try {
      // Check if we have a next track to play
      if (_player.hasNext) {
        // Show loading indicator
        setState(() => _isBuffering = true);
        // Seek to next track
        await _player.seekToNext();
        // Update loading state
        if (mounted) setState(() => _isBuffering = false);
      } else {
        // Optionally show a snackbar or toast that we're at the end of the playlist
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('End of playlist reached'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Handle error and update UI
      if (mounted) setState(() => _isBuffering = false);
      print('Error seeking to next track: $e');
    }
  }

  Future<void> _handlePreviousTrack() async {
    try {
      // If we're more than 3 seconds into the track, seek to beginning instead of previous track
      if (_position.inSeconds > 3) {
        await _player.seek(Duration.zero);
      } else if (_player.hasPrevious) {
        // Show loading indicator
        setState(() => _isBuffering = true);
        // Seek to previous track
        await _player.seekToPrevious();
        // Update loading state
        if (mounted) setState(() => _isBuffering = false);
      } else {
        // We're at the beginning of the playlist, just restart the current track
        await _player.seek(Duration.zero);
      }
    } catch (e) {
      // Handle error and update UI
      if (mounted) setState(() => _isBuffering = false);
      print('Error seeking to previous track: $e');
    }
  }

  void _closeMiniPlayer() {
    // Hide the mini player
    showPersistentMiniPlayerNotifier.value = false;
    // Optional: Pause playback when closing
    if (_isPlaying) {
      _player.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get bottom inset for proper spacing above nav bar
    final bottomInset = MediaQuery.of(context).padding.bottom;

    // Check both players to see if either has content
    final nohaHasContent = globalNohaPlayer.audioSource != null;
    final marsiyaHasContent = globalAudioPlayer.audioSource != null;

    // If both have no content, don't show player
    if (!nohaHasContent && !marsiyaHasContent) {
      return const SizedBox.shrink();
    }

    // Check player states
    final nohaState = globalNohaPlayer.playerState;
    final marsiyaState = globalAudioPlayer.playerState;

    // Update active player flag based on current state
    if (_isNohaPlayerActive && !nohaHasContent) {
      _isNohaPlayerActive = false;
      _setupPlayerListeners();
    } else if (!_isNohaPlayerActive && !marsiyaHasContent && nohaHasContent) {
      _isNohaPlayerActive = true;
      _setupPlayerListeners();
    }

    // Get the appropriate title, artist, and image based on the active player
    final title =
        _isNohaPlayerActive ? globalNohaTitle.value : globalTrackTitle;
    final artist =
        _isNohaPlayerActive ? globalNohaArtistName.value : globalArtistName;
    final imageUrl =
        _isNohaPlayerActive ? globalNohaImageUrl.value : globalImageUrl;

    return ValueListenableBuilder<bool>(
      valueListenable: showPersistentMiniPlayerNotifier,
      builder: (context, show, child) {
        // If global flag is false, hide mini player
        if (!show) return const SizedBox.shrink();

        // Also hide if no audio source is loaded or player is idle
        final audioSource = _player.audioSource;
        final playerState = _player.playerState;
        if (audioSource == null ||
            playerState.processingState == ProcessingState.idle) {
          return const SizedBox.shrink();
        }

        // Get progress percentage for the progress bar
        final progress =
            _duration.inMilliseconds > 0
                ? _position.inMilliseconds / _duration.inMilliseconds
                : 0.0;

        return Container(
          height: 72,
          margin: EdgeInsets.fromLTRB(4, 4, 4, navBarHeight + bottomInset + 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E), // Dark background matching nav bar
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: primaryColor.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Stack(
                children: [
                  // Main content area with interactive element
                  InkWell(
                    onTap: _navigateToFullPlayer,
                    splashColor: primaryColor.withOpacity(0.1),
                    highlightColor: Colors.white.withOpacity(0.05),
                    child: Column(
                      children: [
                        // Custom progress bar at the top with smoother corners
                        Container(
                          height: 3,
                          margin: EdgeInsets.symmetric(
                            horizontal: 0,
                            vertical: 0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.2),
                          ),
                          alignment: Alignment.centerLeft,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Container(
                                width: constraints.maxWidth * progress,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.4),
                                      blurRadius: 3,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        // Main content of the mini player
                        Expanded(
                          child: Row(
                            children: [
                              // Album image with rounded corners and subtle border
                              Container(
                                width: 54,
                                height: 54,
                                margin: const EdgeInsets.only(left: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: primaryColor.withOpacity(0.4),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      spreadRadius: 0,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: CachedNetworkImage(
                                    imageUrl:
                                        imageUrl ??
                                        'https://algodream.in/admin/uploads/default_art.png',
                                    fit: BoxFit.cover,
                                    placeholder:
                                        (context, url) => Container(
                                          color: Colors.white.withOpacity(0.1),
                                          child: Icon(
                                            Icons.music_note,
                                            color: primaryColor.withOpacity(
                                              0.7,
                                            ),
                                            size: 30,
                                          ),
                                        ),
                                    errorWidget:
                                        (context, url, error) => Container(
                                          color: Colors.white.withOpacity(0.1),
                                          child: Icon(
                                            Icons.music_note,
                                            color: primaryColor.withOpacity(
                                              0.7,
                                            ),
                                            size: 30,
                                          ),
                                        ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Track info: title and artist with improved text styling
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: 20,
                                      child: Marquee(
                                        text: title,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          letterSpacing: 0.3,
                                        ),
                                        scrollAxis: Axis.horizontal,
                                        blankSpace: 40.0,
                                        velocity: 35.0,
                                        pauseAfterRound: const Duration(
                                          seconds: 1,
                                        ),
                                        startPadding: 0.0,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      artist,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        color: primaryColor.withOpacity(0.9),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    // Progress text with improved styling
                                    Row(
                                      children: [
                                        Text(
                                          _formatDuration(_position),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                        Text(
                                          " / ",
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Text(
                                          _formatDuration(_duration),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Enhanced playback controls with better visual effects
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Previous button with ripple effect
                                  ClipOval(
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        splashColor: primaryColor.withOpacity(
                                          0.2,
                                        ),
                                        onTap: _handlePreviousTrack,
                                        child: Container(
                                          padding: EdgeInsets.all(8),
                                          child: Icon(
                                            Icons.skip_previous_rounded,
                                            color: Colors.white,
                                            size: 28,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Play/Pause button with animation
                                  Container(
                                    width: 42,
                                    height: 42,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: primaryColor.withOpacity(0.3),
                                          blurRadius: 8,
                                          spreadRadius: 0,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(21),
                                        splashColor: Colors.white.withOpacity(
                                          0.2,
                                        ),
                                        onTap: () async {
                                          if (_isPlaying) {
                                            await _player.pause();
                                          } else {
                                            // Ensure the other player is paused before playing
                                            if (_isNohaPlayerActive) {
                                              coordPlayerPlayback(true);
                                            } else {
                                              coordPlayerPlayback(false);
                                            }
                                            await _player.play();
                                          }
                                        },
                                        child: Center(
                                          child:
                                              _isBuffering
                                                  ? SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(Colors.white),
                                                    ),
                                                  )
                                                  : AnimatedIcon(
                                                    icon:
                                                        AnimatedIcons
                                                            .play_pause,
                                                    progress:
                                                        _animationController,
                                                    color: Colors.white,
                                                    size: 28,
                                                  ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Next button with ripple effect
                                  ClipOval(
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        splashColor: primaryColor.withOpacity(
                                          0.2,
                                        ),
                                        onTap: _handleNextTrack,
                                        child: Container(
                                          padding: EdgeInsets.all(8),
                                          child: Icon(
                                            Icons.skip_next_rounded,
                                            color: Colors.white,
                                            size: 28,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Close button positioned in the top-right corner
                  Positioned(
                    top: 4,
                    right: 4,
                    child: ClipOval(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _closeMiniPlayer,
                          splashColor: Colors.red.withOpacity(0.2),
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
