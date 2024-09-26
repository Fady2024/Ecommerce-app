import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../onboarding/splash_screen.dart';

class SplashScreen2 extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen2> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  _navigateToHome() async {
    await Future.delayed(Duration(seconds: 3), () {
      // This closure is executed after the delay
      if (!mounted) return; // Check if the widget is still mounted

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SplashScreen()), // Replace with your home page
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Scaffold(
      backgroundColor: themeNotifier.themeMode == ThemeMode.dark
          ? Colors.black
          : Colors.white,
      body: Column(
        children: [
          SizedBox(height: 50),
          Image.asset("assets/Untitled-1.png"),
          SizedBox(height: 50),
          Container(
            height: 150,
            child: Center(
              child: Lottie.asset('assets/Run Hamster... run.json'),
            ),
          ),
        ],
      ),
    );
  }
}
