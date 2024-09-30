import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loginpage/pages/Loading_page.dart';
import 'package:loginpage/pages/restart.dart';
import 'package:loginpage/pages/splash_home%20page.dart';
import 'package:provider/provider.dart';
import 'cubits/auth_cubit.dart';
import 'cubits/favorite_and_cart_cubit_management.dart';
import 'cubits/user_profile_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'data/data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        BlocProvider(create: (context) => FadyCardCubit()..loadProducts()),
        BlocProvider(create: (context) => AuthCubit()),
      ],
      child: RestartWidget(child: MyApp()),
    ),
  );
}

class ThemeNotifier extends ChangeNotifier {
  ThemeMode? _themeMode;  // Use nullable type to avoid initialization error
  final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

  ThemeMode get themeMode {
    // Return system mode if _themeMode is not yet loaded (null)
    return _themeMode ?? ThemeMode.system;
  }

  Future<void> loadThemeModeFromFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    final userRef = FirebaseDatabase.instance.ref('users');

    if (user != null) {
      // Load theme for authenticated user
      String sanitizedEmail = _sanitizeEmail(user.email!);
      DatabaseEvent themeEvent = await userRef
          .child('accountUsers')
          .child(sanitizedEmail)
          .child('Theme Mode')
          .once();
      final themeSnapshot = themeEvent.snapshot;

      if (themeSnapshot.exists) {
        final themeValue = themeSnapshot.value as String;
        _themeMode = themeValue == 'dark' ? ThemeMode.dark : ThemeMode.light;
      } else {
        // If no value exists in Firebase, set to system default
        _themeMode = ThemeMode.system;
      }
    } else {
      // Load theme for guest user
      String deviceId = await _getDeviceId();
      final deviceRef = userRef.child('guestUsers');
      DatabaseEvent themeEvent = await deviceRef.child(deviceId).child('Theme Mode').once();
      final themeSnapshot = themeEvent.snapshot;

      if (themeSnapshot.exists) {
        final themeValue = themeSnapshot.value as String;
        _themeMode = themeValue == 'dark' ? ThemeMode.dark : ThemeMode.light;
      } else {
        // If no value exists in Firebase, set to system default
        _themeMode = ThemeMode.system;
      }
    }

    notifyListeners();  // Notify listeners after the theme mode is set
  }

  void toggleTheme() {
    // Toggle between light and dark mode
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _saveThemeModeToFirebase();  // Save the toggled theme to Firebase
    notifyListeners();
  }

  Future<void> _saveThemeModeToFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    final userRef = FirebaseDatabase.instance.ref('users');

    if (user != null) {
      // Save for authenticated user in 'accountUsers'
      String sanitizedEmail = _sanitizeEmail(user.email!);
      await userRef
          .child('accountUsers')
          .child(sanitizedEmail)
          .child('Theme Mode')
          .set(_themeMode == ThemeMode.dark ? 'dark' : 'light');
    } else {
      // Save for guest user in 'guestUsers'
      String deviceId = await _getDeviceId();
      final deviceRef = FirebaseDatabase.instance.ref('users').child('guestUsers');
      await deviceRef.child(deviceId).child('Theme Mode')
          .set(_themeMode == ThemeMode.dark ? 'dark' : 'light');
    }
  }

  Future<String> _getDeviceId() async {
    String deviceId = '';
    if (defaultTargetPlatform == TargetPlatform.android) {
      AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
      deviceId = _sanitizeEmail(androidInfo.id);  // Unique ID on Android
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
      deviceId = iosInfo.identifierForVendor!;  // Unique ID on iOS
    }
    return deviceId;
  }

  String _sanitizeEmail(String email) {
    return email.replaceAll(RegExp(r'[.#$[\]]'), ',');
  }
}


class AppState with ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;

  AppState._internal();

  bool isLoading = false;
  String _selectedLanguage = ''; // Initially empty, will be set from Firebase

  String get selectedLanguage => _selectedLanguage;

  void setLoading(bool loading) {
    isLoading = loading;
    notifyListeners(); // Notify listeners when loading state changes
  }

  void setLanguage(String language) {
    _selectedLanguage = language;
    notifyListeners(); // Notify listeners when language changes
  }

  Future<void> loadLanguageFromFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    final userRef = FirebaseDatabase.instance.ref('users');

    if (user != null) {
      // Load language for authenticated user from 'accountUsers'
      final sanitizedEmail = _sanitizeEmail(user.email!);
      DatabaseEvent event =
      await userRef.child('accountUsers').child(sanitizedEmail).child('language').once();
      final snapshot = event.snapshot;
      if (snapshot.exists) {
        setLanguage(snapshot.value == 'fr' ? 'Français' : 'English');
      }
    } else {
      // Load language for guest user from 'guestUsers'
      String deviceId = await _getDeviceId();
      final deviceRef = userRef.child('guestUsers');
      DatabaseEvent event =
      await deviceRef.child(deviceId).child('language').once();
      final snapshot = event.snapshot;
      if (snapshot.exists) {
        setLanguage(snapshot.value == 'fr' ? 'Français' : 'English');
      }
    }
  }

  String _sanitizeEmail(String email) {
    return email.replaceAll(RegExp(r'[.#$[\]]'), ',');
  }

  Future<String> _getDeviceId() async {
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    String deviceId = '';
    if (defaultTargetPlatform == TargetPlatform.android) {
      AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
      deviceId = _sanitizeEmail(androidInfo.id); // Unique ID on Android
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
      deviceId = iosInfo.identifierForVendor!; // Unique ID on iOS
    }
    return deviceId;
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Flutter Firebase App',
          theme: ThemeData(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              secondary: Colors.blueAccent,
            ),
            scaffoldBackgroundColor: Colors.white,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.dark(
              primary: Colors.blue,
              secondary: Colors.blueAccent,
            ),
            scaffoldBackgroundColor: Colors.black,
          ),
          themeMode: themeNotifier.themeMode,
          home: FutureBuilder(
            future: Future.wait([
              _loadLanguagePreference(), // Load language preference from Firebase
              themeNotifier.loadThemeModeFromFirebase(), // Load theme mode
              DataService().loadProducts(AppState().selectedLanguage), // Pass selected language here
            ]),
            builder: (context, snapshot) {
              if (AppState().isLoading) {
                return LoadingScreen(); // Show loading while fetching preferences
              }

              AppState().setLoading(false); // Mark loading as complete

              return SplashScreen2(); // Show splash screen when done
            },
          ),
        );
      },
    );
  }

  Future<void> _loadLanguagePreference() async {
    await AppState().loadLanguageFromFirebase(); // Load language preference
  }
}
