import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';

class GlowingText extends StatelessWidget {
  final String text;
  final double intensity;

  GlowingText({
    required this.text,
    this.intensity = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Center(
      child: ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: themeNotifier.themeMode == ThemeMode.light
              ? [Colors.red, Colors.black]
              : [Colors.red, Colors.grey],
          stops: themeNotifier.themeMode == ThemeMode.light
          ?[0.5 - intensity / 2, 0.5 + intensity / 2]:[0.7 - intensity / 2, 0.5 + intensity / 2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
        child: Text(
          text,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24, // Adjust the font size as needed
          ),
        ),
      ),
    );
  }
}
