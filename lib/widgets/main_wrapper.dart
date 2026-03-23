// lib/widgets/main_wrapper.dart

import 'package:flutter/material.dart';
import '../screens/home_screen.dart'; // To access the MiniPlayer

class MainWrapper extends StatelessWidget {
  final Widget child;

  const MainWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The 'child' is the screen being navigated to (HomeScreen, AlbumScreen, etc.)
      body: Stack(
        children: [
          child,
          const Positioned(left: 0, right: 0, bottom: 0, child: MiniPlayer()),
        ],
      ),
    );
  }
}
