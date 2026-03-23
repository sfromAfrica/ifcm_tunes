// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$songListHash() => r'e5185771c06326acd61f52ddffa0f447db391688';

/// StreamProvider that listens to the Firestore repository and exposes a list of all Songs.
///
/// Copied from [songList].
@ProviderFor(songList)
final songListProvider = AutoDisposeStreamProvider<List<Song>>.internal(
  songList,
  name: r'songListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$songListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SongListRef = AutoDisposeStreamProviderRef<List<Song>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
