// lib/screens/full_player_screen.dart

import 'dart:ui'; // Required for BackdropFilter
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:http/http.dart' as http;

import '../providers/audio_player_provider.dart';
import '../services/audio_player_handler.dart';
import '../models/song.dart';

class _PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;
  _PositionData(this.position, this.bufferedPosition, this.duration);
}

Stream<_PositionData> _positionDataStream(AudioPlayer audioPlayer) {
  return Rx.combineLatest3<Duration, Duration, Duration?, _PositionData>(
    audioPlayer.positionStream,
    audioPlayer.bufferedPositionStream,
    audioPlayer.durationStream,
    (position, bufferedPosition, duration) =>
        _PositionData(position, bufferedPosition, duration ?? Duration.zero),
  );
}

class FullPlayerScreen extends ConsumerStatefulWidget {
  const FullPlayerScreen({super.key});

  @override
  ConsumerState<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends ConsumerState<FullPlayerScreen> {
  List<LyricLine> _lyrics = [];
  String _currentLyricsUrl = "";
  bool _isLoadingLyrics = false;
  String? _lyricErrorMessage;

  // Controller for the draggable sheet
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  bool _isLyricsMaximized = false;

  // We set the stop point just below the top nav bar (roughly 88% of height)
  static const double _lyricsMaxHeight = 0.886;
  static const double _lyricsMinHeight = 0.15;

  Future<void> _fetchLyrics(String url) async {
    if (url.isEmpty || url == _currentLyricsUrl) return;

    Future.microtask(() {
      if (!mounted) return;
      setState(() {
        _isLoadingLyrics = true;
        _lyricErrorMessage = null;
        _currentLyricsUrl = url;
        _lyrics = [];
      });
    });

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final parsedLyrics = Song.parseLrc(response.body);
        setState(() {
          _lyrics = parsedLyrics;
          _isLoadingLyrics = false;
        });
      } else {
        setState(() {
          _isLoadingLyrics = false;
          _lyricErrorMessage =
              "Error ${response.statusCode}: Lyrics unavailable.";
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingLyrics = false;
        _lyricErrorMessage = "Network error. Please check CORS.";
      });
    }
  }

