import 'package:edu_kids_app/models/user_model.dart';

class BadgeModel {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final String requirement;
  final int requiredCount; // ✅ target progress

  BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.requirement,
    this.requiredCount = 1, // default 1 untuk badge one-time
  });

  // ✅ Hitung progress user berdasarkan data userModel
  double getProgress(UserModel user) {
    switch (requirement) {
      case 'first_quiz':
        return user.badges.contains(id) ? 1.0 : 0.0;
      case 'perfect_score':
        return user.badges.contains(id) ? 1.0 : 0.0;
      case 'streak_3':
        return (user.streakDays / 3).clamp(0.0, 1.0);
      case 'streak_7':
        return (user.streakDays / 7).clamp(0.0, 1.0);
      case 'streak_30':
        return (user.streakDays / 30).clamp(0.0, 1.0);
      case 'streak_100':
        return (user.streakDays / 100).clamp(0.0, 1.0);
      case 'math_10':
        return ((user.subjectProgress['matematika'] ?? 0) / 100)
            .clamp(0.0, 1.0);
      case 'math_100':
        return ((user.subjectProgress['matematika'] ?? 0) / 1000)
            .clamp(0.0, 1.0);
      case 'bahasa_10':
        return ((user.subjectProgress['bahasa'] ?? 0) / 100).clamp(0.0, 1.0);
      case 'bahasa_100':
        return ((user.subjectProgress['bahasa'] ?? 0) / 1000).clamp(0.0, 1.0);
      case 'ipa_10':
        return ((user.subjectProgress['ipa'] ?? 0) / 100).clamp(0.0, 1.0);
      case 'ipa_100':
        return ((user.subjectProgress['ipa'] ?? 0) / 1000).clamp(0.0, 1.0);
      case 'ips_10':
        return ((user.subjectProgress['ips'] ?? 0) / 100).clamp(0.0, 1.0);
      case 'ips_100':
        return ((user.subjectProgress['ips'] ?? 0) / 1000).clamp(0.0, 1.0);
      case 'level_5':
        return (user.level / 5).clamp(0.0, 1.0);
      default:
        return 0.0;
    }
  }

  // ✅ Teks progress yang ditampilkan
  String getProgressText(UserModel user) {
    switch (requirement) {
      case 'streak_3':
        return '${user.streakDays.clamp(0, 3)} / 3 hari';
      case 'streak_7':
        return '${user.streakDays.clamp(0, 7)} / 7 hari';
      case 'streak_30':
        return '${user.streakDays.clamp(0, 30)} / 30 hari';
      case 'streak_100':
        return '${user.streakDays.clamp(0, 100)} / 100 hari';
      case 'math_10':
        final pts = user.subjectProgress['matematika'] ?? 0;
        return '${pts.clamp(0, 100)} / 100 pts';
      case 'math_100':
        final pts = user.subjectProgress['matematika'] ?? 0;
        return '${pts.clamp(0, 1000)} / 1000 pts';
      case 'bahasa_10':
        final pts = user.subjectProgress['bahasa'] ?? 0;
        return '${pts.clamp(0, 100)} / 100 pts';
      case 'bahasa_100':
        final pts = user.subjectProgress['bahasa'] ?? 0;
        return '${pts.clamp(0, 1000)} / 1000 pts';
      case 'ipa_10':
        final pts = user.subjectProgress['ipa'] ?? 0;
        return '${pts.clamp(0, 100)} / 100 pts';
      case 'ipa_100':
        final pts = user.subjectProgress['ipa'] ?? 0;
        return '${pts.clamp(0, 1000)} / 1000 pts';
      case 'ips_10':
        final pts = user.subjectProgress['ips'] ?? 0;
        return '${pts.clamp(0, 100)} / 100 pts';
      case 'ips_100':
        final pts = user.subjectProgress['ips'] ?? 0;
        return '${pts.clamp(0, 1000)} / 1000 pts';
      case 'level_5':
        return 'Level ${user.level.clamp(1, 5)} / 5';
      default:
        return user.badges.contains(id) ? 'Selesai! ✅' : 'Belum';
    }
  }
}

class Badges {
  static final List<BadgeModel> all = [
    BadgeModel(
        id: 'first_quiz',
        name: 'Pemula Berani',
        description: 'Selesaikan kuis pertama',
        emoji: '🌟',
        requirement: 'first_quiz'),
    BadgeModel(
        id: 'perfect_score',
        name: 'Bintang Sempurna',
        description: 'Dapatkan nilai 100 di satu quiz',
        emoji: '💯',
        requirement: 'perfect_score'),
    BadgeModel(
        id: 'streak_3',
        name: 'Konsisten 3 Hari',
        description: 'Belajar 3 hari berturut-turut',
        emoji: '🔥',
        requirement: 'streak_3',
        requiredCount: 3),
    BadgeModel(
        id: 'streak_7',
        name: 'Semangat Seminggu',
        description: 'Belajar 7 hari berturut-turut',
        emoji: '⚡',
        requirement: 'streak_7',
        requiredCount: 7),
    BadgeModel(
        id: 'streak_30',
        name: 'Semangat Sebulan',
        description: 'Belajar 30 hari berturut-turut',
        emoji: '🧑‍🏫',
        requirement: 'streak_30',
        requiredCount: 30),
    BadgeModel(
        id: 'streak_100',
        name: '100 Day Spirit',
        description: 'Belajar 100 hari berturut-turut',
        emoji: '📖',
        requirement: 'streak_100',
        requiredCount: 100),
    BadgeModel(
        id: 'math_master',
        name: 'Jago Matematika',
        description: 'Kumpulkan 100 pts Matematika',
        emoji: '🔢',
        requirement: 'math_10',
        requiredCount: 100),
    BadgeModel(
        id: 'math_expert',
        name: 'Master Matematika',
        description: 'Kumpulkan 1000 pts matematika',
        emoji: '🎲',
        requirement: 'math_100',
        requiredCount: 1000),
    BadgeModel(
        id: 'reading_hero',
        name: 'Pahlawan Membaca',
        description: 'Kumpulkan 100 pts Bahasa Indonesia',
        emoji: '📚',
        requirement: 'bahasa_10',
        requiredCount: 100),
    BadgeModel(
        id: 'expert_reading',
        name: 'Master Membaca',
        description: 'Kumpulkan 1000 pts bahasa',
        emoji: '🦉',
        requirement: 'bahasa_100',
        requiredCount: 1000),
    BadgeModel(
        id: 'science_wizard',
        name: 'Penyihir IPA',
        description: 'Kumpulkan 100 pts IPA',
        emoji: '🔬',
        requirement: 'ipa_10',
        requiredCount: 100),
    BadgeModel(
        id: 'sciece_expert',
        name: 'Penakluk IPA',
        description: 'Kumpulkan 1000 pts IPA',
        emoji: '🌏',
        requirement: 'ipa_100',
        requiredCount: 1000),
    BadgeModel(
        id: 'social_good',
        name: 'Pahlawan Sosial',
        description: 'Kumpulkan 100 pts IPS',
        emoji: '🎭',
        requirement: 'ips_10',
        requiredCount: 100),
    BadgeModel(
        id: 'social_expert',
        name: 'Pahlawan Hebat',
        description: 'Kumpulkan 1000 pts IPS',
        emoji: '🤹‍♀️',
        requirement: 'ips_100',
        requiredCount: 1000),
    BadgeModel(
        id: 'level_5',
        name: 'Naik Level',
        description: 'Capai level 5',
        emoji: '🏆',
        requirement: 'level_5',
        requiredCount: 5),
  ];
}
