import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loginpage/pages/splash_home%20page.dart';
import 'package:provider/provider.dart';
import 'cubits/auth_cubit.dart';
import 'cubits/favorite_and_cart_cubit_management.dart';
import 'cubits/splash_cubit.dart';
import 'cubits/user_profile_provider.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}
class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()), // Add UserProfileProvider
        BlocProvider(create: (context) => FadyCardCubit()..loadCartProducts()),
        BlocProvider(create: (context) => AuthCubit()),
        BlocProvider(create: (context) => SplashCubit()),
      ],
      child: Consumer<ThemeNotifier>(
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
            home: SplashScreen2(), // Set SplashScreen as the initial page

          );
        },
      ),
    );
  }
}