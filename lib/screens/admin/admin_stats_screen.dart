// lib/screens/admin/admin_stats_screen.dart

import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import '../../services/export_service.dart';

class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  bool _loading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final stats = await AdminService.getDashboardStats();
    if (mounted)
      setState(() {
        _stats = stats;
        _loading = false;
      });
  }

  Future<void> _exportPdf() async {
    try {
      await ExportService.exportUsersPdf(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal export PDF: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exportExcel() async {
    try {
      // Tampilkan loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Menyiapkan file Excel...')),
        );
      }
      await ExportService.exportUsersExcel(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal export Excel: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalUsers = _stats['totalUsers'] ?? 0;
    final totalQuestions = _stats['totalQuestions'] ?? 0;
    final bySubject = Map<String, int>.from(_stats['questionsBySubject'] ?? {});
    final topUsers = List<UserModel>.from(_stats['topUsers'] ?? []);

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dashboard',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text('Ringkasan data aplikasi',
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _exportPdf,
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                    label: const Text('Export PDF',
                        style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _exportExcel,
                    icon: const Icon(Icons.table_chart, color: Colors.green),
                    label: const Text('Export Excel',
                        style: TextStyle(color: Colors.green)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.green),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Stat cards
            LayoutBuilder(builder: (ctx, constraints) {
              final cols = constraints.maxWidth > 600 ? 4 : 2;
              return GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: [
                  _StatCard(
                    label: 'Total User',
                    value: '$totalUsers',
                    icon: Icons.people,
                    color: AppColors.primary,
                  ),
                  _StatCard(
                    label: 'Total Soal',
                    value: '$totalQuestions',
                    icon: Icons.quiz,
                    color: AppColors.success,
                  ),
                  _StatCard(
                    label: 'Mata Pelajaran',
                    value: '${bySubject.length}',
                    icon: Icons.book,
                    color: AppColors.accent,
                  ),
                  _StatCard(
                    label: 'Kelas',
                    value: '6',
                    icon: Icons.school,
                    color: AppColors.secondary,
                  ),
                ],
              );
            }),
            const SizedBox(height: 24),

            // Soal per mapel
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Soal per Mata Pelajaran',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    if (bySubject.isEmpty)
                      const Text('Belum ada soal',
                          style: TextStyle(color: Colors.grey))
                    else
                      ...bySubject.entries.map((e) => _SubjectBar(
                            subject: e.key,
                            count: e.value,
                            total: totalQuestions,
                          )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Top users
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Top 5 User Terbaik',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    if (topUsers.isEmpty)
                      const Text('Belum ada user',
                          style: TextStyle(color: Colors.grey))
                    else
                      ...topUsers.asMap().entries.map((e) => _TopUserTile(
                            rank: e.key + 1,
                            user: e.value,
                          )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
                Text(label,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectBar extends StatelessWidget {
  final String subject;
  final int count;
  final int total;

  const _SubjectBar(
      {required this.subject, required this.count, required this.total});

  Color get _color {
    switch (subject) {
      case 'matematika':
        return AppColors.math;
      case 'bahasa':
        return AppColors.bahasa;
      case 'ipa':
        return AppColors.ipa;
      case 'ips':
        return AppColors.ips;
      default:
        return Colors.grey;
    }
  }

  String get _label {
    switch (subject) {
      case 'matematika':
        return 'Matematika';
      case 'bahasa':
        return 'B. Indonesia';
      case 'ipa':
        return 'IPA';
      case 'ips':
        return 'IPS';
      default:
        return subject;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? count / total : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_label, style: const TextStyle(fontSize: 13)),
              Text('$count soal',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: pct,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(_color),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}

class _TopUserTile extends StatelessWidget {
  final int rank;
  final UserModel user;

  const _TopUserTile({required this.rank, required this.user});

  @override
  Widget build(BuildContext context) {
    final rankColors = [
      AppColors.accent,
      Colors.grey[400]!,
      const Color(0xFFCD7F32),
    ];
    final color = rank <= 3 ? rankColors[rank - 1] : Colors.grey[300]!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Center(
              child: Text('$rank',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.white)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(user.username,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Text('Lv.${user.level}',
              style: TextStyle(fontSize: 12, color: AppColors.primary)),
          const SizedBox(width: 12),
          Text('${user.totalPoints} poin',
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
