import 'package:flutter/material.dart';
import 'package:loginpage/enter_to_app/welcome_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/ecommerce_page.dart';
import 'onboarding_page_view.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  void _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

    if (isFirstLaunch) {
      await prefs.setBool('isFirstLaunch', false);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => OnboardingPageView()),
      );
    } else {
      _checkUserLoginStatus();
    }
  }

  void _checkUserLoginStatus() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => Ecommerce()), // Redirect to Ecommerce if logged in
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => WelcomeScreen()), // Redirect to WelcomeScreen if not logged in
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
