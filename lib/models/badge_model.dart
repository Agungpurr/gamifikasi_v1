class BadgeModel {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final String requirement;

  BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.requirement,
  });
}

// Predefined badges
class Badges {
  static final List<BadgeModel> all = [
    BadgeModel(
      id: 'first_quiz',
      name: 'Pemula Berani',
      description: 'Selesaikan kuis pertama',
      emoji: '🌟',
      requirement: 'first_quiz',
    ),
    BadgeModel(
      id: 'perfect_score',
      name: 'Bintang Sempurna',
      description: 'Dapatkan nilai 100 di satu quiz',
      emoji: '💯',
      requirement: 'perfect_score',
    ),
    BadgeModel(
      id: 'streak_3',
      name: 'Konsisten 3 Hari',
      description: 'Belajar 3 hari berturut-turut',
      emoji: '🔥',
      requirement: 'streak_3',
    ),
    BadgeModel(
      id: 'streak_7',
      name: 'Semangat Seminggu',
      description: 'Belajar 7 hari berturut-turut',
      emoji: '⚡',
      requirement: 'streak_7',
    ),
    BadgeModel(
      id: 'math_master',
      name: 'Jago Matematika',
      description: 'Selesaikan 10 soal matematika',
      emoji: '🔢',
      requirement: 'math_10',
    ),
    BadgeModel(
      id: 'reading_hero',
      name: 'Pahlawan Membaca',
      description: 'Selesaikan 10 soal bahasa Indonesia',
      emoji: '📚',
      requirement: 'bahasa_10',
    ),
    BadgeModel(
      id: 'science_wizard',
      name: 'Penyihir IPA',
      description: 'Selesaikan 10 soal IPA',
      emoji: '🔬',
      requirement: 'ipa_10',
    ),
    BadgeModel(
      id: 'level_5',
      name: 'Naik Level',
      description: 'Capai level 5',
      emoji: '🏆',
      requirement: 'level_5',
    ),
  ];
}
