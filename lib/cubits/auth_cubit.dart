import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meta/meta.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthCubit() : super(AuthInitial());

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      emit(AuthSignedOut());
    } catch (e) {
      emit(AuthError('Error signing out'));
    }
  }

  Future<void> updateProfile(String name, String? photoUrl, String? password) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        // Update display name if provided
        if (name.isNotEmpty) {
          await user.updateDisplayName(name);
        }

        // Update photo URL if provided
        if (photoUrl != null && photoUrl.isNotEmpty) {
          await user.updatePhotoURL(photoUrl);
        }

        // Update password if provided
        if (password != null && password.isNotEmpty) {
          await user.updatePassword(password);
        }

        // Reload the user to apply changes
        await user.reload();
        emit(AuthProfileUpdated());
      } catch (e) {
        emit(AuthError('Error updating profile'));
      }
    }
  }
}
