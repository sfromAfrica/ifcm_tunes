// lib/screens/search_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audio_service/audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/song_list_provider.dart';
import '../providers/audio_player_provider.dart';
import '../providers/filter_provider.dart'; // IMPORTED
import '../services/audio_player_handler.dart';
import '../models/song.dart';
import 'home_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = "";
  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('recent_searches') ?? [];
    });
  }

  Future<void> _saveSearch(String term) async {
    if (term.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    _recentSearches.remove(term);
    _recentSearches.insert(0, term);
    if (_recentSearches.length > 10) _recentSearches.removeLast();
    await prefs.setStringList('recent_searches', _recentSearches);
    setState(() {});
  }

  Future<void> _deleteSearch(String term) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches.remove(term);
    });
    await prefs.setStringList('recent_searches', _recentSearches);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final songsAsync = ref.watch(songListProvider);
    final playerHandler = ref.read(audioPlayerProvider) as AudioPlayerHandler;
    final activeFilter = ref.watch(filterProvider); // WATCH FILTER

    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) =>
                  setState(() => _query = value.toLowerCase()),
              onSubmitted: (value) => _saveSearch(value),
              decoration: InputDecoration(
                hintText: "Titles, Pastors, or Series...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = "");
                        },
                      )
                    : null,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Expanded(
            child: _query.isEmpty
                ? _buildHistoryView()
                : _buildResultsView(
                    songsAsync,
                    playerHandler,
                    activeFilter, // PASS FILTER
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryView() {
    if (_recentSearches.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 60, color: Colors.grey),
            SizedBox(height: 10),
            Text("No recent searches", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            "Recent",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _recentSearches.length,
            itemBuilder: (context, index) {
              final term = _recentSearches[index];
              return ListTile(
                leading: const Icon(Icons.history, size: 20),
                title: Text(term),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => _deleteSearch(term),
                ),
                onTap: () {
                  setState(() {
                    _query = term.toLowerCase();
                    _searchController.text = term;
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResultsView(
    AsyncValue<List<Song>> songsAsync,
    AudioPlayerHandler playerHandler,
    String activeFilter, // ADDED PARAMETER
  ) {
    return songsAsync.when(
      data: (songs) {
        final filteredSongs = songs.where((song) {
          // 1. Filter by Search Query
          final matchesQuery =
              song.title.toLowerCase().contains(_query) ||
              song.artist.toLowerCase().contains(_query) ||
              song.album.toLowerCase().contains(_query);

          // 2. Filter by Category Pill
          bool matchesCategory = true;
          if (activeFilter == "Teachings")
            matchesCategory = song.album.toLowerCase().contains('sermon');
          if (activeFilter == "Songs")
            matchesCategory = !song.album.toLowerCase().contains('sermon');
          if (activeFilter == "Prayers")
            matchesCategory = song.album.toLowerCase().contains('prayer');
          if (activeFilter == "Audiobooks")
            matchesCategory = song.album.toLowerCase().contains('book');

          return matchesQuery && matchesCategory;
        }).toList();

        if (filteredSongs.isEmpty) {
          return const Center(child: Text("No results found"));
        }

        return ListView.separated(
          padding: const EdgeInsets.only(top: 8, bottom: 200),
          itemCount: filteredSongs.length,
          separatorBuilder: (context, index) =>
              const Divider(height: 1, indent: 70),
          itemBuilder: (context, index) {
            final song = filteredSongs[index];
            return ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: song.coverUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.music_note),
                ),
              ),
              title: Text(
                song.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text("${song.artist} • ${song.album}"),
              trailing: IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => showAddToPlaylistDialog(context, ref, song),
              ),
              onTap: () {
                _saveSearch(song.title);
                playerHandler.initPlaylistAndPlay([song.toMediaItem()], 0);
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text("Error: $err")),
    );
  }
}
