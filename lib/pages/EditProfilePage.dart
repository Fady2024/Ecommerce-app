import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:lottie/lottie.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import '../cubits/auth_cubit.dart';
import '../cubits/user_profile_provider.dart';
import '../enter_to_app/welcome_screen.dart';
import '../main.dart'; // Assuming ThemeNotifier is in your main.dart

class EditProfilePage extends StatefulWidget {
  final VoidCallback? onProfileUpdated;

  const EditProfilePage({Key? key, this.onProfileUpdated}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  File? _imageFile;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false; // Added for password visibility
  String? _joinDate;

  final DatabaseReference _userRef =
      FirebaseDatabase.instance.ref().child('users');

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _nameController.text = user.displayName ?? '';
        _userRef
            .child(user.email!.replaceAll('.', ','))
            .once()
            .then((snapshot) {
          if (snapshot.snapshot.exists) {
            final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
            _phoneController.text = data['phoneNumber'] ?? '';
          }
        });

        // Get user creation date
        final creationTime = user.metadata.creationTime;
        if (creationTime != null) {
          String formattedDate = _formatDate(creationTime);
          setState(() {
            _joinDate =
                formattedDate; // Just store the formatted date, not the entire string
          });
        }
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_getMonthName(date.month)} ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path); // Update the state with the new image file
      });
    }
  }


  Future<void> _updateProfile() async {
    final authCubit = context.read<AuthCubit>();
    setState(() {
      _isLoading = true;
    });

    try {
      String? photoURL;

      if (_imageFile != null) {
        photoURL = await _uploadImage(_imageFile!);
      }

      final user = FirebaseAuth.instance.currentUser;

      // Skip email verification check and proceed with updating the profile.
      if (user != null) {
        await authCubit.updateProfile(
          _nameController.text,
          photoURL,
          _passwordController.text,
        );

        // Update other profile details in Firebase Realtime Database
        await _userRef.child(user.email!.replaceAll('.', ',')).update({
          'fullName': _nameController.text,
          'phoneNumber': _phoneController.text,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );

        if (widget.onProfileUpdated != null) {
          widget.onProfileUpdated!();
        }

        Navigator.of(context).pop();

        Provider.of<UserProfileProvider>(context, listen: false)
            .updateProfile(photoURL, _nameController.text);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_images')
          .child('${FirebaseAuth.instance.currentUser?.uid}.jpg');
      await storageRef.putFile(image);
      return await storageRef.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;

    // Check if the user is authenticated
    if (user == null) return;

    try {
      // Prompt user for password confirmation
      final shouldDelete = await _confirmDeletion();
      if (!shouldDelete) return;

      // Re-authenticate the user
      await _reauthenticateUser(user);

      // Delete user account from Firebase Auth
      await user.delete();

      // Delete user's data from Firebase Realtime Database
      await _userRef.child(user.email!.replaceAll('.', ',')).remove();

      // Delete user's image from Firebase Storage
      await _deleteUserImage(user.uid);

      // Redirect to WelcomeScreen after deletion
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => WelcomeScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting account: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _reauthenticateUser(User user) async {
    final email = user.email;
    final password = await _showReauthenticationDialog();

    if (password == null || password.isEmpty) {
      throw Exception('Password cannot be empty');
    }

    // Re-authenticate with the user's credentials
    final credential =
        EmailAuthProvider.credential(email: email!, password: password);
    await user.reauthenticateWithCredential(credential);
  }

  Future<String?> _showReauthenticationDialog() async {
    return await showDialog<String>(
      context: context,
      builder: (context) {
        final passwordController = TextEditingController();
        return AlertDialog(
          title: const Text('Re-authenticate'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(passwordController.text),
              child: const Text('Confirm'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteUserImage(String userId) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_images')
          .child('$userId.jpg');
      await storageRef.delete();
    } catch (e) {
      print('Error deleting image: $e');
    }
  }

  Future<bool> _confirmDeletion() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Confirm Deletion'),
              content: const Text(
                  'Are you sure you want to delete your account? This action cannot be undone.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDarkMode = themeNotifier.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.wb_sunny : Icons.nights_stay),
            onPressed: () {
              themeNotifier.toggleTheme();
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            UpdatedImage(),
            const SizedBox(height: 20.0),
            _buildTextField(
              controller: _nameController,
              labelText: 'Full Name',
              icon: Icons.person,
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 16.0),
            _buildTextField(
              controller: _phoneController,
              labelText: 'Phone Number',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 16.0),
            _buildTextField(
              controller: _passwordController,
              labelText: 'New Password',
              icon: Icons.lock,
              obscureText: !_isPasswordVisible,
              isDarkMode: isDarkMode,
              togglePasswordVisibility: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
              onPressed: _updateProfile,
              child: const Text(
                'Update Profile',
                style: TextStyle(color: Colors.black),
              ),
            ),
            const SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_joinDate != null)
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Joined ',
                          style: TextStyle(
                            color: isDarkMode
                                ? Colors.white
                                : Colors.black, // Use your desired color
                          ),
                        ),
                        TextSpan(
                          text:
                              _joinDate, // This will contain the formatted date
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode
                                ? Colors.white
                                : Colors.black, // Use your desired color
                          ),
                        ),
                      ],
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(17)),
                  child: TextButton(
                    onPressed: _deleteAccount,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
            if (_isLoading)
              Center(
                child: Lottie.asset(
                  'lib/data/Animation - 1725477463954.json',
                  width: double.infinity,
                  height: 100,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    required bool isDarkMode,
    VoidCallback? togglePasswordVisibility,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey),
        labelText: labelText,
        labelStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.grey),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.grey),
          borderRadius: BorderRadius.circular(20.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.yellow),
          borderRadius: BorderRadius.circular(20.0),
        ),
        filled: true,
        fillColor: isDarkMode ? Colors.black.withOpacity(0.1) : Colors.white,
        suffixIcon: togglePasswordVisibility != null
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: togglePasswordVisibility,
              )
            : null,
      ),
      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
    );
  }

  Widget UpdatedImage() {
    return FutureBuilder<String?>(
      future: _getProfileImageUrl(),
      builder: (context, snapshot) {
        return GestureDetector(
          onTap: _pickImage,
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50.0,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!) // Use the picked image
                        : snapshot.connectionState == ConnectionState.waiting
                        ? null
                        : (snapshot.hasData && snapshot.data != null
                        ? CachedNetworkImageProvider(snapshot.data!)
                        : null),
                    child: snapshot.connectionState == ConnectionState.waiting
                        ? const CircularProgressIndicator()
                        : (snapshot.hasData && snapshot.data != null
                        ? null
                        : const Icon(Icons.camera_alt, size: 50.0, color: Colors.grey)),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.yellow,
                        shape: BoxShape.circle,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(Icons.camera_alt, color: Colors.black, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              if (snapshot.connectionState == ConnectionState.waiting)
                const CircularProgressIndicator()
              else if (!snapshot.hasData || snapshot.data == null)
                const Text(
                  'No image available',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        );
      },
    );
  }
  Future<String?> _getProfileImageUrl() async {
    final user = _auth.currentUser;
    if (user != null) {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_images')
          .child('${user.uid}.jpg');
      try {
        return await storageRef.getDownloadURL();
      } catch (e) {
        print('Error getting image URL: $e');
        return null;
      }
    }
    return null;
  }
}
