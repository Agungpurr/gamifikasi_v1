// lib/services/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'firebase_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _firebaseUser;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _error;

  User? get firebaseUser => _firebaseUser;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _firebaseUser != null;

  AuthProvider() {
    FirebaseService.authStateChanges.listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(User? user) async {
    _firebaseUser = user;
    if (user != null) {
      await _loadUserModel(user.uid);
      // await FirebaseService.updateStreak(user.uid);
    } else {
      _userModel = null;
    }
    notifyListeners();
  }

  Future<void> _loadUserModel(String uid) async {
    _userModel = await FirebaseService.getUserProfile(uid);
    notifyListeners();
  }

  Future<bool> register({
    required String email,
    required String password,
    required String username,
    required String avatarId,
    required String grade,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final credential =
          await FirebaseService.registerWithEmail(email, password);
      if (credential?.user != null) {
        final user = UserModel(
          uid: credential!.user!.uid,
          username: username,
          avatarId: avatarId,
          lastLoginDate: DateTime.now(),
          createdAt: DateTime.now(),
          subjectProgress: {'grade': int.tryParse(grade) ?? 1},
        );
        await FirebaseService.createUserProfile(user);
        _userModel = user;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final credential = await FirebaseService.loginWithEmail(email, password);

      // ✅ Update streak hanya saat login
      if (credential?.user != null) {
        await FirebaseService.updateStreak(credential!.user!.uid);
        await _loadUserModel(credential.user!.uid);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await FirebaseService.signOut();
    _userModel = null;
    notifyListeners();
  }

  Future<void> refreshUserModel() async {
    if (_firebaseUser != null) {
      await _loadUserModel(_firebaseUser!.uid);
    }
  }

  Future<void> addPoints(int points, String subject) async {
    if (_firebaseUser == null || _userModel == null) return;

    await FirebaseService.addPoints(_firebaseUser!.uid, points, subject);
    await refreshUserModel();

    // Check badge conditions
    await _checkBadges();
  }

  Future<void> _checkBadges() async {
    if (_userModel == null || _firebaseUser == null) return;
    final uid = _firebaseUser!.uid;
    final badges = _userModel!.badges;

    // First quiz badge
    if (!badges.contains('first_quiz')) {
      await FirebaseService.addBadge(uid, 'first_quiz');
    }

    // Level 5 badge
    if (_userModel!.level >= 5 && !badges.contains('level_5')) {
      await FirebaseService.addBadge(uid, 'level_5');
    }

    // Streak badges
    if (_userModel!.streakDays >= 3 && !badges.contains('streak_3')) {
      await FirebaseService.addBadge(uid, 'streak_3');
    }
    if (_userModel!.streakDays >= 7 && !badges.contains('streak_7')) {
      await FirebaseService.addBadge(uid, 'streak_7');
    }

    await refreshUserModel();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
