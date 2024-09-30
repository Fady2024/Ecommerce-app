import 'package:flutter/material.dart';
import 'package:loginpage/enter_to_app/login_page.dart';
import 'package:loginpage/enter_to_app/signup_page.dart';
import 'package:loginpage/pages/ecommerce_page.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../pages/day_night_switch.dart';

class WelcomeScreen extends StatefulWidget {
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final selectedLanguage = AppState().selectedLanguage; // Get the current language

  // Toggle theme mode
  void _toggleTheme(bool value) {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    themeNotifier.toggleTheme(); // Toggle theme in your provider
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    // Update _isDarkMode based on the current theme
    bool _isDarkMode = themeNotifier.themeMode == ThemeMode.light
        ?false:true;
    return Scaffold(
      appBar: AppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DayNightSwitch(
              value: _isDarkMode,
              onChanged: _toggleTheme,
              moonImage: AssetImage('assets/moon.png'),
              sunImage: AssetImage('assets/sun.png'),
              sunColor: Colors.yellow,
              moonColor: Colors.white,
              dayColor: Colors.blue,
              nightColor: Color(0xFF393939),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 150.0,
                  backgroundColor: Colors.transparent,
                  child: Image.asset("assets/Untitled-1.png"),
                ),
                const SizedBox(height: 20.0),
                Text(
                  selectedLanguage == 'Français' ? 'Bienvenue sur AFK Market!' : 'Welcome to AFK Market!',
                  style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10.0),
                Text(
                  selectedLanguage == 'Français' ? 'Tout ce dont vous avez besoin, au même endroit.' : 'Everything you need, all in one place.',
                  style: const TextStyle(fontSize: 16.0),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30.0),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => SignInScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: Text(
                    selectedLanguage == 'Français' ? 'Se connecter' : 'Log In',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                const SizedBox(height: 10.0),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => SignUpPage()),
                    );
                  },
                  child: Text(
                    selectedLanguage == 'Français' ? 'S\'inscrire' : 'Sign Up',
                    style: const TextStyle(color: Colors.blue, fontSize: 18),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                const SizedBox(height: 10.0),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => Ecommerce()),
                    );
                  },
                  child: Text(
                    selectedLanguage == 'Français' ? 'CONTINUER EN TANT QU\'INVITÉ' : 'CONTINUE AS GUEST',
                    style: const TextStyle(color: Color(0xFF1B681D), fontSize: 18),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF1B681D)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
