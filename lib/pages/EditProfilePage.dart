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
import '../main.dart';
import 'day_night_switch.dart'; // Assuming ThemeNotifier is in your main.dart

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
  final selectedLanguage = AppState().selectedLanguage; // Get the current language

  bool _isLoading = false;
  bool _isDarkMode = false; // Initialize based on your app's logic or provider
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
        // For authenticated users, use their email as the key
        _nameController.text = user.displayName ?? '';
        _userRef
            .child('accountUsers')
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
    const monthsEn = [
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

    const monthsFr = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre'
    ];

    return selectedLanguage == 'Français' ? monthsFr[month - 1] : monthsEn[month - 1];
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
        await _userRef.child('accountUsers').child(user.email!.replaceAll('.', ',')).update({
          'fullName': _nameController.text,
          'phoneNumber': _phoneController.text,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(selectedLanguage == 'Français' ?'Profil mis à jour avec succès':'Profile updated successfully')),
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
        SnackBar(content: Text(selectedLanguage == 'Français' ?'Erreur lors de la mise à jour du profil : $e':'Error updating profile: $e')),
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
      // Re-authenticate the user
      await _reauthenticateUser(user);

      // Delete user account from Firebase Auth
      await user.delete();

      // Sanitize email to use as Firebase key
      final sanitizedEmail = user.email!.replaceAll('.', ',');

      // Delete user's data from Firebase Realtime Database
      await FirebaseDatabase.instance.ref().child('accountUsers').child(sanitizedEmail).remove(); // Delete user profile and all associated data

      // Delete user's image from Firebase Storage
      await _deleteUserImage(user.uid);
      // Redirect to WelcomeScreen after deletion
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => WelcomeScreen()),
            (Route<dynamic> route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(selectedLanguage == 'Français' ?'Erreur lors de la suppression du compte : $e':'Error deleting account: $e')),
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
      throw Exception(selectedLanguage == 'Français' ?'Le mot de passe ne peut pas être vide':'Password cannot be empty');
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
          title: Text(selectedLanguage == 'Français' ?'Confirmer la suppression':'Confirm Deletion'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: selectedLanguage == 'Français' ?'Veuillez entrer votre mot de passe':'Please Enter Your Password'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(passwordController.text),
              child: Text(selectedLanguage == 'Français' ?'Confirmer':'Confirm'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text(selectedLanguage == 'Français' ?'Annuler':'Cancel'),
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
      print(selectedLanguage == 'Français' ?'Erreur lors de la suppression de l\'image : $e':'Error deleting image: $e');
    }
  }

  // Toggle theme mode
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
    final isDarkMode = themeNotifier.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text(selectedLanguage == 'Français' ?'Modifier le profil':'Edit Profile'),
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              UpdatedImage(),
              const SizedBox(height: 20.0),
              _buildTextField(
                controller: _nameController,
                labelText: selectedLanguage == 'Français' ? 'Nom Complet' : 'Full Name',
                icon: Icons.person,
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 16.0),
              _buildTextField(
                controller: _phoneController,
                labelText: selectedLanguage == 'Français' ? 'Numéro de Téléphone' : 'Phone Number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 16.0),
              _buildTextField(
                controller: _passwordController,
                labelText: selectedLanguage == 'Français' ? 'Nouveau Mot de Passe' : 'New Password',
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
                child: Text(
                  selectedLanguage == 'Français' ? 'Mettre à Jour le Profil' : 'Update Profile',
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
                            text: selectedLanguage == 'Français' ? 'Rejoint le ' : 'Joined ',
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
                      child: Text(                    selectedLanguage == 'Français' ? 'Supprimer' : 'Delete',
                      ),
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
                 Text(
                  selectedLanguage == 'Français' ? 'Aucune image disponible':'No image available',
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
      final List<String> extensions = ['png', 'jpg', 'jpeg', 'gif']; // Add other formats if needed
      for (String ext in extensions) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child('${user.uid}.$ext');
        try {
          // Attempt to get the download URL
          final downloadUrl = await storageRef.getDownloadURL();

          // If successful, return the download URL and stop further requests
          return downloadUrl;
        } catch (e) {
          // Print error message, but continue to the next extension
          print(selectedLanguage == 'Français'
              ? 'Erreur lors de l\'obtention de l\'URL de l\'image avec .$ext : $e'
              : 'Error getting image URL with .$ext: $e');
        }
      }
    }
    return null; // Return null if none of the extensions work
  }

}
