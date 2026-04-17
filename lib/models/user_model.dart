class UserModel {
  final String uid;
  final String username;
  final String avatarId;
  final int totalPoints;
  final int level;
  final int streakDays;
  final Map<String, int> subjectProgress;
  final List<String> badges;
  final DateTime lastLoginDate;
  final DateTime createdAt;
  final String? nisn;
  final String? kelas;

  // ✅ Field baru untuk Daily Challenge
  final int dailyChallengeCount;
  final bool dailyChallengeBonused;
  final DateTime? lastChallengeDate;

  UserModel({
    required this.uid,
    required this.username,
    required this.avatarId,
    this.totalPoints = 0,
    this.level = 1,
    this.streakDays = 0,
    this.subjectProgress = const {},
    this.badges = const [],
    required this.lastLoginDate,
    required this.createdAt,
    this.nisn,
    this.kelas,
    // ✅ Field baru — default aman untuk user lama di Firestore
    this.dailyChallengeCount = 0,
    this.dailyChallengeBonused = false,
    this.lastChallengeDate,
  });

  int get xpForCurrentLevel => (level - 1) * 100;
  int get xpForNextLevel => level * 100;
  int get currentLevelXP => totalPoints - xpForCurrentLevel;
  double get levelProgress => currentLevelXP / 100.0;

  String get levelTitle {
    if (level <= 3) return 'Pemula';
    if (level <= 6) return 'Pelajar';
    if (level <= 9) return 'Mahir';
    if (level <= 12) return 'Ahli';
    return 'Juara';
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      username: map['username'] ?? 'Anak Pintar',
      avatarId: map['avatarId'] ?? 'avatar_1',
      totalPoints: map['totalPoints'] ?? 0,
      level: map['level'] ?? 1,
      streakDays: map['streakDays'] ?? 0,
      subjectProgress: Map<String, int>.from(map['subjectProgress'] ?? {}),
      badges: List<String>.from(map['badges'] ?? []),
      lastLoginDate: map['lastLoginDate'] != null
          ? DateTime.parse(map['lastLoginDate'])
          : DateTime.now(),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      nisn: map['nisn'],
      kelas: map['kelas'],
      // ✅ Parse field baru — null-safe, user lama otomatis dapat default
      dailyChallengeCount: map['dailyChallengeCount'] ?? 0,
      dailyChallengeBonused: map['dailyChallengeBonused'] ?? false,
      lastChallengeDate: map['lastChallengeDate'] != null
          ? DateTime.tryParse(map['lastChallengeDate'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'avatarId': avatarId,
      'totalPoints': totalPoints,
      'level': level,
      'streakDays': streakDays,
      'subjectProgress': subjectProgress,
      'badges': badges,
      'lastLoginDate': lastLoginDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'nisn': nisn,
      'kelas': kelas,
      // ✅ Simpan ke Firestore
      'dailyChallengeCount': dailyChallengeCount,
      'dailyChallengeBonused': dailyChallengeBonused,
      'lastChallengeDate': lastChallengeDate?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? username,
    String? avatarId,
    int? totalPoints,
    int? level,
    int? streakDays,
    Map<String, int>? subjectProgress,
    List<String>? badges,
    DateTime? lastLoginDate,
    String? nisn,
    String? kelas,
    // ✅ Field baru di copyWith
    int? dailyChallengeCount,
    bool? dailyChallengeBonused,
    DateTime? lastChallengeDate,
  }) {
    return UserModel(
      uid: uid,
      username: username ?? this.username,
      avatarId: avatarId ?? this.avatarId,
      totalPoints: totalPoints ?? this.totalPoints,
      level: level ?? this.level,
      streakDays: streakDays ?? this.streakDays,
      subjectProgress: subjectProgress ?? this.subjectProgress,
      badges: badges ?? this.badges,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      createdAt: createdAt,
      nisn: nisn ?? this.nisn,
      kelas: kelas ?? this.kelas,
      // ✅
      dailyChallengeCount: dailyChallengeCount ?? this.dailyChallengeCount,
      dailyChallengeBonused:
          dailyChallengeBonused ?? this.dailyChallengeBonused,
      lastChallengeDate: lastChallengeDate ?? this.lastChallengeDate,
    );
  }
}
