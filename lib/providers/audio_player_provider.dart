import 'package:audio_service/audio_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/audio_player_handler.dart';

// Needed for Riverpod code generation
part 'audio_player_provider.g.dart';

// We use an external provider as the AudioHandler needs to be initialized
// BEFORE runApp() and ProviderScope, which is unusual for a typical Riverpod setup.

/// The external provider holds the initialized AudioHandler instance.
/// It is set in the main() function using an override.
final externalAudioHandlerProvider = Provider<AudioHandler>(
  (ref) =>
      throw UnimplementedError('AudioHandler must be provided in main.dart'),
);

/// The main Player State Provider.
/// This provider gives us easy access to the necessary streams and methods.
@riverpod
AudioPlayerHandler audioPlayer(AudioPlayerRef ref) {
  // Cast the generic AudioHandler to our custom handler to access custom methods
  // like initPlaylist().
  return ref.watch(externalAudioHandlerProvider) as AudioPlayerHandler;
}

// --- Utility Providers for UI Access ---

/// Exposes the current MediaItem (the currently playing song's metadata).
@riverpod
Stream<MediaItem?> currentMediaItem(CurrentMediaItemRef ref) {
  final handler = ref.watch(audioPlayerProvider);
  return handler.mediaItem;
}

/// Exposes the current PlaybackState (playing/paused, buffering, position).
@riverpod
Stream<PlaybackState> playbackState(PlaybackStateRef ref) {
  final handler = ref.watch(audioPlayerProvider);
  return handler.playbackState;
}
