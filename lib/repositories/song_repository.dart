import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/song.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A Riverpod provider to give access to the SongRepository instance.
final songRepositoryProvider = Provider((ref) => SongRepository());

/// Repository class responsible for fetching and managing song data from Firestore.
class SongRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _songCollection = 'songs';

  /// Fetches a stream of all songs available in the database.
  Stream<List<Song>> getSongsStream() {
    return _firestore
        .collection(_songCollection)
        .orderBy('title')
        .snapshots() // Stream of query snapshots
        .map((snapshot) {
          // Map the snapshot list to a list of Song objects
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;

            // Convert the Firestore data map into our Song model
            return Song.fromJson(data);
          }).toList();
        });
  }
}
