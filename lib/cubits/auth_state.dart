part of 'auth_cubit.dart';

@immutable
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthSignedOut extends AuthState {}

class AuthProfileUpdated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}
