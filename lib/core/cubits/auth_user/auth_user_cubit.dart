import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:codeshastraxi_overload_oblivion/core/entities/user_entity.dart';

part 'auth_user_state.dart';

class AuthUserCubit extends Cubit<AuthUserState> {
  final firebase_auth.FirebaseAuth _firebaseAuth;

  AuthUserCubit(this._firebaseAuth) : super(AuthUserInitial()) {
    _loadUser();
  }

  void _loadUser() {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null) {
        final user = User(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          firstName: firebaseUser.displayName?.split(' ').first ?? '',
          middleName: '',
          lastName: firebaseUser.displayName?.split(' ').last ?? '',
          emailVerified: firebaseUser.emailVerified,
        );
        emit(AuthUserLoggedIn(user));
      }
    } catch (e) {
      print('Error loading user: $e');
      // Just keep the initial state if there's an error
    }
  }

  Future<void> updateUser(User? user) async {
    if (user == null) {
      emit(AuthUserInitial());
    } else {
      emit(AuthUserLoggedIn(user));
    }
  }

  Future<void> clearUser() async {
    emit(AuthUserInitial());
  }
}
