// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_player_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$audioPlayerHash() => r'3c3f548bf8536281743fb349e9fe22346b7f59c8';

/// The main Player State Provider.
/// This provider gives us easy access to the necessary streams and methods.
///
/// Copied from [audioPlayer].
@ProviderFor(audioPlayer)
final audioPlayerProvider = AutoDisposeProvider<AudioPlayerHandler>.internal(
  audioPlayer,
  name: r'audioPlayerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$audioPlayerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AudioPlayerRef = AutoDisposeProviderRef<AudioPlayerHandler>;
String _$currentMediaItemHash() => r'b3951079b0e17bb54c9bd30fa9bb598a72d9b54e';

/// Exposes the current MediaItem (the currently playing song's metadata).
///
/// Copied from [currentMediaItem].
@ProviderFor(currentMediaItem)
final currentMediaItemProvider = AutoDisposeStreamProvider<MediaItem?>.internal(
  currentMediaItem,
  name: r'currentMediaItemProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentMediaItemHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentMediaItemRef = AutoDisposeStreamProviderRef<MediaItem?>;
String _$playbackStateHash() => r'973f3ad02530e065f458ad2d53ee7c2396d60070';

/// Exposes the current PlaybackState (playing/paused, buffering, position).
///
/// Copied from [playbackState].
@ProviderFor(playbackState)
final playbackStateProvider = AutoDisposeStreamProvider<PlaybackState>.internal(
  playbackState,
  name: r'playbackStateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$playbackStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PlaybackStateRef = AutoDisposeStreamProviderRef<PlaybackState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
