import 'dart:ui'; // Required for BackdropFilter
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audio_service/audio_service.dart';
import 'package:rxdart/rxdart.dart';
import '../providers/filter_provider.dart';
import '../providers/song_list_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/audio_player_provider.dart';
import '../providers/playlist_provider.dart'; // IMPORTED
import '../models/song.dart';
import '../models/playlist.dart'; // IMPORTED
import '../services/audio_player_handler.dart';
import '../widgets/side_nav_bar.dart';
import 'full_player_screen.dart';
import 'album_playlist_screen.dart';
import 'explore_screen.dart';
import 'search_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  bool _isCreateMenuOpen = false;
  bool _isSidebarOpen = false; // Track Sidebar state
  final double _drawerWidth = 280.0; // Standard drawer width

  // Logic for Filter Chips
  String _selectedFilter = "All";
  final List<String> _filters = [
    "All",
    "Teachings",
    "Songs",
    "Prayers",
    "Audiobooks",
  ];

  final List<Widget> _pages = [
    const ExploreScreen(), // Index 0
    const LibraryView(), // Index 1
    const SearchScreen(), // Index 2
    const SizedBox.shrink(), // Index 3 (Placeholder)
  ];

  // Helper method to show the naming dialog
  void _showNewPlaylistDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New Playlist"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Give your playlist a name",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref
                    .read(playlistProvider.notifier)
                    .createPlaylist(controller.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Created "${controller.text}"')),
                );
              }
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = ref.read(themeModeNotifierProvider.notifier);
    final currentThemeMode = ref.watch(themeModeNotifierProvider);
    final String userName = "Dumo";

    final themeIcon = currentThemeMode == ThemeMode.dark
        ? Icons.light_mode
        : Icons.dark_mode;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          // 1. THE SIDE BAR (Fixed in the background)
          SizedBox(
            width: _drawerWidth,
            child: SideNavBar(userName: userName),
          ),

          // 2. THE MAIN CONTENT (Slides to the right in the background)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            transform: Matrix4.identity()
              ..translate(_isSidebarOpen ? _drawerWidth : 0.0),
            child: Stack(
              children: [
                Scaffold(
                  extendBody: true,
                  appBar: AppBar(
                    leading: IconButton(
                      icon: CircleAvatar(
                        radius: 16,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          userName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      onPressed: () =>
                          setState(() => _isSidebarOpen = !_isSidebarOpen),
                    ),
                    title: Text(
                      _currentIndex == 0
                          ? 'Home'
                          : _currentIndex == 1
                          ? 'IFCM Tunes Library'
                          : 'Search ',
                    ),
                    actions: [
                      IconButton(
                        icon: Icon(themeIcon),
                        onPressed: themeNotifier.toggleTheme,
                      ),
                    ],
                  ),
                  body: Column(
                    children: [
                      // --- ADDED FILTER CHIPS SECTION ---
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: Row(
                          children: _filters.map((filter) {
                            final isSelected = _selectedFilter == filter;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(filter),
                                selected: isSelected,
                                onSelected: (bool selected) {
                                  setState(() {
                                    _selectedFilter = filter;
                                  });
                                  ref.read(filterProvider.notifier).state =
                                      filter;
                                },
                                shape: const StadiumBorder(),
                                showCheckmark: false,
                                selectedColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      // --- END FILTER CHIPS ---
                      Expanded(
                        child: Stack(
                          children: [
                            IndexedStack(
                              index: _currentIndex == 3 ? 0 : _currentIndex,
                              children: _pages,
                            ),
                            if (_isCreateMenuOpen)
                              Positioned.fill(
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _isCreateMenuOpen = false),
                                  child: Container(
                                    color: Colors.black.withOpacity(0.3),
                                  ),
                                ),
                              ),
                            if (_isCreateMenuOpen) _buildCreateMenu(context),
                          ],
                        ),
                      ),
                    ],
                  ),
                  bottomNavigationBar: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [const MiniPlayer(), _buildBottomNavBar(context)],
                  ),
                ),

                if (_isSidebarOpen)
                  GestureDetector(
                    onTap: () => setState(() => _isSidebarOpen = false),
                    child: Container(color: Colors.black.withOpacity(0.4)),
                  ),
              ],
            ),
          ),

          // 2. THE SIDE BAR (Moves in front)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: _isSidebarOpen ? 0 : -_drawerWidth,
            top: 0,
            bottom: 0,
            width: _drawerWidth,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  if (_isSidebarOpen)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: SideNavBar(userName: userName),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface.withOpacity(0.6),
      child: BottomNavigationBar(
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        currentIndex: _currentIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: (index) {
          if (index == 3) {
            setState(() {
              _isCreateMenuOpen = !_isCreateMenuOpen;
            });
          } else {
            setState(() {
              _currentIndex = index;
              _isCreateMenuOpen = false;
              _isSidebarOpen = false;
            });
          }
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.library_music_outlined),
            activeIcon: Icon(Icons.library_music),
            label: 'Library',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: AnimatedRotation(
              duration: const Duration(milliseconds: 300),
              turns: _isCreateMenuOpen ? 0.375 : 0,
              child: Icon(
                _isCreateMenuOpen ? Icons.add : Icons.add_circle_outline,
              ),
            ),
            label: 'Create',
          ),
        ],
      ),
    );
  }

  Widget _buildCreateMenu(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 155, left: 16, right: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  ListTile(
                    leading: const Icon(Icons.playlist_add),
                    title: const Text('New Playlist'),
                    onTap: () {
                      setState(() => _isCreateMenuOpen = false);
                      _showNewPlaylistDialog(context, ref);
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- LibraryView, AlbumGridTile, MiniPlayer, and showAddToPlaylistDialog classes remain unchanged below this line ---

class LibraryView extends ConsumerWidget {
  const LibraryView({super.key});

  Map<String, List<Song>> _groupSongsByAlbum(List<Song> allSongs) {
    Map<String, List<Song>> albumGroups = {};
    for (var song in allSongs) {
      if (!albumGroups.containsKey(song.album)) {
        albumGroups[song.album] = [];
      }
      albumGroups[song.album]!.add(song);
    }
    return albumGroups;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsyncValue = ref.watch(songListProvider);
    final playlists = ref.watch(playlistProvider);

    return songsAsyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (songs) {
        if (songs.isEmpty && playlists.isEmpty)
          return const Center(child: Text('No content found.'));

        final albumMap = _groupSongsByAlbum(songs);
        final albumNames = albumMap.keys.toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 180),
          children: [
            // --- SECTION 1: PLAYLISTS ---
            if (playlists.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  "Your Playlists",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    return Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade800,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.playlist_play,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            playlist.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // --- SECTION 2: ALBUMS ---
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "Albums & Series",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            GridView.builder(
              shrinkWrap: true, // Needed because it's inside a ListView
              physics:
                  const NeverScrollableScrollPhysics(), // Scroll handled by parent
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: albumNames.length,
              itemBuilder: (context, index) {
                final name = albumNames[index];
                final albumSongs = albumMap[name]!;
                return AlbumGridTile(albumName: name, songs: albumSongs);
              },
            ),
          ],
        );
      },
    );
  }
}

class AlbumGridTile extends StatelessWidget {
  final String albumName;
  final List<Song> songs;
  const AlbumGridTile({
    super.key,
    required this.albumName,
    required this.songs,
  });

  @override
  Widget build(BuildContext context) {
    final String coverUrl = songs.first.coverUrl;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                AlbumPlaylistScreen(albumName: albumName, songs: songs),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: coverUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade800,
                  child: const Icon(Icons.album),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey.shade800,
                  child: const Icon(Icons.error_outline),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            albumName,
            style: const TextStyle(fontWeight: FontWeight.bold),
            maxLines: 1,
          ),
          Text(
            songs.first.artist,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerHandler = ref.watch(audioPlayerProvider);
    final accentColor = Theme.of(context).colorScheme.primary;

    final combinedStream =
        Rx.combineLatest2<MediaItem?, PlaybackState, Map<String, dynamic>>(
          playerHandler.mediaItem,
          playerHandler.playbackState,
          (mediaItem, playbackState) => {
            'item': mediaItem,
            'state': playbackState,
          },
        );

    return StreamBuilder<Map<String, dynamic>>(
      stream: combinedStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final mediaItem = snapshot.data!['item'] as MediaItem?;
        final playbackState = snapshot.data!['state'] as PlaybackState;

        if (mediaItem == null &&
            playbackState.processingState == AudioProcessingState.idle)
          return const SizedBox.shrink();
        final isPlaying = playbackState.playing;

        return GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const FullPlayerScreen()),
          ),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              border: Border(
                top: BorderSide(color: Colors.black.withOpacity(0.1)),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: (mediaItem?.artUri != null)
                      ? CachedNetworkImage(
                          imageUrl: mediaItem!.artUri!.toString(),
                          width: 45,
                          height: 45,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.album, size: 30),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mediaItem?.title ?? "No Track",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        mediaItem?.artist ?? "",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                  iconSize: 36,
                  color: accentColor,
                  onPressed: mediaItem != null
                      ? (isPlaying ? playerHandler.pause : playerHandler.play)
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  iconSize: 28,
                  onPressed: mediaItem != null
                      ? playerHandler.skipToNext
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

void showAddToPlaylistDialog(BuildContext context, WidgetRef ref, Song song) {
  final playlists = ref.watch(playlistProvider);

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Add to Playlist",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            if (playlists.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text("No playlists created yet.")),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    return ListTile(
                      leading: const Icon(Icons.playlist_add),
                      title: Text(playlist.name),
                      onTap: () {
                        ref
                            .read(playlistProvider.notifier)
                            .addSongToPlaylist(playlist.id, song);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Added to ${playlist.name}')),
                        );
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
}
