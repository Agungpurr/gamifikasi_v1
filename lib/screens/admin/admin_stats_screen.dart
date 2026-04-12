// lib/screens/admin/admin_stats_screen.dart

import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import '../../services/export_service.dart';
import 'package:intl/intl.dart';
import '../../services/audio_service.dart';

class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  bool _loading = true;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  bool _exportingRealtime = false;
  Map<String, dynamic> _stats = {};
  String _selectedKelas = 'Semua Kelas';
  List<String> _kelasList = ['Semua Kelas'];

  @override
  void initState() {
    super.initState();
    _load();
    _loadKelas();
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
      // _exportRealtime
      await ExportService.exportUsersPdf(
        context,
        kelas: _selectedKelas,
      );
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

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _exportRealtime() async {
    if (_startDate.isAfter(_endDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tanggal mulai tidak boleh setelah tanggal akhir')),
      );
      return;
    }
    setState(() => _exportingRealtime = true);
    try {
      await ExportService.exportRealtimePdf(
        context,
        startDate: _startDate,
        endDate: _endDate,
        kelas: _selectedKelas,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal export: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _exportingRealtime = false);
    }
  }

  Future<void> _loadKelas() async {
    final list = await AdminService.getAvailableKelas();
    setState(() {
      _kelasList = ['Semua Kelas', ...list];
    });
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
            // Dropdown Kelas
            Row(
              children: [
                const Text('Kelas:',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedKelas,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                    items: _kelasList
                        .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedKelas = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 12),
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

            // ── Export Realtime ──
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Export Hasil Quiz Realtime',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Filter berdasarkan tanggal quiz',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _pickStartDate,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today,
                                      size: 16, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Dari',
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey[500])),
                                      Text(
                                        DateFormat('dd MMM yyyy', 'id_ID')
                                            .format(_startDate),
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child:
                              Text('—', style: TextStyle(color: Colors.grey)),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: _pickEndDate,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today,
                                      size: 16, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Sampai',
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey[500])),
                                      Text(
                                        DateFormat('dd MMM yyyy', 'id_ID')
                                            .format(_endDate),
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _exportingRealtime ? null : _exportRealtime,
                        icon: _exportingRealtime
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.picture_as_pdf),
                        label: Text(_exportingRealtime
                            ? 'Menyiapkan PDF...'
                            : 'Export PDF Hasil Quiz'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
                    label: 'Level',
                    value: '12',
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
            // Setelah widget Top 5 User Terbaik, tambahkan:

            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pengaturan Suara',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    StatefulBuilder(
                      builder: (context, setLocalState) => Column(
                        children: [
                          SwitchListTile(
                            title: const Text('🎵 Musik Latar',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                            subtitle:
                                const Text('Musik background saat bermain'),
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
                            subtitle: const Text(
                                'Suara benar, salah, dan notifikasi'),
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
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
