// lib/screens/leaderboard/leaderboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../models/badge_model.dart';
import '../../services/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../utils/app_theme.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<UserModel> _leaders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    try {
      final leaders = await FirebaseService.getLeaderboard();
      setState(() {
        _leaders = leaders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = context.read<AuthProvider>().firebaseUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppColors.accent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.accent, Color(0xFFFF9F43)],
                  ),
                ),
                child: const SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🏆', style: TextStyle(fontSize: 60)),
                      SizedBox(height: 8),
                      Text(
                        'Papan Peringkat',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Siapa juaranya? 👑',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.accent)),
            )
          else if (_leaders.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🤔', style: TextStyle(fontSize: 64)),
                    SizedBox(height: 16),
                    Text('Belum ada data',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    Text('Jadilah yang pertama! 🚀',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final user = _leaders[index];
                    final rank = index + 1;
                    final isCurrentUser = user.uid == currentUid;

                    return _LeaderCard(
                      user: user,
                      rank: rank,
                      isCurrentUser: isCurrentUser,
                    )
                        .animate(delay: Duration(milliseconds: 50 * index))
                        .slideX(begin: 0.2)
                        .fadeIn();
                  },
                  childCount: _leaders.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LeaderCard extends StatelessWidget {
  final UserModel user;
  final int rank;
  final bool isCurrentUser;

  const _LeaderCard({
    required this.user,
    required this.rank,
    required this.isCurrentUser,
  });

  String get _rankEmoji {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '#$rank';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            isCurrentUser ? AppColors.primary.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCurrentUser
            ? Border.all(color: AppColors.primary, width: 2)
            : Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: rank <= 3
                ? Text(_rankEmoji,
                    style: const TextStyle(fontSize: 24),
                    textAlign: TextAlign.center)
                : Text(
                    '#$rank',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              AppConstants.avatarEmojis[user.avatarId] ?? '🦁',
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user.username,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color:
                            isCurrentUser ? AppColors.primary : Colors.black87,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Kamu',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
                Text(
                  'Level ${user.level} • ${user.levelTitle}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '⭐ ${user.totalPoints}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFE6A800),
                  fontSize: 16,
                ),
              ),
              Text(
                '${user.badges.length} lencana',
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════
// BADGES SCREEN
// ════════════════════════════════════════

// lib/screens/badges/badges_screen.dart

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;
    final earnedBadges = user?.badges ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lencana Saya 🎖️',
            style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Earned count
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.secondary, Color(0xFFFF9FB5)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Text('🎖️', style: TextStyle(fontSize: 40)),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Lencana Diperoleh',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 13)),
                      Text(
                        '${earnedBadges.length} / ${Badges.all.length}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Text('Semua Lencana',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: Badges.all.length,
              itemBuilder: (context, index) {
                final badge = Badges.all[index];
                final isEarned = earnedBadges.contains(badge.id);

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isEarned ? Colors.white : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isEarned ? AppColors.accent : Colors.grey.shade200,
                      width: isEarned ? 2 : 1,
                    ),
                    boxShadow: isEarned
                        ? [
                            BoxShadow(
                                color: AppColors.accent.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4))
                          ]
                        : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        badge.emoji,
                        style: TextStyle(
                          fontSize: 40,
                          color: isEarned ? null : Colors.transparent,
                          shadows: isEarned
                              ? null
                              : [
                                  Shadow(
                                      color: Colors.grey.shade400,
                                      blurRadius: 0)
                                ],
                        ),
                      ),
                      if (!isEarned)
                        const Text('🔒', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 8),
                      Text(
                        badge.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: isEarned ? Colors.black87 : Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        badge.description,
                        style: TextStyle(
                          fontSize: 11,
                          color: isEarned ? Colors.grey : Colors.grey.shade400,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                )
                    .animate(delay: Duration(milliseconds: 50 * index))
                    .scale(curve: Curves.elasticOut);
              },
            ),
          ],
        ),
      ),
    );
  }
}
