import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:email_validator/email_validator.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import '../main.dart';
import '../pages/day_night_switch.dart';
import 'login_page.dart';
import 'welcome_screen.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _picker = ImagePicker();
  final _googleSignIn = GoogleSignIn();
  final selectedLanguage =
      AppState().selectedLanguage; // Get the current language
  File? _imageFile;
  bool _isPasswordValid = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasDigits = false;
  bool _hasSpecialChar = false;
  bool _isLoading = false;
  bool _obscureText = true;
  bool _isDarkMode = false; // Initialize based on your app's logic or provider
  PhoneNumber _phoneNumber = PhoneNumber(isoCode: 'EG');

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  void _showSnackBar(String title, String message, Icon icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            icon,
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: title == 'Warning' ? Colors.pink : Colors.green,
      ),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_images')
          .child('${_auth.currentUser?.uid}.jpg');

      await storageRef.putFile(image);
      final downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print( selectedLanguage == 'Français' ?'Erreur lors du téléchargement de l\'image: $e':'Error uploading image: $e');
      return null;
    }
  }

  bool _isPasswordStrong(String password) {
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigits = password.contains(RegExp(r'[0-9]'));
    final hasSpecialCharacters =
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    final isLongEnough = password.length >= 8;

    setState(() {
      _hasUppercase = hasUppercase;
      _hasLowercase = hasLowercase;
      _hasDigits = hasDigits;
      _hasSpecialChar = hasSpecialCharacters;
      _isPasswordValid = isLongEnough && hasDigits && hasSpecialCharacters;
    });

    return _isPasswordValid;
  }

  Future<void> _signUp() async {
    setState(() => _isLoading = true);

    if (_fullNameController.text.isEmpty) {
      _showSnackBar(
        'Warning',
        selectedLanguage == 'Français' ? 'Nom complet ne peut pas être vide' : 'Full name cannot be empty',
        Icon(Icons.error, color: Colors.pink),
      );
      setState(() => _isLoading = false);
      return;
    }
    if (_emailController.text.isEmpty) {
      _showSnackBar(
        'Warning',
        selectedLanguage == 'Français' ? 'L\'email ne peut pas être vide' : 'Email cannot be empty',
        Icon(Icons.error, color: Colors.pink),
      );
      setState(() => _isLoading = false);
      return;
    }
    if (_passwordController.text.isEmpty) {
      _showSnackBar(
        'Warning',
        selectedLanguage == 'Français' ? 'Le mot de passe ne peut pas être vide' : 'Password cannot be empty',
        Icon(Icons.error, color: Colors.pink),
      );
      setState(() => _isLoading = false);
      return;
    }
    if (!EmailValidator.validate(_emailController.text)) {
      _showSnackBar(
        'Warning',
        selectedLanguage == 'Français' ? 'Entrez une adresse e-mail valide' : 'Enter a valid email address',
        Icon(Icons.error, color: Colors.pink),
      );
      setState(() => _isLoading = false);
      return;
    }
    if (!_isPasswordStrong(_passwordController.text)) {
      _showSnackBar(
        'Warning',
        selectedLanguage == 'Français' ? 'Le mot de passe ne répond pas aux exigences' : 'Password does not meet the requirements',
        Icon(Icons.error, color: Colors.pink),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (_imageFile != null) {
        String? imageUrl = await _uploadImage(_imageFile!);
        if (imageUrl != null) {
          await userCredential.user?.updatePhotoURL(imageUrl);
        }
      }

      await userCredential.user?.updateProfile(
        displayName: _fullNameController.text,
      );

      await FirebaseDatabase.instance
          .reference()
          .child('users')
          .child('accountUsers') // Updated path to account users
          .child(userCredential.user!.email!.replaceAll('.', ','))
          .set({
        'fullName': userCredential.user?.displayName ?? 'User',
        'phoneNumber': _phoneNumber.phoneNumber?.replaceFirst(
            RegExp(r'^\+\d{0,1}'), ''), // Remove the country code
        'joinTime': ServerValue.timestamp, // Add this line to store server time
      });

      _showSnackBar(
        'Sign up',
        selectedLanguage == 'Français' ? 'Compte créé avec succès' : 'Account is successfully created',
        Icon(Icons.done, color: Colors.white),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => SignInScreen()),
      );
    } catch (e) {
      if (e is FirebaseAuthException) {
        if (e.code == 'email-already-in-use') {
          _showSnackBar(
            'Warning',
            selectedLanguage == 'Français' ? 'Ce compte existe déjà' : 'This account already exists',
            Icon(Icons.error, color: Colors.white),
          );
        } else if (e.code == 'weak-password') {
          _showSnackBar(
            'Warning',
            selectedLanguage == 'Français' ? 'Le mot de passe doit avoir plus de 5 caractères' : 'Password length should be greater than 5',
            Icon(Icons.error, color: Colors.white),
          );
        } else {
          _showSnackBar(
            'Warning',
            selectedLanguage == 'Français' ? 'Échec de l\'inscription: ${e.message}' : 'Failed to sign up: ${e.message}',
            Icon(Icons.error, color: Colors.white),
          );
        }
      } else {
        _showSnackBar(
          'Warning',
          selectedLanguage == 'Français' ? 'Échec de l\'inscription: $e' : 'Failed to sign up: $e',
          Icon(Icons.error, color: Colors.white),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signUpWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      if (_imageFile != null) {
        String? imageUrl = await _uploadImage(_imageFile!);
        if (imageUrl != null) {
          await userCredential.user?.updatePhotoURL(imageUrl);
        }
      }

      await userCredential.user?.updateProfile(
        displayName: userCredential.user?.displayName ?? 'User',
      );

      // Save user information to Firebase Realtime Database with email as key
      await FirebaseDatabase.instance
          .reference()
          .child('users')
          .child('accountUsers') // Updated path to account users
          .child(userCredential.user!.email!.replaceAll('.', ','))
          .set({
        'fullName': userCredential.user?.displayName ?? 'User',
        'phoneNumber': _phoneNumber.phoneNumber?.replaceFirst(
            RegExp(r'^\+\d{0,1}'), ''), // Remove the country code
        'joinTime': ServerValue.timestamp, // Add this line to store server time
      });

      _showSnackBar(
        'Sign up',
        selectedLanguage == 'Français' ? 'Connexion réussie avec Google' : 'Successfully signed in with Google',
        Icon(Icons.done, color: Colors.white),
      );

      Navigator.pushReplacementNamed(context, '/profile');
    } catch (e) {
      _showSnackBar(
        'Warning',
        selectedLanguage == 'Français' ? 'Échec de l\'inscription avec Google: $e' : 'Failed to sign up with Google: $e',
        Icon(Icons.error, color: Colors.pink),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleTheme(bool value) {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    setState(() {
      _isDarkMode = value;
      themeNotifier
          .toggleTheme(); // Assuming this method switches the theme in your provider
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(selectedLanguage == 'Français' ? 'Inscription' : 'Sign Up'),
        leading: BackButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => WelcomeScreen()),
            );
          },
        ),
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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage:
                          _imageFile != null ? FileImage(_imageFile!) : null,
                      child: _imageFile == null
                          ? Icon(Icons.camera_alt, size: 40)
                          : null,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    selectedLanguage == 'Français'
                        ? "Télécharger votre photo"
                        : "Upload your Photo",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: selectedLanguage == 'Français'
                        ? 'Nom complet'
                        : 'Full Name',
                  ),
                ),
                SizedBox(height: 16),
                InternationalPhoneNumberInput(
                  onInputChanged: (PhoneNumber number) {
                    setState(() {
                      _phoneNumber = number;
                    });
                  },
                  initialValue: _phoneNumber,
                  textFieldController: _phoneNumberController,
                  inputBorder: OutlineInputBorder(),
                  selectorConfig: SelectorConfig(
                    selectorType: PhoneInputSelectorType.DIALOG,
                    showFlags: true,
                  ),
                  ignoreBlank: false,
                  autoValidateMode: AutovalidateMode.disabled,
                  selectorTextStyle: TextStyle(
                    color: themeNotifier.themeMode == ThemeMode.light
                        ? Colors.black
                        : Colors.white,
                  ),
                  textStyle: TextStyle(
                    color: themeNotifier.themeMode == ThemeMode.light
                        ? Colors.black
                        : Colors.white,
                  ),
                  formatInput: false,
                  keyboardType: TextInputType.numberWithOptions(
                      signed: true, decimal: true),
                  onSaved: (PhoneNumber number) {
                    print('On Saved: $number');
                  },
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText:
                        selectedLanguage == 'Français' ? 'Email' : 'Email',
                  ),
                ),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: selectedLanguage == 'Français'
                        ? 'Mot de passe'
                        : 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: _togglePasswordVisibility,
                    ),
                  ),
                  obscureText: _obscureText,
                  onChanged: (value) => _isPasswordStrong(value),
                ),
                SizedBox(height: 16),
                if (_passwordController.text.isNotEmpty) ...[
                  Text(
                    selectedLanguage == 'Français'
                        ? 'Force du mot de passe:'
                        : 'Password Strength:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Icon(
                        _hasDigits ? Icons.check : Icons.close,
                        color: _hasDigits ? Colors.green : Colors.red,
                      ),
                      SizedBox(width: 8),
                      Text(selectedLanguage == 'Français'
                          ? 'Contient des chiffres'
                          : 'Contains digits'),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        _hasSpecialChar ? Icons.check : Icons.close,
                        color: _hasSpecialChar ? Colors.green : Colors.red,
                      ),
                      SizedBox(width: 8),
                      Text(selectedLanguage == 'Français'
                          ? 'Contient des caractères spéciaux'
                          : 'Contains special characters'),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        _hasUppercase ? Icons.check : Icons.warning_rounded,
                        color:
                            _hasUppercase ? Colors.green : Colors.yellow[700],
                      ),
                      SizedBox(width: 8),
                      Text(selectedLanguage == 'Français'
                          ? 'Contient des majuscules'
                          : 'Contains uppercase letter'),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        _hasLowercase ? Icons.check : Icons.warning_rounded,
                        color:
                            _hasLowercase ? Colors.green : Colors.yellow[700],
                      ),
                      SizedBox(width: 8),
                      Text(selectedLanguage == 'Français'
                          ? 'Contient des minuscules'
                          : 'Contains lowercase letter'),
                    ],
                  ),
                ],
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _signUp,
                  child: Text(selectedLanguage == 'Français'
                      ? 'S\'inscrire'
                      : 'Sign Up'),
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _signUpWithGoogle,
                  icon: Icon(Icons.login, color: Colors.white),
                  label: Text(
                    selectedLanguage == 'Français'
                        ? 'S\'inscrire avec Google'
                        : 'Sign Up with Google',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, // Google color
                  ),
                ),
                SizedBox(height: 15),
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
                SizedBox(height: 15),
                Align(
                  alignment: Alignment.center,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => SignInScreen()),
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: selectedLanguage == 'Français'
                                ? 'Vous avez déjà un compte? '
                                : 'Already have an account? ',
                            style: TextStyle(
                              color: themeNotifier.themeMode == ThemeMode.light
                                  ? Colors.black
                                  : Colors.white,
                            ),
                          ),
                          TextSpan(
                            text: selectedLanguage == 'Français'
                                ? 'Connexion'
                                : 'Login',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
