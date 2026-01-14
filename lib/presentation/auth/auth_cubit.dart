import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safety_portal/core/logger.dart';

enum AppRole { admin, safety, engineer, user }

class AuthState {
  final User? user;
  final AppRole role;
  final String displayName;
  AuthState({this.user, this.role = AppRole.user , this.displayName = "Guest"});

  AuthState copyWith({
    User? user,
    AppRole? role,
    String? displayName,
  }) {
    return AuthState(
      user: user ?? this.user,
      role: role ?? this.role,
      displayName: displayName ?? this.displayName,
    );
  }

  // UI Permission Getters
  bool get canValidate => role == AppRole.admin || role == AppRole.safety;
  bool get canModify => role == AppRole.admin || role == AppRole.safety;
  bool get canViewAnalytics => role != AppRole.user; // General users are excluded from complex charts
  bool get isAdmin => role == AppRole.admin;
}

class AuthCubit extends Cubit<AuthState> with LogMixin{
  AuthCubit() : super(AuthState());

  String get currentUserName => state.displayName;

  void setRole(AppRole role) => emit(AuthState(user: state.user, role: role));
    Future<void> login(String email, String password) async {
    try {
      if (FirebaseAuth.instance.app.options.apiKey.isNotEmpty) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      }
    } catch (e) {
      logError("Login error: $e");
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }
  
  void setUser(User? user) => emit(state.copyWith(user: user));
}

