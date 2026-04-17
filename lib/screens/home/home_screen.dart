// lib/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_provider.dart';
import '../../../models/user_model.dart';
import '../../../utils/app_theme.dart';
import 'package:edu_kids_app/screens/quiz/subject_select_screen.dart';
import 'package:edu_kids_app/screens/leaderboard/leaderboard_screen.dart';
import 'package:edu_kids_app/screens/profile/profile_screen.dart';
import 'package:edu_kids_app/screens/calendar/calendar_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _HomeTab(),
    const SubjectSelectScreen(),
    const LeaderboardScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: Colors.grey.shade400,
            selectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                  icon: Text('🏠', style: TextStyle(fontSize: 22)),
                  label: 'Beranda'),
              BottomNavigationBarItem(
                  icon: Text('📚', style: TextStyle(fontSize: 22)),
                  label: 'Belajar'),
              BottomNavigationBarItem(
                  icon: Text('🏆', style: TextStyle(fontSize: 22)),
                  label: 'Peringkat'),
              BottomNavigationBarItem(
                  icon: Text('👤', style: TextStyle(fontSize: 22)),
                  label: 'Profil'),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.userModel;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, Color(0xFF9B8FFF)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Halo, ${user?.username ?? "Anak Pintar"}! 👋',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '${user?.levelTitle ?? "Pemula"} • Level ${user?.level ?? 1}',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 14),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                AppConstants.avatarEmojis[
                                        user?.avatarId ?? 'avatar_1'] ??
                                    '🦁',
                                style: const TextStyle(fontSize: 36),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'XP: ${user?.currentLevelXP ?? 0} / 100',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12),
                                ),
                                Text(
                                  '⭐ ${user?.totalPoints ?? 0} poin',
                                  style: const TextStyle(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: (user?.levelProgress ?? 0).clamp(0.0, 1.0),
                              backgroundColor: Colors.white.withOpacity(0.3),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.accent),
                              minHeight: 10,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  children: [
                    _StatCard(
                      emoji: '🔥',
                      label: 'Streak',
                      value: '${user?.streakDays ?? 0} hari',
                      color: Colors.orange,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CalendarScreen()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      emoji: '🎖️',
                      label: 'Lencana',
                      value: '${user?.badges.length ?? 0}',
                      color: AppColors.secondary,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BadgesScreen()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      emoji: '📊',
                      label: 'Level',
                      value: '${user?.level ?? 1}',
                      color: AppColors.primary,
                    ),
                  ],
                ).animate().slideX(begin: -0.2).fadeIn(),

                const SizedBox(height: 24),

                Text(
                  'Mulai Belajar! 🚀',
                  style: Theme.of(context).textTheme.titleLarge,
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 12),

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: AppConstants.subjects.length,
                  itemBuilder: (context, index) {
                    final subject = AppConstants.subjects[index];
                    final progress = user?.subjectProgress[subject['id']] ?? 0;
                    return _SubjectCard(
                      subject: subject,
                      points: progress,
                    ).animate().scale(
                          delay: Duration(milliseconds: 100 * index),
                          duration: 300.ms,
                          curve: Curves.elasticOut,
                        );
                  },
                ),

                const SizedBox(height: 24),

                // ✅ Banner sekarang terima user untuk progress nyata
                _DailyChallengeBanner(user: user)
                    .animate()
                    .slideY(begin: 0.2, delay: 300.ms)
                    .fadeIn(),

                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 11, color: color.withOpacity(0.7)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final Map<String, dynamic> subject;
  final int points;

  const _SubjectCard({required this.subject, required this.points});

  @override
  Widget build(BuildContext context) {
    final color = subject['color'] as Color;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SubjectSelectScreen(initialSubject: subject['id']),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withOpacity(0.7)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subject['emoji'], style: const TextStyle(fontSize: 32)),
            const Spacer(),
            Text(
              subject['name'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '$points pts',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ Banner sekarang reactive — progress dots update otomatis setelah quiz
class _DailyChallengeBanner extends StatelessWidget {
  final UserModel? user;

  const _DailyChallengeBanner({this.user});

  // Hitung berapa kuis yang sudah selesai hari ini
  int get _todayCount {
    if (user == null) return 0;
    final lastDate = user!.lastChallengeDate;
    if (lastDate == null) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = DateTime(lastDate.year, lastDate.month, lastDate.day);

    // Jika lastChallengeDate bukan hari ini, reset ke 0
    return (last == today) ? user!.dailyChallengeCount.clamp(0, 3) : 0;
  }

  bool get _completed =>
      user?.dailyChallengeBonused == true && _todayCount >= 3;

  @override
  Widget build(BuildContext context) {
    final count = _todayCount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _completed
              ? [const Color(0xFF6BCB77), const Color(0xFF4CAF50)]
              : [const Color(0xFFFFD166), const Color(0xFFFF9F43)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                (_completed ? const Color(0xFF6BCB77) : const Color(0xFFFFD166))
                    .withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _completed ? '✅ Tantangan Selesai!' : '⚡ Tantangan Hari Ini!',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Selesaikan 3 kuis hari ini',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 10),

                // ✅ Progress dots — update realtime dari Firestore via AuthProvider
                Row(
                  children: List.generate(3, (i) {
                    final done = i < count;
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color:
                            done ? Colors.white : Colors.white.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          done ? '✓' : '${i + 1}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color:
                                done ? const Color(0xFFFF9F43) : Colors.white70,
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 8),
                Text(
                  _completed ? 'Bonus sudah diterima! 🎉' : '+50 XP Bonus! 🎁',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Text(
              _completed ? '🏆' : '🏅',
              style: const TextStyle(fontSize: 28),
            ),
          ),
        ],
      ),
    );
  }
}
