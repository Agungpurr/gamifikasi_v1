// lib/screens/admin/admin_users_screen.dart

import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<UserModel> _users = [];
  List<UserModel> _filtered = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  String? _filterKelas;
  String _searchMode = 'nama'; // 'nama' | 'nisn'
  bool _sortAZ = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final users = await AdminService.getAllUsers();
    if (mounted) {
      setState(() {
        _users = users;
        _filtered = users;
        _loading = false;
      });
    }
  }

  void _search(String query) {
    final q = query.toLowerCase();
    setState(() {
      var result = q.isEmpty
          ? _users
          : _users.where((u) {
              if (_searchMode == 'nisn') {
                return (u.nisn ?? '').toLowerCase().contains(q);
              }
              return u.username.toLowerCase().contains(q);
            }).toList();

      if (_filterKelas != null) {
        result = result.where((u) => u.kelas == _filterKelas).toList();
      }

      if (_sortAZ) {
        result.sort((a, b) => a.username.compareTo(b.username));
      }

      _filtered = result;
    });
  }

  void _openEditDialog(UserModel user) {
    final usernameCtrl = TextEditingController(text: user.username);
    final nisnCtrl = TextEditingController(text: user.nisn ?? '');

    final kelasList = [
      for (int i = 1; i <= 6; i++)
        for (final sub in ['A', 'B', 'C']) '$i$sub'
    ];

    String? selectedKelas =
        (user.kelas != null && kelasList.contains(user.kelas))
            ? user.kelas
            : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Edit User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: usernameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nisnCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  decoration: const InputDecoration(
                    labelText: 'NISN',
                    prefixIcon: Icon(Icons.badge_outlined),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedKelas,
                  decoration: const InputDecoration(
                    labelText: 'Kelas',
                    prefixIcon: Icon(Icons.class_outlined),
                  ),
                  items: kelasList
                      .map((k) =>
                          DropdownMenuItem(value: k, child: Text('Kelas $k')))
                      .toList(),
                  onChanged: (val) => setStateDialog(() => selectedKelas = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                await AdminService.updateUser(user.uid, {
                  'username': usernameCtrl.text.trim(),
                  'nisn': nisnCtrl.text.trim(),
                  'kelas': selectedKelas ?? '',
                });
                if (mounted) Navigator.pop(ctx);
                _load();
                _showSnack('User berhasil diperbarui');
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _openCreateDialog() {
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final nisnCtrl = TextEditingController();
    final adminEmailCtrl = TextEditingController();
    final adminPasswordCtrl = TextEditingController();
    bool isLoading = false;

    final kelasList = [
      for (int i = 1; i <= 6; i++)
        for (final sub in ['A', 'B', 'C']) '$i$sub'
    ];
    String? selectedKelas;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Tambah User Baru'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Data siswa
                const Text('Data Siswa',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.grey)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: usernameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Siswa',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: nisnCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  decoration: const InputDecoration(
                    labelText: 'NISN',
                    prefixIcon: Icon(Icons.badge_outlined),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedKelas,
                  decoration: const InputDecoration(
                    labelText: 'Kelas',
                    prefixIcon: Icon(Icons.class_outlined),
                  ),
                  items: kelasList
                      .map((k) =>
                          DropdownMenuItem(value: k, child: Text('Kelas $k')))
                      .toList(),
                  onChanged: (val) => setStateDialog(() => selectedKelas = val),
                ),
                const SizedBox(height: 16),

                // Akun login siswa
                const Text('Akun Login Siswa',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.grey)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password (min. 6 karakter)',
                    prefixIcon: Icon(Icons.lock_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                // Konfirmasi identitas admin
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(Icons.info_outline,
                            size: 14, color: Colors.orange),
                        SizedBox(width: 6),
                        Text('Konfirmasi akun admin',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange)),
                      ]),
                      const SizedBox(height: 4),
                      const Text(
                        'Diperlukan agar admin tidak ter-logout',
                        style: TextStyle(fontSize: 11, color: Colors.orange),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: adminEmailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Admin',
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: adminPasswordCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password Admin',
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (usernameCtrl.text.trim().isEmpty ||
                          emailCtrl.text.trim().isEmpty ||
                          passwordCtrl.text.isEmpty ||
                          adminEmailCtrl.text.trim().isEmpty ||
                          adminPasswordCtrl.text.isEmpty ||
                          selectedKelas == null) {
                        _showSnack('Semua field wajib diisi');
                        return;
                      }
                      if (passwordCtrl.text.length < 6) {
                        _showSnack('Password minimal 6 karakter');
                        return;
                      }

                      setStateDialog(() => isLoading = true);
                      try {
                        await AdminService.createUser(
                          adminEmail: adminEmailCtrl.text.trim(),
                          adminPassword: adminPasswordCtrl.text,
                          newEmail: emailCtrl.text.trim(),
                          newPassword: passwordCtrl.text,
                          username: usernameCtrl.text.trim(),
                          nisn: nisnCtrl.text.trim(),
                          kelas: selectedKelas!,
                        );
                        if (mounted) Navigator.pop(ctx);
                        _load();
                        _showSnack('User berhasil dibuat');
                      } catch (e) {
                        setStateDialog(() => isLoading = false);
                        _showSnack('Gagal: ${e.toString()}');
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Buat Akun'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteUser(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus User'),
        content: Text(
            'Hapus "${user.username}"? Tindakan ini tidak bisa dibatalkan.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await AdminService.deleteUser(user.uid);
      _load();
      _showSnack('User dihapus');
    }
  }

  Future<void> _resetProgress(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Progress'),
        content: Text('Reset semua poin dan badge "${user.username}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await AdminService.resetUserProgress(user.uid);
      _load();
      _showSnack('Progress user direset');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            onChanged: _search,
            decoration: InputDecoration(
              hintText:
                  _searchMode == 'nisn' ? 'Cari NISN...' : 'Cari nama user...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        _search('');
                      },
                    )
                  : null,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              // Dropdown mode pencarian
              DropdownButton<String>(
                value: _searchMode,
                underline: const SizedBox(),
                isDense: true,
                items: const [
                  DropdownMenuItem(value: 'nama', child: Text('Nama')),
                  DropdownMenuItem(value: 'nisn', child: Text('NISN')),
                ],
                onChanged: (val) {
                  setState(() {
                    _searchMode = val!;
                    _searchCtrl.clear();
                  });
                  _search('');
                },
              ),
              const SizedBox(width: 12),

              // Dropdown filter kelas
              DropdownButton<String?>(
                value: _filterKelas,
                hint: const Text('Semua Kelas'),
                underline: const SizedBox(),
                isDense: true,
                items: [
                  const DropdownMenuItem(
                      value: null, child: Text('Semua Kelas')),
                  ...[
                    for (int i = 1; i <= 6; i++)
                      for (final sub in ['A', 'B', 'C']) '$i$sub'
                  ].map((k) =>
                      DropdownMenuItem(value: k, child: Text('Kelas $k'))),
                ],
                onChanged: (val) {
                  setState(() => _filterKelas = val);
                  _search(_searchCtrl.text);
                },
              ),
              const SizedBox(width: 12),

              // Toggle sort A-Z
              FilterChip(
                label: const Text('A-Z'),
                selected: _sortAZ,
                onSelected: (val) {
                  setState(() => _sortAZ = val);
                  _search(_searchCtrl.text);
                },
              ),
            ],
          ),
        ),
        // Counter + tombol tambah user
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_filtered.length} user',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _openCreateDialog,
                    icon: const Icon(Icons.person_add, size: 16),
                    label: const Text('Tambah User'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? const Center(
                      child: Text('Tidak ada user ditemukan',
                          style: TextStyle(color: Colors.grey)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _filtered.length,
                        itemBuilder: (ctx, i) => _UserCard(
                          user: _filtered[i],
                          onEdit: () => _openEditDialog(_filtered[i]),
                          onDelete: () => _deleteUser(_filtered[i]),
                          onReset: () => _resetProgress(_filtered[i]),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReset;

  const _UserCard({
    required this.user,
    required this.onEdit,
    required this.onDelete,
    required this.onReset,
  });

  String get _levelTitle {
    if (user.level <= 3) return 'Pemula';
    if (user.level <= 6) return 'Pelajar';
    if (user.level <= 9) return 'Mahir';
    if (user.level <= 12) return 'Ahli';
    return 'Juara';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      user.username.isNotEmpty
                          ? user.username[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.username,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      Row(
                        children: [
                          _Chip('Lv.${user.level} $_levelTitle',
                              AppColors.primary),
                          const SizedBox(width: 6),
                          _Chip('🔥 ${user.streakDays} hari', Colors.orange),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (val) {
                    if (val == 'edit') onEdit();
                    if (val == 'reset') onReset();
                    if (val == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit')
                        ])),
                    const PopupMenuItem(
                        value: 'reset',
                        child: Row(children: [
                          Icon(Icons.restart_alt,
                              size: 18, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Reset Progress')
                        ])),
                    const PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Hapus', style: TextStyle(color: Colors.red))
                        ])),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                _InfoItem(Icons.star, '${user.totalPoints} poin'),
                const SizedBox(width: 20),
                _InfoItem(Icons.military_tech, '${user.badges.length} badge'),
                const SizedBox(width: 20),
                _InfoItem(Icons.book, '${user.subjectProgress.length} mapel'),
              ],
            ),
            if (user.kelas != null || user.nisn != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  if (user.kelas != null && user.kelas!.isNotEmpty)
                    _InfoItem(Icons.class_outlined, 'Kelas ${user.kelas}'),
                  if (user.kelas != null &&
                      user.kelas!.isNotEmpty &&
                      user.nisn != null &&
                      user.nisn!.isNotEmpty)
                    const SizedBox(width: 16),
                  if (user.nisn != null && user.nisn!.isNotEmpty)
                    _InfoItem(Icons.badge_outlined, 'NISN: ${user.nisn}'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoItem(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
