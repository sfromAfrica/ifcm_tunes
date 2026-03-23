// lib/models/song.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audio_service/audio_service.dart';

/// Model for synchronized lyrics line
class LyricLine {
  final Duration time;
  final String text;

  LyricLine({required this.time, required this.text});
}

/// A robust data model for a single song/track in the IFCM Tunes library.
class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String audioUrl;
  final String coverUrl;
  final String lyricsUrl; // Added lyricsUrl
  final Duration duration;
  final bool isDownloaded;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.audioUrl,
    required this.coverUrl,
    required this.lyricsUrl, // Added lyricsUrl
    required this.duration,
    this.isDownloaded = false,
  });

  // --- Factory Method for Firestore (Database Sync) ---

  factory Song.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    final durationSec = (data['durationSeconds'] as num?)?.toInt() ?? 0;

    return Song(
      id: snapshot.id,
      title: (data['title'] as String?) ?? 'Untitled Track',
      artist: (data['artist'] as String?) ?? 'Unknown Artist',
      album: (data['album'] as String?) ?? 'IFCM Tunes Catalog',
      audioUrl: (data['audioUrl'] as String?) ?? '',
      coverUrl: (data['coverUrl'] as String?) ?? '',
      lyricsUrl: (data['lyricsUrl'] as String?) ?? '', // Added lyricsUrl
      duration: Duration(seconds: durationSec),
      isDownloaded: data['isDownloaded'] as bool? ?? false,
    );
  }

  // --- Methods for Audio Service Integration ---

  MediaItem toMediaItem() {
    return MediaItem(
      id: audioUrl,
      album: album,
      title: title,
      artist: artist,
      duration: duration,
      artUri: coverUrl.isNotEmpty ? Uri.tryParse(coverUrl) : null,
      extras: {
        'songId': id,
        'isDownloaded': isDownloaded,
        'lyricsUrl': lyricsUrl, // Pass lyricsUrl to MediaItem extras
      },
    );
  }

  // --- LRC Parser Logic ---
  static List<LyricLine> parseLrc(String lrcContent) {
    final lines = lrcContent.split('\n');
    final RegExp regExp = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)');
    List<LyricLine> lyricLines = [];

    for (var line in lines) {
      final match = regExp.firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final milliseconds = int.parse(match.group(3)!);
        final text = match.group(4)!.trim();

        lyricLines.add(
          LyricLine(
            time: Duration(
              minutes: minutes,
              seconds: seconds,
              milliseconds: milliseconds * 10,
            ),
            text: text,
          ),
        );
      }
    }
    return lyricLines;
  }

  // --- JSON Serialization ---

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      album: json['album'] as String,
      audioUrl: json['audioUrl'] as String,
      coverUrl: json['coverUrl'] as String,
      lyricsUrl: json['lyricsUrl'] as String? ?? '',
      duration: Duration(seconds: (json['durationSeconds'] as num).toInt()),
      isDownloaded: json['isDownloaded'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'audioUrl': audioUrl,
      'coverUrl': coverUrl,
      'lyricsUrl': lyricsUrl,
      'durationSeconds': duration.inSeconds,
      'isDownloaded': isDownloaded,
    };
  }

  // --- copyWith Method ---

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? audioUrl,
    String? coverUrl,
    String? lyricsUrl,
    Duration? duration,
    bool? isDownloaded,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      audioUrl: audioUrl ?? this.audioUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      lyricsUrl: lyricsUrl ?? this.lyricsUrl,
      duration: duration ?? this.duration,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }
}
