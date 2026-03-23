// lib/providers/palette_provider.dart
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:palette_generator/palette_generator.dart';

import 'audio_player_provider.dart';

part 'palette_provider.g.dart'; // <-- THIS LINE IS CORRECT

@riverpod
Future<PaletteGenerator> paletteGenerator(PaletteGeneratorRef ref) async {
  final mediaItem = ref.watch(audioPlayerProvider).mediaItem.value;
  final artUri = mediaItem?.artUri;

  // Use a default color source if art is missing
  if (artUri == null) {
    return PaletteGenerator.fromColors([PaletteColor(Colors.black, 1)]);
  }

  final ImageProvider imageProvider = NetworkImage(artUri.toString());

  // Use a unique cache key to ensure the palette updates when the song changes
  ref.keepAlive();

  return PaletteGenerator.fromImageProvider(
    imageProvider,
    size: const Size(200, 200),
    maximumColorCount: 10,
  );
}
