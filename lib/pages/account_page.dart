import 'package:firebase_auth/firebase_auth.dart';
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
  String _selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
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



  // Define the showLanguageMenu method
  void showLanguageMenu(BuildContext context) {
    showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(100, 100, 0, 0), // Adjust position as needed
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
    final hasEmail = _auth.currentUser?.email?.isNotEmpty ?? false;
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        actions: <Widget>[
          // Language selection icon
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
                  child: Text('العربية'), // Arabic text for 'Arabic'
                ),
                const PopupMenuItem<String>(
                  value: 'French',
                  child: Text('Français'), // French text for 'French'
                ),
                const PopupMenuItem<String>(
                  value: 'Spanish',
                  child: Text('Español'), // Spanish text for 'Spanish'
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
            Expanded(
              child: ListView(
                children: [
                  const SizedBox(height: 20.0),
                  ElevatedButton(
                    onPressed: hasEmail
                        ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => EditProfilePage(),
                        ),
                      );
                    }
                        : null, // Disable button if no email
                    child: const Text('Edit Information'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              DevPage(), // Ensure this page exists
                        ),
                      );
                    },
                    child: const Text('About Us'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.exit_to_app),
                    title: const Text('Logout'),
                    onTap: () => _signOut(),
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
    return FutureBuilder<String?>(
      future: _getProfileImageUrl(),
      builder: (context, snapshot) {
        String displayName = _auth.currentUser?.displayName ?? 'A';
        String initialLetter =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A';
        bool isNameMissing =
            _auth.currentUser?.email == null || _auth.currentUser!.email!.isEmpty;

        return Column(
          children: [
            CircleAvatar(
              radius: 50.0,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: snapshot.connectionState == ConnectionState.waiting
                  ? null
                  : (snapshot.hasData && snapshot.data != null
                  ? NetworkImage(snapshot.data!)
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
            const SizedBox(height: 16.0),
            Text(
              displayName != 'A' ? displayName : 'User Name',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              _auth.currentUser?.email ?? 'user@example.com',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (isNameMissing) // Conditionally show this message
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
