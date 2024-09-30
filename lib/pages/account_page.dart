import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:loginpage/pages/EditProfilePage.dart';
import 'package:loginpage/enter_to_app/welcome_screen.dart';
import 'package:loginpage/pages/restart.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../cubits/favorite_and_cart_cubit_management.dart';
import '../main.dart';
import 'OnboardingScreen2.dart';
import 'day_night_switch.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _userRef =
      FirebaseDatabase.instance.ref('users'); // Reference to user data
  String _selectedLanguage =
      AppState().selectedLanguage; // Initialize with the globally set language
  String? _fullName;
  String? _userEmail; // Add this variable
  String? _deviceId; // Add device ID variable
  late StreamSubscription<DatabaseEvent>? _userChangesSubscription; // Make it nullable

  @override
  void initState() {
    super.initState();
    _listenForUserChanges();
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _getDeviceId();
  }

  Future<void> _getDeviceId() async {
    DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    if (Theme.of(context).platform == TargetPlatform.android) {
      AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
      _deviceId = _sanitizeEmail(androidInfo.id);
    } else if (Theme.of(context).platform == TargetPlatform.iOS) {
      IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
      _deviceId = iosInfo.identifierForVendor;
    }
  }


  void _updateLanguage(String language) async {
    setState(() {
      _selectedLanguage = language;
    });
    final languagePreference = language == 'English' ? 'en' : 'fr';

    if (_userEmail != null) {
      final sanitizedEmail = _sanitizeEmail(_userEmail!);
      await _userRef.child('accountUsers').child(sanitizedEmail).child('language').set(languagePreference);
    }

    if (_deviceId != null) {
      await _userRef.child('guestUsers').child(_deviceId!).child('language').set(languagePreference);
    }

    AppState().setLanguage(language);
    AppState().setLoading(true);
    RestartWidget.restartApp(context);
  }

  void _loadUserData() {
    final user = _auth.currentUser;
    if (user != null) {
      _userEmail = user.email;
      _userRef.child('accountUsers').child(_sanitizeEmail(_userEmail!)).child('language').once().then((DatabaseEvent event) {
        final snapshot = event.snapshot;
        if (mounted) {
          setState(() {
            _selectedLanguage = snapshot.exists && snapshot.value == 'fr' ? 'Français' : 'English';
            AppState().setLanguage(_selectedLanguage);
          });
        }
      });
    } else if (_deviceId != null) {
      _userRef.child('guestUsers').child(_deviceId!).child('language').once().then((DatabaseEvent event) {
        final snapshot = event.snapshot;
        if (mounted) {
          setState(() {
            _selectedLanguage = snapshot.exists && snapshot.value == 'fr' ? 'Français' : 'English';
            AppState().setLanguage(_selectedLanguage);
          });
        }
      });
    }
  }

  void _listenForUserChanges() {
    final user = _auth.currentUser;

    if (user != null) {
      final sanitizedEmail = _sanitizeEmail(user.email!);
      _userChangesSubscription = _userRef
          .child('accountUsers')
          .child(sanitizedEmail)
          .onValue
          .listen((event) {
        if (mounted) {
          final data = event.snapshot.value as Map<dynamic, dynamic>?;
          setState(() {
            _fullName = data?['fullName'] as String?;
            _selectedLanguage =
            data?['language'] == 'fr' ? 'Français' : 'English';
          });
        }
      });
    } else if (_deviceId != null) {
      _userChangesSubscription = _userRef
          .child('guestUsers')
          .child(_deviceId!)
          .onValue
          .listen((event) {
        if (mounted) {
          final data = event.snapshot.value as Map<dynamic, dynamic>?;
          setState(() {
            _selectedLanguage =
            data?['language'] == 'fr' ? 'Français' : 'English';
          });
        }
      });
    } else {
      _userChangesSubscription = null;
    }
  }


  void _refreshAccountPage() {
    setState(() {
      _listenForUserChanges();
    });
  }

  Future<void> _signOut() async {
    final fadyCardCubit = context.read<FadyCardCubit>();
    fadyCardCubit.clearFavorites();
    fadyCardCubit.clearCard();

    await _auth.signOut();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => WelcomeScreen()),
      );
    }
  }

  String _sanitizeEmail(String email) {
    return email.replaceAll(RegExp(r'[.#$[\]]'), ',');
  }

  // Toggle theme mode
  void _toggleTheme(bool value) {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    themeNotifier.toggleTheme(); // Toggle theme in your provider
  }

  @override
  void dispose() {
    if (_userChangesSubscription != null) {
      _userChangesSubscription!.cancel();
    }
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    // Update _isDarkMode based on the current theme
    bool _isDarkMode = themeNotifier.themeMode == ThemeMode.light ?true:false;
    bool isNameMissing =
        _auth.currentUser?.email == null || _auth.currentUser!.email!.isEmpty;
    _selectedLanguage = AppState().selectedLanguage;

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedLanguage == 'Français' ? 'Compte' : 'Account'),
        actions: <Widget>[
          PopupMenuButton<String>(
              icon: const Icon(Icons.language),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              itemBuilder: (BuildContext context) {
                return [
                  for (String language in ['English', 'Français'])
                    PopupMenuItem<String>(
                      value: language,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12.0, horizontal: 16.0),
                        decoration: BoxDecoration(
                          color: _selectedLanguage == language
                              ? Colors.blueAccent
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                          boxShadow: [
                            if (_selectedLanguage == language)
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                spreadRadius: 1,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                          ],
                        ),
                        child: Text(
                          language,
                          style: TextStyle(
                            fontWeight: _selectedLanguage == language
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: _selectedLanguage == language
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                ];
              },
              onSelected: (String value) {
                if (value == _selectedLanguage) {
                  // Show a message if the selected language is already active
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.blueAccent,
                      // Set your desired background color
                      content: Container(
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          // Ensure the background color is consistent
                          borderRadius:
                              BorderRadius.circular(12), // Rounded corners
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        child: Text(
                          _selectedLanguage == 'Français'
                              ? 'Vous avez déjà sélectionné la langue $value.'
                              : 'You have already selected $value language.',
                          style: TextStyle(
                            color: Colors.white, // Text color
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      duration:
                          Duration(seconds: 1), // Duration to show the SnackBar
                    ),
                  );
                } else {
                  _updateLanguage(value); // Update language preference
                }
              }),
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings),
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'Profile',
                  child: Text(_selectedLanguage == 'Français'
                      ? 'Paramètres du profil'
                      : 'Profile Settings'),
                ),
                PopupMenuItem<String>(
                  value: 'Notifications',
                  child: Text(_selectedLanguage == 'Français'
                      ? 'Paramètres de notification'
                      : 'Notification Settings'),
                ),
                PopupMenuItem<String>(
                  value: 'Privacy',
                  child: Text(_selectedLanguage == 'Français'
                      ? 'Paramètres de confidentialité'
                      : 'Privacy Settings'),
                ),
              ];
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildAccountHeader(),
            const SizedBox(height: 16.0),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isNameMissing
                    ? themeNotifier.themeMode == ThemeMode.dark
                        ? Colors.grey[800]
                        : Colors.grey
                    : Colors.yellow, // Disable color when name is missing
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: isNameMissing
                  ? null // Disable button if name is missing
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => EditProfilePage(
                                  onProfileUpdated:
                                      _refreshAccountPage, // Pass the refresh function
                                )),
                      );
                    },
              child: Text(
                _selectedLanguage == 'Français'
                    ? 'Modifier le profil'
                    : 'Edit Profile',
                style: TextStyle(
                  color: isNameMissing
                      ? themeNotifier.themeMode == ThemeMode.dark
                          ? Colors.white
                          : Colors.black
                      : Colors.black,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  const SizedBox(height: 20.0),
                  Divider(
                    color: Colors.grey.withOpacity(0.5),
                    thickness: 1,
                  ),
                  SizedBox(height: 10),
                  Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => DevPage(),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                margin: EdgeInsets.only(right: 10.0),
                                child: CircleAvatar(
                                  backgroundColor:
                                      themeNotifier.themeMode == ThemeMode.light
                                          ? Color(0xFFE1E7FA)
                                          : Color(0xFF44432D),
                                  child: Icon(
                                    Icons.info_outline_rounded,
                                    color: themeNotifier.themeMode ==
                                            ThemeMode.dark
                                        ? Color(0xFFE3E16B)
                                        : Color(0xFF36399C),
                                  ),
                                ),
                              ),
                              Text(
                                _selectedLanguage == 'Français'
                                    ? 'À propos de nous'
                                    : 'About Us',
                                style: TextStyle(
                                  color:
                                      themeNotifier.themeMode == ThemeMode.dark
                                          ? Colors.white
                                          : Colors.black,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: themeNotifier.themeMode == ThemeMode.dark
                                ? Colors.grey
                                : Colors.black,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                    child: GestureDetector(
                      onTap: () {
                        if (isNameMissing) {
                          // Navigate to WelcomeScreen if the name is missing
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => WelcomeScreen(),
                            ),
                          );
                        } else {
                          // Perform logout if the name is not missing
                          _signOut();
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                margin: EdgeInsets.only(right: 10.0),
                                child: CircleAvatar(
                                  backgroundColor: themeNotifier.themeMode == ThemeMode.light
                                      ? Color(0xFFE1E7FA)
                                      : Color(0xFF44432D),
                                  child: Icon(
                                    isNameMissing
                                        ? Icons.arrow_back // Back icon when name is missing
                                        : Icons.exit_to_app, // Logout icon otherwise
                                    color: themeNotifier.themeMode == ThemeMode.dark
                                        ? Color(0xFFE3E16B)
                                        : Color(0xFF36399C),
                                  ),
                                ),
                              ),
                              Text(
                                isNameMissing
                                    ? _selectedLanguage == 'Français'
                                    ? 'Retour'
                                    : 'Back'
                                    : _selectedLanguage == 'Français'
                                    ? 'Se déconnecter'
                                    : 'Logout',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: themeNotifier.themeMode == ThemeMode.light
                                      ? Colors.redAccent
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountHeader() {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return FutureBuilder<String?>(
      future: _getProfileImageUrl(),
      builder: (context, snapshot) {
        String displayName = _fullName ?? _auth.currentUser?.displayName ?? 'A';
        String initialLetter =
            displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A';
        bool isNameMissing = _auth.currentUser?.email == null ||
            _auth.currentUser!.email!.isEmpty;

        return Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 50.0,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage:
                      snapshot.connectionState == ConnectionState.waiting
                          ? null
                          : (snapshot.hasData && snapshot.data != null
                              ? CachedNetworkImageProvider(snapshot.data!)
                              : null),
                  child: snapshot.connectionState == ConnectionState.waiting
                      ? Lottie.asset(
                          'lib/data/Animation - 1727010739635.json',
                          width: 150,
                          height: 150,
                        )
                      : (snapshot.hasData && snapshot.data != null
                          ? null
                          : Text(
                              initialLetter,
                              style: const TextStyle(
                                  fontSize: 40.0, color: Colors.black),
                            )),
                ),
                GestureDetector(
                  onTap: () {
                    if (!isNameMissing) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => EditProfilePage(
                                  onProfileUpdated:
                                      _refreshAccountPage, // Pass the refresh function
                                )),
                      );
                    } else {
                      // Optionally, show an alert or message if the name is missing
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(_selectedLanguage == 'Français'
                                ? 'Veuillez vous connecter pour modifier vos informations de profil.'
                                : 'Please log in to edit your profile information.')),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6.0),
                    decoration: BoxDecoration(
                      color: Colors.yellow,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Text(
              displayName != 'A'
                  ? displayName
                  : _selectedLanguage == 'Français'
                      ? 'Nom d\'utilisateur'
                      : 'User Name',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0,
                  ),
            ),
            Text(
              _selectedLanguage == 'Français'
                  ? (_auth.currentUser?.email ?? 'utilisateur@example.com')
                  : (_auth.currentUser?.email ?? 'user@example.com'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 15.0,
                    color: themeNotifier.themeMode == ThemeMode.light
                        ? Color(0xFF606060)
                        : Color(0xFFCECECE),
                  ),
            ),
            if (isNameMissing)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _selectedLanguage == 'Français'
                      ? "Il semble que vous ne vous soyez pas encore connecté. Allez vous connecter pour accéder à votre profil."
                      : "It looks like you haven’t signed in yet. Go to Sign In to access your profile.",
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 14.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
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
          print(_selectedLanguage == 'Français'
              ? 'Erreur lors de l\'obtention de l\'URL de l\'image avec .$ext : $e'
              : 'Error getting image URL with .$ext: $e');
        }
      }
    }
    return null; // Return null if none of the extensions work
  }

}
