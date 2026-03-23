import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/song.dart';
import '../repositories/song_repository.dart';

part 'song_list_provider.g.dart';

/// StreamProvider that listens to the Firestore repository and exposes a list of all Songs.
@riverpod
Stream<List<Song>> songList(SongListRef ref) {
  // Return the stream of songs from the repository.
  return ref.watch(songRepositoryProvider).getSongsStream();
}
