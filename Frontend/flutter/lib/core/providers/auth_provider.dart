import 'package:flutter_riverpod/flutter_riverpod.dart';

// State to store current logged in user
class UserState {
  final int id;
  final String email;
  final String fullName;
  final String userRole;
  final bool isAdmin;

  UserState({
    required this.id,
    required this.email,
    required this.fullName,
    required this.userRole,
    this.isAdmin = false,
  });
}

class AuthNotifier extends StateNotifier<UserState?> {
  AuthNotifier() : super(null);

  void login(int id, String email, String fullName, {String userRole = "User"}) {
    state = UserState(
      id: id,
      email: email,
      fullName: fullName,
      userRole: userRole,
      isAdmin: userRole.toLowerCase() == 'admin',
    );
  }

  void logout() {
    state = null;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, UserState?>((ref) {
  return AuthNotifier();
});
