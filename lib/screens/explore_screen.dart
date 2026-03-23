// lib/screens/explore_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audio_service/audio_service.dart';
import '../providers/song_list_provider.dart';
import '../providers/filter_provider.dart'; // IMPORTED
import '../widgets/section_header.dart';
import '../providers/audio_player_provider.dart';
import '../services/audio_player_handler.dart';
import '../models/song.dart';
import 'home_screen.dart'; // IMPORTED for showAddToPlaylistDialog

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(songListProvider);
    final activeFilter = ref.watch(filterProvider); // WATCH FILTER

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          songsAsync.when(
            data: (allSongs) {
              // 1. Logic: Filter songs based on Category Pill
              final songs = allSongs.where((song) {
                if (activeFilter == "All") return true;
                if (activeFilter == "Teachings")
                  return song.album.toLowerCase().contains('sermon') ||
                      song.album.toLowerCase().contains('teaching');
                if (activeFilter == "Songs")
                  return !song.album.toLowerCase().contains('sermon');
                if (activeFilter == "Prayers")
                  return song.album.toLowerCase().contains('prayer');
                if (activeFilter == "Audiobooks")
                  return song.album.toLowerCase().contains('book');
                return true;
              }).toList();

              if (songs.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text("No content matches this filter.")),
                );
              }

              final featuredSong = songs.first;

              final sermons = songs
                  .where((s) => s.album.toLowerCase().contains('sermon'))
                  .toList();
              final music = songs
                  .where((s) => !s.album.toLowerCase().contains('sermon'))
                  .toList();

              return SliverList(
                delegate: SliverChildListDelegate([
                  const SectionHeader(title: "Featured Today"),
                  _HeroBanner(song: featuredSong),

                  if (music.isNotEmpty) ...[
                    const SectionHeader(title: "Worship & Praise"),
                    _HorizontalSongList(songs: music),
                  ],
                  if (sermons.isNotEmpty) ...[
                    const SectionHeader(title: "Latest Sermons"),
                    _HorizontalSongList(songs: sermons),
                  ],

                  const SizedBox(height: 120),
                ]),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, st) =>
                SliverFillRemaining(child: Center(child: Text("Error: $e"))),
          ),
        ],
      ),
    );
  }
}

/// 🌟 THE HERO BANNER WIDGET
class _HeroBanner extends ConsumerWidget {
  final Song song;
  const _HeroBanner({required this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handler = ref.read(audioPlayerProvider) as AudioPlayerHandler;

    return GestureDetector(
      onLongPress: () =>
          showAddToPlaylistDialog(context, ref, song), // ADDED GESTURE
      onTap: () {
        handler.initPlaylistAndPlay([song.toMediaItem()], 0);
      },
      child: Container(
        height: 200,
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CachedNetworkImage(
                imageUrl: song.coverUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(color: Colors.grey[900]),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "FEATURED CONTENT",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    song.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    song.artist,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
            const Positioned(
              right: 20,
              bottom: 20,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.play_arrow, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🛠️ HORIZONTAL LIST WIDGET
class _HorizontalSongList extends ConsumerWidget {
  final List<Song> songs;
  const _HorizontalSongList({required this.songs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handler = ref.read(audioPlayerProvider) as AudioPlayerHandler;

    return SizedBox(
      height: 230,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          return GestureDetector(
            onLongPress: () =>
                showAddToPlaylistDialog(context, ref, song), // ADDED GESTURE
            onTap: () {
              final List<MediaItem> mediaItems = songs
                  .map((s) => s.toMediaItem())
                  .toList();
              handler.initPlaylistAndPlay(mediaItems, index);
            },
            child: Container(
              width: 160,
              margin: const EdgeInsets.only(right: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    // Added stack for menu icon
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: song.coverUrl,
                          height: 160,
                          width: 160,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[900],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.music_note),
                        ),
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: IconButton(
                          icon: const Icon(
                            Icons.more_vert,
                            color: Colors.white,
                          ),
                          onPressed: () =>
                              showAddToPlaylistDialog(context, ref, song),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    song.artist,
                    maxLines: 1,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
