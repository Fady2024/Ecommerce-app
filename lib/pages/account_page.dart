import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:loginpage/pages/EditProfilePage.dart';
import 'package:loginpage/enter_to_app/welcome_screen.dart';
import 'package:provider/provider.dart';
import '../cubits/favorite_and_cart_cubit_management.dart';
import '../main.dart';
import 'OnboardingScreen2.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _userRef =
  FirebaseDatabase.instance.ref('users'); // Reference to user data
  String _selectedLanguage = 'English';
  String? _fullName;

  @override
  void initState() {
    super.initState();
    _listenForUserChanges();
  }

  void _listenForUserChanges() {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      // Listen for changes in the user's full name
      _userRef.child(userId).onValue.listen((event) {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        setState(() {
          _fullName = data?['fullName'] as String?;
        });
      });
    }
  }
  void _refreshAccountPage() {
    setState(() {
      // Trigger reload of profile details
      _listenForUserChanges();
    });
  }

  Future<void> _signOut() async {
    final fadyCardCubit = context.read<FadyCardCubit>();
    fadyCardCubit.clearFavorites();
    fadyCardCubit.clearCard();
    await _auth.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => WelcomeScreen()),
    );
  }

  void showLanguageMenu(BuildContext context) {
    showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(100, 100, 0, 0),
      items: [
        const PopupMenuItem<String>(
          value: 'English',
          child: Text('English'),
        ),
        const PopupMenuItem<String>(
          value: 'Arabic',
          child: Text('العربية'),
        ),
        const PopupMenuItem<String>(
          value: 'French',
          child: Text('Français'),
        ),
        const PopupMenuItem<String>(
          value: 'Spanish',
          child: Text('Español'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    bool isNameMissing = _auth.currentUser?.email == null || _auth.currentUser!.email!.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        actions: <Widget>[
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'English',
                  child: Text('English'),
                ),
                const PopupMenuItem<String>(
                  value: 'Arabic',
                  child: Text('العربية'),
                ),
                const PopupMenuItem<String>(
                  value: 'French',
                  child: Text('Français'),
                ),
                const PopupMenuItem<String>(
                  value: 'Spanish',
                  child: Text('Español'),
                ),
              ];
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: themeNotifier.themeMode == ThemeMode.light
                      ? Colors.black
                      : Colors.white,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings),
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'Profile',
                  child: Text('Profile Settings'),
                ),
                const PopupMenuItem<String>(
                  value: 'Notifications',
                  child: Text('Notification Settings'),
                ),
                const PopupMenuItem<String>(
                  value: 'Privacy',
                  child: Text('Privacy Settings'),
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
                backgroundColor: isNameMissing ? Colors.grey : Colors.yellow, // Disable color when name is missing
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: isNameMissing
                  ? null // Disable button if name is missing
                  : () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => EditProfilePage(
                      onProfileUpdated: _refreshAccountPage, // Pass the refresh function
                    )),
                );
              },
              child: Text(
                'Edit Profile',
                style: TextStyle(
                  color: Colors.black,
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
                    padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
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
                                    color: themeNotifier.themeMode == ThemeMode.dark
                                        ? Color(0xFFE3E16B)
                                        : Color(0xFF36399C),
                                  ),
                                ),
                              ),
                              Text(
                                'About Us',
                                style: TextStyle(
                                  color: themeNotifier.themeMode == ThemeMode.dark
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
                      onTap: () => _signOut(),
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
                                    Icons.exit_to_app,
                                    color: themeNotifier.themeMode == ThemeMode.dark
                                        ? Color(0xFFE3E16B)
                                        : Color(0xFF36399C),
                                  ),
                                ),
                              ),
                              Text(
                                'Logout',
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
                  ),
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
        String initialLetter = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A';
        bool isNameMissing = _auth.currentUser?.email == null || _auth.currentUser!.email!.isEmpty;

        return Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 50.0,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: snapshot.connectionState == ConnectionState.waiting
                      ? null
                      : (snapshot.hasData && snapshot.data != null
                      ? CachedNetworkImageProvider(snapshot.data!)
                      : null),
                  child: snapshot.connectionState == ConnectionState.waiting
                      ? const CircularProgressIndicator()
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
                              onProfileUpdated: _refreshAccountPage, // Pass the refresh function
                            )),
                        );
                      } else {
                        // Optionally, show an alert or message if the name is missing
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please log in to edit your profile information.')),
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
              displayName != 'A' ? displayName : 'User Name',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20.0,
              ),
            ),
            Text(
              _auth.currentUser?.email ?? 'user@example.com',
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
                  "It looks like you haven’t signed in yet. Go to Sign In to access your profile.",
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
