// lib/screens/profile/profile_screen.dart

import 'package:edu_kids_app/services/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../utils/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final uid = context.read<AuthProvider>().firebaseUser?.uid;
    if (uid != null) {
      try {
        final history = await FirebaseService.getUserQuizHistory(uid);
        setState(() {
          _history = history;
          _loadingHistory = false;
        });
      } catch (_) {
        setState(() => _loadingHistory = false);
      }
    } else {
      setState(() => _loadingHistory = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.userModel;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Profile Header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.primary,
            actions: [
              IconButton(
                onPressed: () => _showLogoutDialog(context, auth),
                icon: const Icon(Icons.logout, color: Colors.white),
              ),
            ],
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Avatar
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          AppConstants
                                  .avatarEmojis[user?.avatarId ?? 'avatar_1'] ??
                              '🦁',
                          style: const TextStyle(fontSize: 64),
                        ),
                      )
                          .animate()
                          .scale(duration: 500.ms, curve: Curves.elasticOut),

                      const SizedBox(height: 12),

                      Text(
                        user?.username ?? 'Anak Pintar',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${user?.levelTitle ?? "Pemula"} • Level ${user?.level ?? 1}',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // XP bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('XP: ${user?.currentLevelXP ?? 0}/100',
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 12)),
                                Text('⭐ ${user?.totalPoints ?? 0}',
                                    style: const TextStyle(
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.w700)),
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
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats Row
                Row(
                  children: [
                    _ProfileStat(
                        emoji: '🔥',
                        label: 'Streak',
                        value: '${user?.streakDays ?? 0} hari'),
                    const SizedBox(width: 12),
                    _ProfileStat(
                        emoji: '🎖️',
                        label: 'Lencana',
                        value: '${user?.badges.length ?? 0}'),
                    const SizedBox(width: 12),
                    _ProfileStat(
                        emoji: '📝',
                        label: 'Kuis',
                        value: '${_history.length}'),
                  ],
                ).animate().slideX(begin: -0.2).fadeIn(),

                const SizedBox(height: 24),

                // Subject Progress
                Text('Progress per Mata Pelajaran',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),

                ...AppConstants.subjects.map((subject) {
                  final points = user?.subjectProgress[subject['id']] ?? 0;
                  final color = subject['color'] as Color;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8)
                        ],
                      ),
                      child: Row(
                        children: [
                          Text(subject['emoji'],
                              style: const TextStyle(fontSize: 28)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(subject['name'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                LinearProgressIndicator(
                                  value: (points / 200.0).clamp(0.0, 1.0),
                                  backgroundColor: color.withOpacity(0.15),
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(color),
                                  minHeight: 8,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$points pts',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: color,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 24),

                // Recent Quiz History
                Text('Riwayat Kuis Terakhir',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),

                if (_loadingHistory)
                  const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary))
                else if (_history.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      children: [
                        Text('📚', style: TextStyle(fontSize: 40)),
                        SizedBox(height: 8),
                        Text('Belum ada riwayat kuis',
                            style: TextStyle(color: Colors.grey)),
                        Text('Yuk mulai belajar!',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                else
                  ..._history.take(5).map((result) {
                    final subjectData = AppConstants.subjects.firstWhere(
                      (s) => s['id'] == result['subject'],
                      orElse: () => AppConstants.subjects.first,
                    );
                    final accuracy = ((result['correctAnswers'] ?? 0) /
                            (result['totalQuestions'] ?? 1) *
                            100)
                        .toInt();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 6)
                        ],
                      ),
                      child: Row(
                        children: [
                          Text(subjectData['emoji'],
                              style: const TextStyle(fontSize: 28)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(subjectData['name'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                                Text('Kelas ${result['grade']}',
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${result['score']} pts',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary),
                              ),
                              Text('$accuracy% benar',
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 24),
                Text('Pengaturan Suara',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),

                StatefulBuilder(
                  builder: (context, setLocalState) => Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8)
                      ],
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('🎵 Musik Latar',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: const Text('Musik background saat bermain'),
                          value: AudioService.isBgmEnabled,
                          activeColor: AppColors.primary,
                          onChanged: (_) async {
                            await AudioService.toggleBgm();
                            if (AudioService.isBgmEnabled) {
                              await AudioService.playHomeBgm();
                            }
                            setLocalState(() {});
                          },
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('🔊 Efek Suara',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          subtitle:
                              const Text('Suara benar, salah, dan notifikasi'),
                          value: AudioService.isSfxEnabled,
                          activeColor: AppColors.primary,
                          onChanged: (_) async {
                            await AudioService.toggleSfx();
                            setLocalState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar? 😢',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Kamu yakin mau keluar dari EduKids?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              auth.logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;

  const _ProfileStat({
    required this.emoji,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)
          ],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 4),
            Text(value,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
