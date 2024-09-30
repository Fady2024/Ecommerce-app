import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../pages/day_night_switch.dart';
import '../pages/ecommerce_page.dart';
import 'signup_page.dart';
import 'welcome_screen.dart';
import '../main.dart';

class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final selectedLanguage =
      AppState().selectedLanguage; // Get the current language
  bool _isLoading = false;
  bool _obscurePassword = true; // New variable for password visibility

  void _showSnackBar(String title, String message, Icon icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            icon,
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: title == 'Error' ? Colors.pink : Colors.green,
      ),
    );
  }

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      _showSnackBar(
        selectedLanguage == 'Français' ? 'Connexion' : 'Login',
        selectedLanguage == 'Français'
            ? 'Connecté avec succès. Bienvenue à nouveau !'
            : 'Successfully logged in. Welcome back!',
        const Icon(Icons.done, color: Colors.white),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const Ecommerce()),
      );
    } catch (e) {
      _showSnackBar(
        selectedLanguage == 'Français' ? 'Erreur' : 'Error',
        selectedLanguage == 'Français'
            ? 'Vérifiez vos informations et réessayez.'
            : 'Check your details and try again.',
        const Icon(Icons.error_outline, color: Colors.white),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await _auth.signInWithCredential(credential);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const Ecommerce()),
        );
      }
    } catch (e) {
      _showSnackBar(
        selectedLanguage == 'Français' ? 'Erreur' : 'Error',
        selectedLanguage == 'Français'
            ? 'Échec de la connexion avec Google : $e'
            : 'Failed to sign in with Google: $e',
        const Icon(Icons.error, color: Colors.pink),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Toggle theme mode
  void _toggleTheme(bool value) {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    themeNotifier.toggleTheme(); // Toggle theme in your provider
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    // Update _isDarkMode based on the current theme
    bool _isDarkMode = themeNotifier.themeMode == ThemeMode.light ?false:true;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => WelcomeScreen()),
            );
          },
        ),
        title: Text(selectedLanguage == 'Français' ? 'Connexion' : 'Sign In'),
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
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: selectedLanguage == 'Français'
                          ? 'Adresse e-mail'
                          : 'Email Address',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: selectedLanguage == 'Français'
                          ? 'Mot de passe'
                          : 'Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword =
                                !_obscurePassword; // Toggle password visibility
                          });
                        },
                      ),
                    ),
                    obscureText: _obscurePassword, // Use the boolean variable
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () async {
                        if (_emailController.text.isNotEmpty) {
                          try {
                            await _auth.sendPasswordResetEmail(
                                email: _emailController.text);
                            _showSnackBar(
                              selectedLanguage == 'Français'
                                  ? 'Succès'
                                  : 'Success',
                              selectedLanguage == 'Français'
                                  ? 'E-mail de réinitialisation de mot de passe envoyé ! Vérifiez votre boîte de réception.'
                                  : 'Password reset email sent! Check your inbox.',
                              const Icon(Icons.email_outlined,
                                  color: Colors.white),
                            );
                          } catch (e) {
                            _showSnackBar(
                              selectedLanguage == 'Français'
                                  ? 'Erreur'
                                  : 'Error',
                              selectedLanguage == 'Français'
                                  ? 'Échec de l\'envoi de l\'e-mail de réinitialisation du mot de passe. Veuillez réessayer.'
                                  : 'Failed to send password reset email. Please try again.',
                              const Icon(Icons.error_outline,
                                  color: Colors.white),
                            );
                          }
                        } else {
                          _showSnackBar(
                            selectedLanguage == 'Français' ? 'Erreur' : 'Error',
                            selectedLanguage == 'Français'
                                ? 'Veuillez entrer votre adresse e-mail.'
                                : 'Please enter your email address.',
                            const Icon(Icons.error_outline,
                                color: Colors.white),
                          );
                        }
                      },
                      child: Text(
                        selectedLanguage == 'Français'
                            ? 'Mot de passe oublié ?'
                            : 'Forgot password?',
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  ElevatedButton(
                    onPressed: _signIn,
                    child: Text(selectedLanguage == 'Français'
                        ? 'Connexion'
                        : 'Log In'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  ElevatedButton.icon(
                    onPressed: _signInWithGoogle,
                    icon: const Icon(Icons.g_mobiledata, color: Colors.white),
                    label: Text(
                        selectedLanguage == 'Français'
                            ? 'Se connecter avec Google'
                            : 'Sign in with Google',
                        style: const TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                  Align(
                    alignment: Alignment.center,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => SignUpPage()),
                        );
                      },
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: selectedLanguage == 'Français'
                                  ? 'Vous n\'avez pas de compte ? '
                                  : 'Don\'t have an account? ',
                              style: TextStyle(
                                color:
                                    themeNotifier.themeMode == ThemeMode.light
                                        ? Colors.black
                                        : Colors.white,
                              ),
                            ),
                             TextSpan(
                              text: selectedLanguage == 'Français'
                                  ? 'S\'inscrire':"Sign Up",
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_isLoading)
                    Container(
                      child: Center(
                        child: Lottie.asset(
                          'lib/data/Animation - 1725477463954.json',
                          width: double.infinity,
                          height: 100,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
