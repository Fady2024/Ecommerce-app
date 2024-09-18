import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';

class ThemeControllerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Theme Controller'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            themeNotifier.toggleTheme();
          },
          child: Text(themeNotifier.themeMode == ThemeMode.light
              ? 'Switch to Dark Mode'
              : 'Switch to Light Mode'),
        ),
      ),
    );
  }
}
