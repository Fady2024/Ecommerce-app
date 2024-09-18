import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:email_validator/email_validator.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import 'login_page.dart';
import 'welcome_screen.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _picker = ImagePicker();
  final _googleSignIn = GoogleSignIn();
  File? _imageFile;
  bool _isPasswordValid = false;
  bool _isPasswordLongEnough = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasDigits = false;
  bool _hasSpecialChar = false;
  bool _isLoading = false;

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
      print('Error uploading image: $e');
      return null;
    }
  }

  bool _isPasswordStrong(String password) {
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigits = password.contains(RegExp(r'[0-9]'));
    final hasSpecialCharacters = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    final isLongEnough = password.length >= 8;

    setState(() {
      _isPasswordLongEnough = isLongEnough;
      _hasUppercase = hasUppercase;
      _hasLowercase = hasLowercase;
      _hasDigits = hasDigits;
      _hasSpecialChar = hasSpecialCharacters;
      _isPasswordValid = isLongEnough && hasUppercase && hasLowercase && hasDigits && hasSpecialCharacters;
    });

    return _isPasswordValid;
  }

  Future<void> _signUp() async {
    setState(() => _isLoading = true);

    if (_usernameController.text.isEmpty) {
      _showSnackBar(
        'Warning',
        'Username cannot be empty',
        Icon(Icons.error, color: Colors.pink),
      );
      setState(() => _isLoading = false);
      return;
    }
    if (_emailController.text.isEmpty) {
      _showSnackBar(
        'Warning',
        'Email cannot be empty',
        Icon(Icons.error, color: Colors.pink),
      );
      setState(() => _isLoading = false);
      return;
    }
    if (_passwordController.text.isEmpty) {
      _showSnackBar(
        'Warning',
        'Password cannot be empty',
        Icon(Icons.error, color: Colors.pink),
      );
      setState(() => _isLoading = false);
      return;
    }
    if (!EmailValidator.validate(_emailController.text)) {
      _showSnackBar(
        'Warning',
        'Enter a valid email address',
        Icon(Icons.error, color: Colors.pink),
      );
      setState(() => _isLoading = false);
      return;
    }
    if (!_isPasswordStrong(_passwordController.text)) {
      _showSnackBar(
        'Warning',
        'Password does not meet the requirements',
        Icon(Icons.error, color: Colors.pink),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
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
        displayName: _usernameController.text,
      );

      _showSnackBar(
        'Sign up',
        'Account is successfully created',
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
            'This account already exists',
            Icon(Icons.error, color: Colors.white),
          );
        } else if (e.code == 'weak-password') {
          _showSnackBar(
            'Warning',
            'Password length should be greater than 5',
            Icon(Icons.error, color: Colors.white),
          );
        } else {
          _showSnackBar(
            'Warning',
            'Failed to sign up: ${e.message}',
            Icon(Icons.error, color: Colors.white),
          );
        }
      } else {
        _showSnackBar(
          'Warning',
          'Failed to sign up: $e',
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

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);

      if (_imageFile != null) {
        String? imageUrl = await _uploadImage(_imageFile!);
        if (imageUrl != null) {
          await userCredential.user?.updatePhotoURL(imageUrl);
        }
      }

      await userCredential.user?.updateProfile(
        displayName: userCredential.user?.displayName ?? 'User',
      );

      _showSnackBar(
        'Sign up',
        'Successfully signed in with Google',
        Icon(Icons.done, color: Colors.white),
      );

      Navigator.pushReplacementNamed(context, '/profile');
    } catch (e) {
      _showSnackBar(
        'Warning',
        'Failed to sign up with Google: $e',
        Icon(Icons.error, color: Colors.pink),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
        leading: BackButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => WelcomeScreen()),
            );
          },
        ),
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
                    "Upload your Photo",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(labelText: 'Username'),
                ),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  onChanged: (value) => _isPasswordStrong(value),
                ),
                SizedBox(height: 16),
                if (_passwordController.text.isNotEmpty) ...[
                  Text(
                    'Password Strength:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Icon(
                        _hasUppercase ? Icons.check : Icons.close,
                        color: _hasUppercase ? Colors.green : Colors.red,
                      ),
                      SizedBox(width: 8),
                      Text('Contains uppercase letter'),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        _hasLowercase ? Icons.check : Icons.close,
                        color: _hasLowercase ? Colors.green : Colors.red,
                      ),
                      SizedBox(width: 8),
                      Text('Contains lowercase letter'),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        _hasDigits ? Icons.check : Icons.close,
                        color: _hasDigits ? Colors.green : Colors.red,
                      ),
                      SizedBox(width: 8),
                      Text('Contains digits'),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        _hasSpecialChar ? Icons.check : Icons.close,
                        color: _hasSpecialChar ? Colors.green : Colors.red,
                      ),
                      SizedBox(width: 8),
                      Text('Contains special characters'),
                    ],
                  ),
                ],
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _signUp,
                  child: Text('Sign Up'),
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _signUpWithGoogle,
                  icon: Icon(Icons.login, color: Colors.white),
                  label: Text(
                    'Sign Up with Google',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, // Google color
                  ),
                ),
                SizedBox(height: 30),
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
                            text: 'Already have an account? ',
                            style: TextStyle(color: themeNotifier.themeMode == ThemeMode.light
                                ? Colors.black
                                : Colors.white,),
                          ),
                          const TextSpan(
                            text: 'Login',
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
                      child: Lottie.asset('lib/data/Animation - 1725477463954.json',
                        width:double.infinity,
                        height: 100,
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
