import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';
import 'package:marquee/marquee.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../screens/full_audio_player.dart';

/// Global notifier to control the visibility of the persistent mini player.
ValueNotifier<bool> showPersistentMiniPlayerNotifier = ValueNotifier<bool>(
  true,
);

/// Global metadata variables to be updated from your full player screen.
String globalTrackTitle = "Now Playing: Some Title";
String globalArtistName = "zakir";
String? globalImageUrl = 'https://algodream.in/admin/uploads/default_art.png';
String globalNohaTitle = "Now Playing: Some Noha Title";
String globalNohaArtistName = "Noha Artist";
String? globalNohaImageUrl =
    'https://algodream.in/admin/uploads/default_art.png';

// Reference to the navigator key defined in main.dart
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Constants matching MainNavigationScreen values
const double navBarHeight = 60.0;
const Color primaryColor = Color(0xFF0D9051); // App green color

class PersistentMiniPlayer extends StatefulWidget {
  const PersistentMiniPlayer({Key? key}) : super(key: key);

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

  // Reference to the global player
  AudioPlayer get _player => globalAudioPlayer;

  @override
  void initState() {
    super.initState();
    // Initialize animation controller for the play/pause button
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    // Set initial animation state based on player
    if (_player.playing) {
      _animationController.forward();
    }

    // Subscribe to the player's streams
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

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _shuffleModeEnabledSubscription?.cancel();
    _loopModeSubscription?.cancel();
    _animationController.dispose();
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
      return tag?['audioId'] as String? ?? "1"; // Default to "1" if not found
    }
    return "1"; // Default audio ID
  }

  void _navigateToFullPlayer() {
    // Get the current playing audio ID
    String audioId = _getAudioIdFromPlayer();
    // Use the navigator key to get a navigator context that is guaranteed to exist
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder:
            (context) => FullAudioPlayer(
              audioId: audioId,
              autoPlay: true, // Continue playback
              contentType: ContentType.marsiya,
            ),
      ),
    );
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

        // Determine if we're playing Marsiya or Noha
        bool isMarsiya = true;
        if (audioSource is UriAudioSource) {
          final tag = audioSource.tag as Map<String, dynamic>?;
          final contentType = tag?['contentType'] as String?;
          isMarsiya = contentType != 'ContentType.noha';
        }

        // Get the appropriate title and artist name based on content type
        final title = isMarsiya ? globalTrackTitle : globalNohaTitle;
        final artistName = isMarsiya ? globalArtistName : globalNohaArtistName;
        final imageUrl = isMarsiya ? globalImageUrl : globalNohaImageUrl;

        // Get progress percentage for the progress bar
        final progress =
            _duration.inMilliseconds > 0
                ? _position.inMilliseconds / _duration.inMilliseconds
                : 0.0;

        return Container(
          height: 70,
          margin: EdgeInsets.fromLTRB(
            12,
            4,
            12,
            navBarHeight + bottomInset + 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Progress bar at the top
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF1A8754),
                    ),
                    minHeight: 2.5,
                  ),
                ),
              ),

              // Close button in top right corner
              Positioned(
                top: -8,
                right: -8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        spreadRadius: 0,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _closeMiniPlayer,
                      child: Padding(
                        padding: const EdgeInsets.all(3.0),
                        child: Icon(
                          Icons.close,
                          size: 15,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Main content
              Positioned.fill(
                top: 2.5, // Adjust for progress bar
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    onTap: _navigateToFullPlayer,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                      child: Row(
                        children: [
                          // Album art with better rounded corners
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl:
                                    imageUrl ??
                                    'https://algodream.in/admin/uploads/default_art.png',
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                placeholder:
                                    (_, __) => Container(
                                      color: Colors.grey.shade100,
                                      child: const Icon(
                                        Icons.music_note,
                                        color: Colors.grey,
                                        size: 20,
                                      ),
                                    ),
                                errorWidget:
                                    (_, __, ___) => Container(
                                      color: Colors.grey.shade100,
                                      child: const Icon(
                                        Icons.music_note,
                                        color: Colors.grey,
                                        size: 20,
                                      ),
                                    ),
                              ),
                            ),
                          ),

                          // Song info with better spacing
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Title with marquee for long titles
                                  title.length > 15
                                      ? SizedBox(
                                        height: 18,
                                        child: Marquee(
                                          text: title,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                          scrollAxis: Axis.horizontal,
                                          blankSpace: 20.0,
                                          velocity: 30.0,
                                          pauseAfterRound: const Duration(
                                            seconds: 1,
                                          ),
                                          showFadingOnlyWhenScrolling: true,
                                          fadingEdgeStartFraction: 0.1,
                                          fadingEdgeEndFraction: 0.1,
                                        ),
                                      )
                                      : Text(
                                        title,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),

                                  const SizedBox(height: 4),

                                  // Artist name with appropriate prefix
                                  Text(
                                    isMarsiya
                                        ? "zakir: $artistName"
                                        : "reciter: $artistName",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Playback controls - more elegant
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Previous button
                              IconButton(
                                icon: Icon(
                                  Icons.skip_previous_rounded,
                                  color: Colors.grey.shade800,
                                  size: 24,
                                ),
                                onPressed: _handlePreviousTrack,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                                splashRadius: 18,
                              ),

                              // Play/Pause button with gradient
                              Container(
                                width: 40,
                                height: 40,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF1A8754),
                                      Color(0xFF0D9051),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF1A8754,
                                      ).withOpacity(0.3),
                                      blurRadius: 8,
                                      spreadRadius: 0,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    _isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                  onPressed: () {
                                    if (_isPlaying) {
                                      _player.pause();
                                    } else {
                                      _player.play();
                                    }
                                  },
                                  padding: EdgeInsets.zero,
                                  splashRadius: 20,
                                ),
                              ),

                              // Next button
                              IconButton(
                                icon: Icon(
                                  Icons.skip_next_rounded,
                                  color: Colors.grey.shade800,
                                  size: 24,
                                ),
                                onPressed: _handleNextTrack,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                                splashRadius: 18,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
