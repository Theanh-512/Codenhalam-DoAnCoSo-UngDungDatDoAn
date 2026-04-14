import 'package:flutter_riverpod/flutter_riverpod.dart';

// State to store current logged in user
class UserState {
  final int id;
  final String email;
  final String fullName;
  final bool isAdmin;

  UserState({
    required this.id,
    required this.email,
    required this.fullName,
    this.isAdmin = false,
  });
}

class AuthNotifier extends StateNotifier<UserState?> {
  AuthNotifier() : super(null);

  void login(int id, String email, String fullName) {
    state = UserState(
      id: id,
      email: email,
      fullName: fullName,
      isAdmin: email == 'admin@foodapp.com',
    );
  }

  void logout() {
    state = null;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, UserState?>((ref) {
  return AuthNotifier();
});
