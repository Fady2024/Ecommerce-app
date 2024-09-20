import 'package:flutter/material.dart';
import 'package:loginpage/enter_to_app/login_page.dart';
import 'package:loginpage/enter_to_app/signup_page.dart';
import 'package:loginpage/pages/ecommerce_page.dart';
import 'package:provider/provider.dart';
import '../main.dart';

class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return Scaffold(
      appBar: AppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Container(
              decoration: BoxDecoration(
                  border: Border.all(
                    color: themeNotifier.themeMode == ThemeMode.light
                        ? Colors.black
                        : Colors.white,
                  ),
                  borderRadius: BorderRadius.circular(15)),
              child: IconButton(
                icon: Icon(
                  themeNotifier.themeMode == ThemeMode.light
                      ? Icons.nightlight_round
                      : Icons.wb_sunny,
                ),
                onPressed: () {
                  themeNotifier.toggleTheme();
                },
              ),
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
                const Text(
                  'Welcome to AFK Market!',
                  style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10.0),
                const Text(
                  'Everything you need, all in one place.',
                  style: TextStyle(fontSize: 16.0),
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
                  child:
                      const Text('Log In', style: TextStyle(color: Colors.red)),
                ),
                const SizedBox(height: 10.0),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => SignUpPage()),
                    );
                  },
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(color: Colors.blue, fontSize: 18),
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
                  child: const Text(
                    'GUEST LOGIN',
                    style: TextStyle(color: Color(0xFF1B681D), fontSize: 18),
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
