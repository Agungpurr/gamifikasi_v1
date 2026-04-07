// lib/services/auth_provider.dart

import 'package:edu_kids_app/services/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'firebase_service.dart';
import 'notification_service.dart';

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

      // ✅ Ini jalan setiap app dibuka, login/tidak
      final streak = _userModel?.streakDays ?? 0;

      // Jadwalkan ulang streak warning dengan streak terbaru
      await NotificationService.scheduleStreakWarning(streak);

      // Cek apakah sudah login hari ini
      final lastLogin = _userModel?.lastLoginDate;
      if (lastLogin != null) {
        final today = DateTime.now();
        final lastDay =
            DateTime(lastLogin.year, lastLogin.month, lastLogin.day);
        final todayDay = DateTime(today.year, today.month, today.day);
        final isLoginToday = lastDay == todayDay;

        if (isLoginToday) {
          // Sudah aktif hari ini → batalkan warning
          await NotificationService.cancelStreakWarning();
        }
      }
    } else {
      _userModel = null;
    }

    notifyListeners();
  }

  Future<void> _loadUserModel(String uid) async {
    _userModel = await FirebaseService.getUserProfile(uid);
    notifyListeners();
    // Tambah ini — cek badge setiap kali user data dimuat
    await _checkBadges();
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

      if (credential?.user != null) {
        await FirebaseService.updateStreak(credential!.user!.uid);
        await _loadUserModel(credential.user!.uid);
        await _checkMilestone(); // cek streak 3, 7, 14, 30
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
    await NotificationService.cancelStreakWarning();
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

  Future<void> _checkMilestone() async {
    final streak = _userModel?.streakDays ?? 0;
    await NotificationService.showMilestoneNotification(streak);
  }

  Future<void> _checkBadges() async {
    if (_userModel == null || _firebaseUser == null) return;
    final uid = _firebaseUser!.uid;
    final badges = _userModel!.badges;
    bool anyNewBadge = false;

    // First quiz
    if (!badges.contains('first_quiz')) {
      await FirebaseService.addBadge(uid, 'first_quiz');
      anyNewBadge = true; // ✅ ini yang hilang
    }

    // Level 5
    if (_userModel!.level >= 5 && !badges.contains('level_5')) {
      await FirebaseService.addBadge(uid, 'level_5');
      anyNewBadge = true; //
    }

    // Streak
    if (_userModel!.streakDays >= 3 && !badges.contains('streak_3')) {
      await FirebaseService.addBadge(uid, 'streak_3');
      anyNewBadge = true;
    }
    if (_userModel!.streakDays >= 7 && !badges.contains('streak_7')) {
      await FirebaseService.addBadge(uid, 'streak_7');
      anyNewBadge = true;
    }

    // ✅ Subject badges — key harus sama dengan yang dikirim di addPoints
    final math = _userModel!.subjectProgress['matematika'] ?? 0;
    final bahasa = _userModel!.subjectProgress['bahasa'] ?? 0;
    final ipa = _userModel!.subjectProgress['ipa'] ?? 0;

    if (math >= 100 && !badges.contains('math_master')) {
      await FirebaseService.addBadge(uid, 'math_master');
      anyNewBadge = true;
    }
    if (bahasa >= 100 && !badges.contains('reading_hero')) {
      await FirebaseService.addBadge(uid, 'reading_hero');
      anyNewBadge = true;
    }
    if (ipa >= 100 && !badges.contains('science_wizard')) {
      await FirebaseService.addBadge(uid, 'science_wizard');
      anyNewBadge = true;
    }

    if (anyNewBadge) {
      _userModel = await FirebaseService.getUserProfile(uid);
      await AudioService.playBadgeEarned();
      notifyListeners();
    }

    // Tambah cek level up di _checkBadges()
    final oldLevel = badges.contains('level_5') ? 5 : 0;
// Simpan level sebelum update
    final levelBefore = _userModel!.level;

// ... setelah refreshUserModel
    if (_userModel!.level > levelBefore) {
      await AudioService.playLevelUp(); // ✅
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