  void _toggleLyricsSize() {
    setState(() {
      _isLyricsMaximized = !_isLyricsMaximized;
    });
    _sheetController.animateTo(
      _isLyricsMaximized ? _lyricsMaxHeight : _lyricsMinHeight,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  // --- Queue Management UI (Fixed Skip Logic) ---
  void _showQueueSheet(BuildContext context, AudioPlayerHandler handler) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final queue = handler.queue.value;
            final currentIndex = handler.audioPlayer.currentIndex;

            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                children: [
                  AppBar(
                    title: Text('Up Next (${queue.length} Tracks)'),
                    centerTitle: true,
                    automaticallyImplyLeading: false,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: queue.length,
                      itemBuilder: (context, index) {
                        final item = queue[index];
                        final isCurrent = index == currentIndex;

                        return ListTile(
                          leading: Icon(
                            isCurrent ? Icons.volume_up : Icons.music_note,
                            color: isCurrent
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                          ),
                          title: Text(
                            item.title,
                            style: TextStyle(
                              fontWeight: isCurrent
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(item.artist ?? 'Unknown Artist'),
                          onTap: () async {
                            // Fixed: Ensure we skip to the index and explicitly call play
                            await handler.skipToQueueItem(index);
                            handler.play();
                            if (context.mounted) Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerHandler = ref.read(audioPlayerProvider) as AudioPlayerHandler;
    final audioPlayer = playerHandler.audioPlayer;
    final accentColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Now Playing'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.queue_music),
            onPressed: () => _showQueueSheet(context, playerHandler),
          ),
        ],
      ),
      body: StreamBuilder<MediaItem?>(
        stream: playerHandler.mediaItem,
        builder: (context, mediaSnapshot) {
          final mediaItem = mediaSnapshot.data;
          final duration = mediaItem?.duration ?? Duration.zero;

          final String lyricsUrl = mediaItem?.extras?['lyricsUrl'] ?? "";
          if (lyricsUrl.isNotEmpty && lyricsUrl != _currentLyricsUrl) {
            _fetchLyrics(lyricsUrl);
          }

          return StreamBuilder<_PositionData>(
            stream: _positionDataStream(audioPlayer),
            builder: (context, positionSnapshot) {
              final positionData = positionSnapshot.data;
              final position = positionData?.position ?? Duration.zero;
              final bufferedPosition =
                  positionData?.bufferedPosition ?? Duration.zero;

              return Stack(
                children: [
                  // Main Player UI
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _AlbumArtWidget(
                          mediaItem: mediaItem,
                          accentColor: accentColor,
                        ),
                        const SizedBox(height: 20),
                        _MetadataWidget(
                          mediaItem: mediaItem,
                          accentColor: accentColor,
                        ),
                        _SeekBar(
                          duration: duration,
                          position: position,
                          bufferedPosition: bufferedPosition,
                          accentColor: accentColor,
                          onSeek: playerHandler.seek,
                        ),
                        _ControlsWidget(
                          playerHandler: playerHandler,
                          accentColor: accentColor,
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),

                  // Draggable Lyrics Sheet
                  if (_lyrics.isNotEmpty ||
                      _isLoadingLyrics ||
                      _lyricErrorMessage != null)
                    DraggableScrollableSheet(
                      controller: _sheetController,
                      initialChildSize: _lyricsMinHeight,
                      minChildSize: _lyricsMinHeight,
                      maxChildSize: _lyricsMaxHeight,
                      builder: (context, scrollController) {
                        return ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(25),
                          ),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surface.withOpacity(0.7),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(25),
                                ),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 0.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 5,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const SizedBox(width: 40),
                                        Container(
                                          width: 40,
                                          height: 2,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.withOpacity(0.5),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            _isLyricsMaximized
                                                ? Icons.close_fullscreen
                                                : Icons.open_in_full,
                                            size: 20,
                                          ),
                                          onPressed: _toggleLyricsSize,
                                        ),
                                      ],
                                    ),
                                  ),

                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                      ),
                                      child: _isLoadingLyrics
                                          ? const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            )
                                          : _lyricErrorMessage != null
                                          ? Center(
                                              child: Text(
                                                _lyricErrorMessage!,
                                                style: const TextStyle(
                                                  color: Colors.redAccent,
                                                ),
                                              ),
                                            )
                                          : _LyricsWidget(
                                              lyrics: _lyrics,
                                              currentPosition: position,
                                              scrollController:
                                                  scrollController,
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _LyricsWidget extends StatefulWidget {
  final List<LyricLine> lyrics;
  final Duration currentPosition;
  final ScrollController scrollController;

  const _LyricsWidget({
    required this.lyrics,
    required this.currentPosition,
    required this.scrollController,
  });

  @override
  State<_LyricsWidget> createState() => _LyricsWidgetState();
}

class _LyricsWidgetState extends State<_LyricsWidget> {
  int _currentIndex = -1;

  @override
  void didUpdateWidget(_LyricsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    int newIndex = -1;
    for (int i = 0; i < widget.lyrics.length; i++) {
      if (widget.currentPosition >= widget.lyrics[i].time) {
        newIndex = i;
      } else {
        break;
      }
    }
    if (newIndex != -1 && newIndex != _currentIndex) {
      _currentIndex = newIndex;
      _scrollToIndex(newIndex);
    }
  }

  void _scrollToIndex(int index) {
    if (!widget.scrollController.hasClients) return;
    const double itemHeight = 60.0;
    double targetScroll = (index * itemHeight) - 120;
    widget.scrollController.animateTo(
      targetScroll.clamp(0.0, widget.scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = Theme.of(context).colorScheme.onSurface;

    return ListView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.only(top: 20, bottom: 150),
      itemCount: widget.lyrics.length,
      itemBuilder: (context, index) {
        final line = widget.lyrics[index];
        final bool isActive = index == _currentIndex;

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 400),
          opacity: isActive ? 1.0 : 0.2,
          child: Container(
            height: 60,
            alignment: Alignment.center,
            child: Text(
              line.text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isActive ? 24 : 20,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: textColor,
                shadows: isActive
                    ? []
                    : [
                        Shadow(
                          blurRadius: 8,
                          color: textColor.withOpacity(0.5),
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

// --- UI Sub-Widgets ---

class _AlbumArtWidget extends StatelessWidget {
  final MediaItem? mediaItem;
  final Color accentColor;
  const _AlbumArtWidget({required this.mediaItem, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final artUri = mediaItem?.artUri?.toString();
    final size = MediaQuery.of(context).size.width * 0.7;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: size,
          height: size,
          color: Colors.grey.withOpacity(0.1),
          child: artUri != null && artUri.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: artUri,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) =>
                      Icon(Icons.music_note, size: 60, color: accentColor),
                )
              : Icon(Icons.music_note, size: 60, color: accentColor),
        ),
      ),
    );
  }
}

class _MetadataWidget extends StatelessWidget {
  final MediaItem? mediaItem;
  final Color accentColor;
  const _MetadataWidget({required this.mediaItem, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          mediaItem?.title ?? 'Loading...',
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          mediaItem?.artist ?? 'Unknown Artist',
          style: TextStyle(fontSize: 18, color: accentColor.withOpacity(0.8)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ControlsWidget extends StatelessWidget {
  final AudioPlayerHandler playerHandler;
  final Color accentColor;
  const _ControlsWidget({
    required this.playerHandler,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            StreamBuilder<bool>(
              stream: playerHandler.shuffleModeEnabledStream,
              builder: (context, snapshot) {
                final isShuffle = snapshot.data ?? false;
                return IconButton(
                  icon: Icon(
                    Icons.shuffle,
                    color: isShuffle ? accentColor : Colors.grey,
                  ),
                  onPressed: playerHandler.toggleShuffle,
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.skip_previous, size: 40),
              onPressed: playerHandler.skipToPrevious,
            ),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: accentColor, width: 2),
              ),
              child: IconButton(
                icon: StreamBuilder<PlaybackState>(
                  stream: playerHandler.playbackState,
                  builder: (context, snapshot) {
                    final isPlaying = snapshot.data?.playing ?? false;
                    return Icon(isPlaying ? Icons.pause : Icons.play_arrow);
                  },
                ),
                iconSize: 55.0,
                color: accentColor,
                onPressed: () {
                  final isPlaying = playerHandler.playbackState.value.playing;
                  if (isPlaying) {
                    playerHandler.pause();
                  } else {
                    playerHandler.play();
                  }
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.skip_next, size: 40),
              onPressed: playerHandler.skipToNext,
            ),
            StreamBuilder<LoopMode>(
              stream: playerHandler.loopModeStream,
              builder: (context, snapshot) {
                final loopMode = snapshot.data ?? LoopMode.off;
                IconData icon = Icons.repeat;
                Color color = Colors.grey;
                if (loopMode == LoopMode.all) color = accentColor;
                if (loopMode == LoopMode.one) {
                  icon = Icons.repeat_one;
                  color = accentColor;
                }
                return IconButton(
                  icon: Icon(icon, color: color),
                  onPressed: playerHandler.cycleRepeatMode,
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Playback Speed Controls
        StreamBuilder<double>(
          stream: playerHandler.speedStream,
          builder: (context, snapshot) {
            final currentSpeed = snapshot.data ?? 1.0;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.speed,
                  size: 16,
                  color: accentColor.withOpacity(0.7),
                ),
                const SizedBox(width: 8),
                DropdownButton<double>(
                  value: currentSpeed,
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  underline: const SizedBox(),
                  icon: Icon(Icons.arrow_drop_down, color: accentColor),
                  items: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((double value) {
                    return DropdownMenuItem<double>(
                      value: value,
                      child: Text(
                        "${value}x",
                        style: TextStyle(
                          color: value == currentSpeed ? accentColor : null,
                          fontWeight: value == currentSpeed
                              ? FontWeight.bold
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (double? newValue) {
                    if (newValue != null) {
                      playerHandler.setSpeed(newValue);
                    }
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SeekBar extends StatelessWidget {
  final Duration duration;
  final Duration position;
  final Duration bufferedPosition;
  final Color accentColor;
  final ValueChanged<Duration> onSeek;

  const _SeekBar({
    required this.duration,
    required this.position,
    required this.bufferedPosition,
    required this.accentColor,
    required this.onSeek,
  });

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Slider(
          min: 0.0,
          max: duration.inMilliseconds.toDouble(),
          value: position.inMilliseconds.toDouble().clamp(
            0.0,
            duration.inMilliseconds.toDouble(),
          ),
          onChanged: (value) => onSeek(Duration(milliseconds: value.round())),
          activeColor: accentColor,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(position),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                _formatDuration(duration),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
