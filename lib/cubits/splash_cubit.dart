import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meta/meta.dart';
import 'dart:async'; // For delay

part 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  SplashCubit() : super(SplashInitial()) {
    _showSplashScreen();
  }

  Future<void> _showSplashScreen() async {
    // Show SplashScreen2 for 3 seconds
    await Future.delayed(const Duration(seconds: 3));

    final user = _auth.currentUser;
    if (user != null) {
      emit(SplashLoggedIn());
    } else {
      emit(SplashLoggedOut());
    }
  }
}
