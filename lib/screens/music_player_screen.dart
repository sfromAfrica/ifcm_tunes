import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../providers/audio_player_provider.dart';
import '../services/audio_player_handler.dart';
import '../models/song.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Recommended for album art

// --- DUMMY DATA (Now using Song model) ---
// Note: We use final because the MediaItem conversion (s.toMediaItem()) requires
// Uri.parse(), which is a runtime operation.
// ------------------------------------------------------------------

class MusicPlayerScreen extends ConsumerWidget {
  const MusicPlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Theme Toggling Logic
    final currentThemeMode = ref.watch(themeModeNotifierProvider);
    final themeNotifier = ref.read(themeModeNotifierProvider.notifier);
    final icon = currentThemeMode == ThemeMode.dark
        ? Icons.light_mode
        : Icons.dark_mode;

    // 2. Get the Audio Handler instance (for calling play/pause/skip methods)
    final playerHandler = ref.read(audioPlayerProvider);

    // 3. Watch the streams for current song metadata and playback state
    // We access the raw streams directly from the playerHandler instance.
    final mediaItemStream = playerHandler.mediaItem;
    final playbackStateStream = playerHandler.playbackState;

    final accentColor = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('IFCM Tunes Player'),
        actions: [
          // Theme Toggle Button
          IconButton(icon: Icon(icon), onPressed: themeNotifier.toggleTheme),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- 1. Current Playing Song Metadata (Title, Artist, Art) ---
            StreamBuilder<MediaItem?>(
              stream: mediaItemStream,
              builder: (context, snapshot) {
                final mediaItem = snapshot.data;
                final artUri = mediaItem?.artUri?.toString();

                return Column(
                  children: [
                    // Album Art
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: artUri != null && artUri.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: artUri,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.broken_image, size: 80),
                              )
                            : Icon(
                                Icons.music_note,
                                size: 80,
                                color: accentColor,
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Title
                    Text(
                      mediaItem?.title ?? 'No Song Loaded',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Artist
                    Text(
                      mediaItem?.artist ?? 'Unknown Artist',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 48),

            // --- 3. Play/Pause/Skip Controls ---
            StreamBuilder<PlaybackState>(
              stream: playbackStateStream, // CORRECT: Raw Stream access
              builder: (context, snapshot) {
                final playbackState = snapshot.data;
                final playing = playbackState?.playing ?? false;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Skip Previous
                    IconButton(
                      icon: const Icon(Icons.skip_previous),
                      iconSize: 48.0,
                      onPressed: playerHandler.skipToPrevious,
                    ),

                    // Main Play/Pause Button
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: accentColor, width: 2),
                      ),
                      child: IconButton(
                        icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                        iconSize: 64.0,
                        color: accentColor,
                        onPressed: playing
                            ? playerHandler.pause
                            : playerHandler.play,
                      ),
                    ),

                    // Skip Next
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      iconSize: 48.0,
                      onPressed: playerHandler.skipToNext,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
