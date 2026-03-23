import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/playlist.dart';
import '../models/song.dart';

class PlaylistNotifier extends StateNotifier<List<Playlist>> {
  PlaylistNotifier() : super([]);

  void createPlaylist(String name) {
    final newPlaylist = Playlist(
      id: DateTime.now().toString(),
      name: name,
      songs: [],
    );
    state = [...state, newPlaylist];
  }

  void addSongToPlaylist(String playlistId, Song song) {
    state = [
      for (final playlist in state)
        if (playlist.id == playlistId)
          Playlist(
            id: playlist.id,
            name: playlist.name,
            songs: [...playlist.songs, song],
          )
        else
          playlist,
    ];
  }
}

final playlistProvider =
    StateNotifierProvider<PlaylistNotifier, List<Playlist>>((ref) {
      return PlaylistNotifier();
    });
