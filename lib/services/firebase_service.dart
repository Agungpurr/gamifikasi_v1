// lib/services/firebase_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/badge_model.dart';
import '../models/question_model.dart';
import '../models/user_model.dart';

class FirebaseService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ═══════════════════════════════════════════
  // AUTH
  // ═══════════════════════════════════════════

  static Future<UserCredential?> registerWithEmail(
    String email,
    String password,
  ) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  static Future<UserCredential?> loginWithEmail(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ═══════════════════════════════════════════
  // USER PROFILE
  // ═══════════════════════════════════════════

  static Future<void> createUserProfile(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  static Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  static Stream<UserModel?> getUserStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    });
  }

  static Future<void> updateUserProfile(
      String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  static Future<void> addPoints(String uid, int points, String subject) async {
    final userRef = _db.collection('users').doc(uid);

    await _db.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);
      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      final currentPoints = userData['totalPoints'] ?? 0;
      final newTotalPoints = currentPoints + points;
      final newLevel = (newTotalPoints / 100).floor() + 1;

      final subjectProgress =
          Map<String, int>.from(userData['subjectProgress'] ?? {});
      subjectProgress[subject] = (subjectProgress[subject] ?? 0) + points;

      transaction.update(userRef, {
        'totalPoints': newTotalPoints,
        'level': newLevel,
        'subjectProgress': subjectProgress,
      });
    });
  }

  static Future<void> addBadge(String uid, String badgeId) async {
    await _db.collection('users').doc(uid).update({
      'badges': FieldValue.arrayUnion([badgeId]),
    });
  }

  static Future<void> updateStreak(String uid) async {
    final userRef = _db.collection('users').doc(uid);
    final doc = await userRef.get();
    if (!doc.exists) return;

    final data = doc.data()!;

    // Normalize ke tengah malam untuk perbandingan yang akurat
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final lastLoginRaw = data['lastLoginDate'];

    // Jika belum pernah login sama sekali
    if (lastLoginRaw == null) {
      await userRef.update({
        'streakDays': 1,
        'lastLoginDate': today.toIso8601String(),
      });
      return;
    }

    final lastLoginParsed = DateTime.parse(lastLoginRaw);
    final lastDay = DateTime(
      lastLoginParsed.year,
      lastLoginParsed.month,
      lastLoginParsed.day,
    );

    final difference = today.difference(lastDay).inDays;

    if (difference == 0) {
      // Sudah dicatat hari ini, tidak perlu update apapun
      return;
    }

    int newStreak = data['streakDays'] ?? 0;

    if (difference == 1) {
      // Hari berturut-turut
      newStreak += 1;
    } else {
      // Streak putus (skip > 1 hari)
      newStreak = 1;
    }

    await userRef.update({
      'streakDays': newStreak,
      'lastLoginDate': today.toIso8601String(), // simpan tanggal saja (00:00)
    });
  }

  // ═══════════════════════════════════════════
  // QUESTIONS
  // ═══════════════════════════════════════════

  static Future<List<QuestionModel>> getQuestions(
    String subject,
    String grade, {
    int limit = 10,
  }) async {
    final query = await _db
        .collection('questions')
        .where('subject', isEqualTo: subject)
        .where('grade', isEqualTo: grade)
        .limit(limit)
        .get();

    final questions = query.docs
        .map((doc) => QuestionModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList();

    questions.shuffle();
    return questions;
  }

  // ═══════════════════════════════════════════
  // QUIZ RESULTS
  // ═══════════════════════════════════════════

  static Future<void> saveQuizResult({
    required String uid,
    required String subject,
    required String grade,
    required int score,
    required int totalQuestions,
    required int correctAnswers,
    required int timeTaken,
  }) async {
    await _db.collection('quiz_results').add({
      'uid': uid,
      'subject': subject,
      'grade': grade,
      'score': score,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'timeTaken': timeTaken,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Future<List<Map<String, dynamic>>> getUserQuizHistory(
      String uid) async {
    final query = await _db
        .collection('quiz_results')
        .where('uid', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .get();

    return query.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  // ═══════════════════════════════════════════
  // LEADERBOARD
  // ═══════════════════════════════════════════

  static Future<List<UserModel>> getLeaderboard({int limit = 10}) async {
    final query = await _db
        .collection('users')
        .orderBy('totalPoints', descending: true)
        .limit(limit)
        .get();

    return query.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
  }

  // ═══════════════════════════════════════════
  // SEED DATA (untuk testing)
  // ═══════════════════════════════════════════

  static Future<void> seedQuestions() async {
    final batch = _db.batch();

    for (final question in _sampleQuestions) {
      final ref = _db.collection('questions').doc();
      batch.set(ref, question);
    }

    await batch.commit();
  }

  static String _handleAuthError(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'Email sudah digunakan';
        case 'weak-password':
          return 'Password terlalu lemah';
        case 'user-not-found':
          return 'Akun tidak ditemukan';
        case 'wrong-password':
          return 'Password salah';
        default:
          return 'Terjadi kesalahan: ${e.message}';
      }
    }
    return 'Terjadi kesalahan';
  }

  // Sample questions data
  static final List<Map<String, dynamic>> _sampleQuestions = [
    // MATEMATIKA - Kelas 1
    {
      'subject': 'matematika',
      'grade': '1',
      'question': 'Berapa hasil dari 5 + 3?',
      'options': ['6', '7', '8', '9'],
      'correctIndex': 2,
      'explanation': '5 + 3 = 8. Hitung dengan jari: 5 lalu tambah 3!',
      'points': 10,
      'difficulty': 'easy',
    },
    {
      'subject': 'matematika',
      'grade': '1',
      'question': 'Berapa hasil dari 10 - 4?',
      'options': ['5', '6', '7', '8'],
      'correctIndex': 1,
      'explanation': '10 - 4 = 6. Mulai dari 10, kurangi 4 langkah.',
      'points': 10,
      'difficulty': 'easy',
    },
    {
      'subject': 'matematika',
      'grade': '1',
      'question': 'Angka manakah yang lebih besar?',
      'options': ['7', '5', '3', '9'],
      'correctIndex': 3,
      'explanation': '9 adalah angka terbesar di antara 7, 5, 3, dan 9.',
      'points': 10,
      'difficulty': 'easy',
    },
    // MATEMATIKA - Kelas 2
    {
      'subject': 'matematika',
      'grade': '2',
      'question': 'Berapa hasil dari 15 + 27?',
      'options': ['40', '41', '42', '43'],
      'correctIndex': 2,
      'explanation':
          '15 + 27 = 42. Hitung puluhan dulu: 10+20=30, lalu satuan: 5+7=12, total 30+12=42',
      'points': 15,
      'difficulty': 'medium',
    },
    {
      'subject': 'matematika',
      'grade': '2',
      'question':
          'Budi punya 24 kelereng. Dia memberi 8 kelereng ke Ali. Berapa kelereng Budi sekarang?',
      'options': ['14', '16', '18', '32'],
      'correctIndex': 1,
      'explanation': '24 - 8 = 16 kelereng',
      'points': 15,
      'difficulty': 'medium',
    },
    // MATEMATIKA - Kelas 3
    {
      'subject': 'matematika',
      'grade': '3',
      'question': 'Berapa hasil dari 7 × 8?',
      'options': ['54', '56', '58', '64'],
      'correctIndex': 1,
      'explanation': '7 × 8 = 56. Ingat perkalian 7: 7,14,21,28,35,42,49,56',
      'points': 20,
      'difficulty': 'medium',
    },
    {
      'subject': 'matematika',
      'grade': '3',
      'question': 'Berapa hasil dari 48 ÷ 6?',
      'options': ['6', '7', '8', '9'],
      'correctIndex': 2,
      'explanation': '48 ÷ 6 = 8, karena 6 × 8 = 48',
      'points': 20,
      'difficulty': 'medium',
    },
    // BAHASA INDONESIA - Kelas 1
    {
      'subject': 'bahasa',
      'grade': '1',
      'question': 'Huruf kapital digunakan untuk...',
      'options': [
        'Semua kata',
        'Awal kalimat dan nama',
        'Akhir kalimat',
        'Kata kerja saja'
      ],
      'correctIndex': 1,
      'explanation':
          'Huruf kapital digunakan di awal kalimat dan untuk nama orang, kota, dll.',
      'points': 10,
      'difficulty': 'easy',
    },
    {
      'subject': 'bahasa',
      'grade': '1',
      'question': 'Kata "berlari" termasuk kata...',
      'options': ['Benda', 'Sifat', 'Kerja', 'Keterangan'],
      'correctIndex': 2,
      'explanation':
          'Berlari adalah kata kerja karena menyatakan perbuatan/aktivitas.',
      'points': 10,
      'difficulty': 'easy',
    },
    // BAHASA INDONESIA - Kelas 2
    {
      'subject': 'bahasa',
      'grade': '2',
      'question': 'Kalimat yang menyatakan pertanyaan diakhiri dengan tanda...',
      'options': ['Titik (.)', 'Koma (,)', 'Tanya (?)', 'Seru (!)'],
      'correctIndex': 2,
      'explanation': 'Kalimat tanya diakhiri dengan tanda tanya (?)',
      'points': 10,
      'difficulty': 'easy',
    },
    // IPA - Kelas 2
    {
      'subject': 'ipa',
      'grade': '2',
      'question': 'Hewan yang dapat terbang adalah...',
      'options': ['Ikan', 'Kucing', 'Burung', 'Kambing'],
      'correctIndex': 2,
      'explanation': 'Burung memiliki sayap sehingga dapat terbang.',
      'points': 10,
      'difficulty': 'easy',
    },
    {
      'subject': 'ipa',
      'grade': '2',
      'question':
          'Apa yang dibutuhkan tanaman untuk membuat makanannya sendiri?',
      'options': [
        'Air saja',
        'Tanah dan air',
        'Sinar matahari, air, dan karbon dioksida',
        'Pupuk saja'
      ],
      'correctIndex': 2,
      'explanation':
          'Tanaman melakukan fotosintesis menggunakan sinar matahari, air, dan CO2.',
      'points': 15,
      'difficulty': 'medium',
    },
    // IPA - Kelas 3
    {
      'subject': 'ipa',
      'grade': '3',
      'question': 'Planet yang paling dekat dengan Matahari adalah...',
      'options': ['Venus', 'Bumi', 'Merkurius', 'Mars'],
      'correctIndex': 2,
      'explanation':
          'Merkurius adalah planet terdekat dari Matahari di tata surya kita.',
      'points': 20,
      'difficulty': 'medium',
    },
    {
      'subject': 'ipa',
      'grade': '3',
      'question': 'Proses perubahan air menjadi uap disebut...',
      'options': ['Kondensasi', 'Evaporasi', 'Presipitasi', 'Infiltrasi'],
      'correctIndex': 1,
      'explanation': 'Evaporasi adalah proses penguapan air menjadi uap air.',
      'points': 20,
      'difficulty': 'medium',
    },
    // IPS - Kelas 3
    {
      'subject': 'ips',
      'grade': '3',
      'question': 'Ibu kota Indonesia adalah...',
      'options': ['Bandung', 'Surabaya', 'Jakarta', 'Medan'],
      'correctIndex': 2,
      'explanation':
          'Jakarta adalah ibu kota Indonesia (saat ini masih Jakarta).',
      'points': 10,
      'difficulty': 'easy',
    },
    {
      'subject': 'ips',
      'grade': '3',
      'question': 'Semboyan negara Indonesia adalah...',
      'options': [
        'Bhineka Tunggal Ika',
        'Pancasila',
        'Garuda Pancasila',
        'Merah Putih'
      ],
      'correctIndex': 0,
      'explanation':
          'Bhinneka Tunggal Ika artinya "Berbeda-beda tetapi tetap satu jua".',
      'points': 10,
      'difficulty': 'easy',
    },
  ];
}
