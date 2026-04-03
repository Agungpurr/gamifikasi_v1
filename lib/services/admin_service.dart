// lib/services/admin_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/question_model.dart';

class AdminService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ═══════════════════════════════════════════
  // CEK ADMIN
  // ═══════════════════════════════════════════

  static Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final doc = await _db.collection('admins').doc(user.uid).get();
    return doc.exists;
  }

  static Future<void> setAdminByEmail(String email) async {
    // Panggil sekali untuk set admin pertama kali via console / seed
    final query =
        await _db.collection('users').where('email', isEqualTo: email).get();
    if (query.docs.isNotEmpty) {
      final uid = query.docs.first.id;
      await _db.collection('admins').doc(uid).set({'email': email});
    }
  }

  // ═══════════════════════════════════════════
  // USERS CRUD
  // ═══════════════════════════════════════════

  static Stream<List<UserModel>> getAllUsersStream() {
    return _db
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => UserModel.fromMap(d.data())).toList());
  }

  static Future<List<UserModel>> getAllUsers() async {
    final snap = await _db
        .collection('users')
        .orderBy('totalPoints', descending: true)
        .get();
    return snap.docs.map((d) => UserModel.fromMap(d.data())).toList();
  }

  static Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  static Future<void> deleteUser(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }

  static Future<void> resetUserProgress(String uid) async {
    await _db.collection('users').doc(uid).update({
      'totalPoints': 0,
      'level': 1,
      'streakDays': 0,
      'subjectProgress': {},
      'badges': [],
    });
  }

  // ═══════════════════════════════════════════
  // QUESTIONS CRUD
  // ═══════════════════════════════════════════

  static Stream<List<QuestionModel>> getAllQuestionsStream() {
    return _db.collection('questions').orderBy('subject').snapshots().map(
        (snap) => snap.docs
            .map((d) => QuestionModel.fromMap({...d.data(), 'id': d.id}))
            .toList());
  }

  static Future<List<QuestionModel>> getAllQuestions({
    String? subject,
    String? grade,
  }) async {
    Query query = _db.collection('questions');
    if (subject != null && subject.isNotEmpty) {
      query = query.where('subject', isEqualTo: subject);
    }
    if (grade != null && grade.isNotEmpty) {
      query = query.where('grade', isEqualTo: grade);
    }
    final snap = await query.get();
    return snap.docs
        .map((d) => QuestionModel.fromMap(
            {...d.data() as Map<String, dynamic>, 'id': d.id}))
        .toList();
  }

  static Future<String> addQuestion(QuestionModel question) async {
    final ref = await _db.collection('questions').add({
      'subject': question.subject,
      'grade': question.grade,
      'question': question.question,
      'options': question.options,
      'correctIndex': question.correctIndex,
      'explanation': question.explanation,
      'points': question.points,
      'difficulty': question.difficulty,
    });
    return ref.id;
  }

  static Future<void> updateQuestion(
      String id, Map<String, dynamic> data) async {
    await _db.collection('questions').doc(id).update(data);
  }

  static Future<void> deleteQuestion(String id) async {
    await _db.collection('questions').doc(id).delete();
  }

  // ═══════════════════════════════════════════
  // STATISTIK DASHBOARD
  // ═══════════════════════════════════════════

  static Future<Map<String, dynamic>> getDashboardStats() async {
    final usersSnap = await _db.collection('users').get();
    final questionsSnap = await _db.collection('questions').get();

    final totalUsers = usersSnap.docs.length;
    final totalQuestions = questionsSnap.docs.length;

    // Hitung soal per mapel
    final Map<String, int> questionsBySubject = {};
    for (final doc in questionsSnap.docs) {
      final subject = doc.data()['subject'] as String? ?? 'unknown';
      questionsBySubject[subject] = (questionsBySubject[subject] ?? 0) + 1;
    }

    // Top 5 user berdasarkan poin
    final topUsers = usersSnap.docs
        .map((d) => UserModel.fromMap(d.data()))
        .toList()
      ..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));

    return {
      'totalUsers': totalUsers,
      'totalQuestions': totalQuestions,
      'questionsBySubject': questionsBySubject,
      'topUsers': topUsers.take(5).toList(),
    };
  }
}
