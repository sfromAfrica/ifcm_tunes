import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'screens/home_screen.dart'; // The main UI screen
import 'services/audio_player_handler.dart';
import 'providers/audio_player_provider.dart';
import 'providers/theme_provider.dart';

Future<void> main() async {
  // 1. Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // --- 2. Initialize Firebase ---
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // --- 3. Initialize the Audio Service ---
  final audioHandler = await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.ifcmtunes.channel.audio',
      androidNotificationChannelName: 'IFCM Tunes Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  // 4. Start the Application wrapped in Riverpod's ProviderScope
  runApp(
    ProviderScope(
      overrides: [externalAudioHandlerProvider.overrideWithValue(audioHandler)],
      child: const IFCMTunesApp(),
    ),
  );
}

class IFCMTunesApp extends ConsumerWidget {
  const IFCMTunesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read the current theme mode from the Riverpod state
    final themeMode = ref.watch(themeModeNotifierProvider);

    return MaterialApp(
      title: 'IFCM Tunes',

      // Apply the theme mode watched from the provider
      themeMode: themeMode,

      // Define the Light Theme
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),

      // Define the Dark Theme (Spotify-like)
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          brightness: Brightness.dark,
          surface: Colors.black12,
          surfaceVariant: Colors.grey.shade900,
        ),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
        scaffoldBackgroundColor: Colors.black,
      ),

      // Set the home screen to our new song catalog UI
      home: const HomeScreen(),
    );
  }
}
