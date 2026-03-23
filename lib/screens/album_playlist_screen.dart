// lib/screens/album_playlist_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart'; // Added for MediaItem
import '../models/song.dart';
import '../providers/audio_player_provider.dart';
import '../services/audio_player_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'home_screen.dart';

class AlbumPlaylistScreen extends ConsumerWidget {
  final String albumName;
  final List<Song> songs;

  const AlbumPlaylistScreen({
    super.key,
    required this.albumName,
    required this.songs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerHandler = ref.read(audioPlayerProvider) as AudioPlayerHandler;

    return Scaffold(
      appBar: AppBar(title: Text(albumName)),
      body: Column(
        children: [
          // Album Header Section
          Container(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: songs.first.coverUrl,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey.shade800,
                      child: const Icon(Icons.album, size: 60),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey.shade800,
                      child: const Icon(Icons.music_note, size: 60),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        albumName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        songs.first.artist,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${songs.length} Tracks",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Track List with Live Highlighting
          Expanded(
            child: StreamBuilder<MediaItem?>(
              stream: playerHandler.mediaItem,
              builder: (context, snapshot) {
                final playingItem = snapshot.data;

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final song = songs[index];

                    // CHECK: Does this song's URL match the currently playing track?
                    // We use audioUrl because it's the unique ID for the MediaItem
                    final bool isCurrent = playingItem?.id == song.audioUrl;

                    return ListTile(
                      // Apply a light background highlight if it's the current song
                      tileColor: isCurrent
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.1)
                          : null,
                      leading: SizedBox(
                        width: 30,
                        child: Text(
                          "${index + 1}",
                          style: TextStyle(
                            color: isCurrent
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade500,
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      title: Text(
                        song.title,
                        style: TextStyle(
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isCurrent
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                      subtitle: Text(song.artist),
                      // CHANGE: Icon changes from Play to Volume Up if playing
                      trailing: Icon(
                        isCurrent ? Icons.volume_up : Icons.play_circle_outline,
                        color: isCurrent
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                        size: 28,
                      ),
                      onTap: () {
                        final mediaItems = songs
                            .map((s) => s.toMediaItem())
                            .toList();
                        playerHandler.initPlaylistAndPlay(mediaItems, index);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const MiniPlayer(),
    );
  }
}
