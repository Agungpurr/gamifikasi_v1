// lib/screens/auth/register_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_provider.dart';
import '../../../utils/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  String _selectedAvatar = 'avatar_1';
  String _selectedGrade = '3';
  int _step = 0;

  final List<String> _gradeTitles = [
    'Kelas 1',
    'Kelas 2',
    'Kelas 3',
    'Kelas 4',
    'Kelas 5',
    'Kelas 6'
  ];

  Future<void> _register() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      username: _usernameController.text.trim(),
      avatarId: _selectedAvatar,
      grade: _selectedGrade,
    );
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Pendaftaran gagal'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else if (success && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF6584), Color(0xFFF8F7FF)],
            stops: [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  ),
                ),

                const Text('🌟', style: TextStyle(fontSize: 64))
                    .animate()
                    .scale(duration: 500.ms, curve: Curves.elasticOut),
                const SizedBox(height: 8),
                Text(
                  'Buat Akun Baru!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Langkah ${_step + 1} dari 2',
                  style: const TextStyle(color: Colors.white70),
                ),

                const SizedBox(height: 30),

                if (_step == 0) _buildStep1() else _buildStep2(auth),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Pilih Avatarmu! 🎭',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Avatar Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: AppConstants.avatarEmojis.length,
              itemBuilder: (context, index) {
                final avatarId = 'avatar_${index + 1}';
                final emoji = AppConstants.avatarEmojis[avatarId] ?? '😊';
                final isSelected = _selectedAvatar == avatarId;

                return GestureDetector(
                  onTap: () => setState(() => _selectedAvatar = avatarId),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.2)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            isSelected ? AppColors.primary : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 32)),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Name field
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Nama Kamu',
                prefixIcon:
                    Icon(Icons.person_rounded, color: AppColors.secondary),
              ),
            ),

            const SizedBox(height: 16),

            // Grade selection
            Text(
              'Kamu kelas berapa?',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(6, (i) {
                final grade = '${i + 1}';
                final isSelected = _selectedGrade == grade;
                return ChoiceChip(
                  label: Text('Kelas ${i + 1}'),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedGrade = grade),
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: () {
                if (_usernameController.text.isNotEmpty) {
                  setState(() => _step = 1);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
              ),
              child: const Text('Lanjut ➡️'),
            ),
          ],
        ),
      ),
    ).animate().slideY(begin: 0.3).fadeIn();
  }

  Widget _buildStep2(AuthProvider auth) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Data Akun 🔐',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email (orang tua)',
                prefixIcon: Icon(Icons.email_rounded, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password (min. 6 karakter)',
                prefixIcon: Icon(Icons.lock_rounded, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: auth.isLoading ? null : _register,
              child: auth.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Daftar Sekarang! 🚀'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() => _step = 0),
              child: const Text('← Kembali'),
            ),
          ],
        ),
      ),
    ).animate().slideY(begin: 0.3).fadeIn();
  }
}
