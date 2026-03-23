import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// The custom AudioHandler implementation that bridges audio_service and just_audio.
class AudioPlayerHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  // The internal JustAudio player
  final _player = AudioPlayer();

  AudioPlayer get audioPlayer => _player;

  // --- NEW: Streams for FullPlayerScreen UI ---
  // These allow your StreamBuilders to listen to mode and speed changes
  Stream<LoopMode> get loopModeStream => _player.loopModeStream;
  Stream<bool> get shuffleModeEnabledStream => _player.shuffleModeEnabledStream;

  // ADDED: Speed stream for the UI to listen to playback speed changes
  Stream<double> get speedStream => _player.speedStream;

  // Constructor
  AudioPlayerHandler() {
    _player.setAudioSource(ConcatenatingAudioSource(children: [])).then((_) {
      // Listen to playback state changes from the player and publish them to audio_service
      _player.playerStateStream.map(_transformEvent).pipe(playbackState);

      // Listen to track changes and publish them to audio_service
      _player.currentIndexStream.listen((index) {
        if (index != null && queue.value.isNotEmpty) {
          mediaItem.add(queue.value[index]);
        }
      });
    });
  }

  // --- Audio Source Helper ---
  AudioSource _createAudioSource(MediaItem item) {
    return LockCachingAudioSource(Uri.parse(item.id), tag: item);
  }

  // --- Queue Management ---
  Future<void> initPlaylistAndPlay(
    List<MediaItem> mediaItems,
    int startIndex,
  ) async {
    final audioSources = mediaItems.map(_createAudioSource).toList();

    await _player.setAudioSource(
      ConcatenatingAudioSource(children: audioSources),
      initialIndex: startIndex,
      initialPosition: Duration.zero,
    );

    queue.add(mediaItems);
    play();
  }

  @override
  Future<void> initPlaylist(List<MediaItem> mediaItems) =>
      initPlaylistAndPlay(mediaItems, 0);

  // --- Playback Controls ---

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  // ADDED: Method to update playback speed
  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  // --- Shuffle & Repeat Logic ---

  /// Toggles through the loop modes (Off -> All -> One)
  Future<void> cycleRepeatMode() async {
    switch (_player.loopMode) {
      case LoopMode.off:
        await _player.setLoopMode(LoopMode.all);
        break;
      case LoopMode.all:
        await _player.setLoopMode(LoopMode.one);
        break;
      case LoopMode.one:
        await _player.setLoopMode(LoopMode.off);
        break;
    }
  }

  /// Toggles shuffle mode on or off
  Future<void> toggleShuffle() async {
    final enable = !_player.shuffleModeEnabled;
    if (enable) {
      await _player.shuffle();
    }
    await _player.setShuffleModeEnabled(enable);
  }

  // Support for audio_service standard calls
  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        await _player.setLoopMode(LoopMode.off);
        break;
      case AudioServiceRepeatMode.one:
        await _player.setLoopMode(LoopMode.one);
        break;
      case AudioServiceRepeatMode.all:
      case AudioServiceRepeatMode.group:
        await _player.setLoopMode(LoopMode.all);
        break;
    }
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    if (shuffleMode == AudioServiceShuffleMode.none) {
      await _player.setShuffleModeEnabled(false);
    } else {
      await _player.shuffle();
      await _player.setShuffleModeEnabled(true);
    }
  }

  // --- State Transformation ---

  PlaybackState _transformEvent(PlayerState playerState) {
    final processingState = const {
      ProcessingState.idle: AudioProcessingState.idle,
      ProcessingState.loading: AudioProcessingState.loading,
      ProcessingState.buffering: AudioProcessingState.buffering,
      ProcessingState.ready: AudioProcessingState.ready,
      ProcessingState.completed: AudioProcessingState.completed,
    }[playerState.processingState]!;

    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (playerState.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.setShuffleMode,
        MediaAction.setRepeatMode,
        MediaAction.setSpeed, // Added speed to system actions
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: processingState,
      playing: playerState.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _player.currentIndex,
      // Pass the current shuffle/repeat state back to AudioService
      shuffleMode: _player.shuffleModeEnabled
          ? AudioServiceShuffleMode.all
          : AudioServiceShuffleMode.none,
      repeatMode: const {
        LoopMode.off: AudioServiceRepeatMode.none,
        LoopMode.one: AudioServiceRepeatMode.one,
        LoopMode.all: AudioServiceRepeatMode.all,
      }[_player.loopMode]!,
    );
  }
}
