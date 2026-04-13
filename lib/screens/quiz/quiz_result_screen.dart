// lib/screens/quiz/quiz_result_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import '../../utils/app_theme.dart';

class QuizResultScreen extends StatefulWidget {
  final int score;
  final int correctAnswers;
  final int totalQuestions;
  final String subject;
  final double nilai;

  const QuizResultScreen({
    super.key,
    required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.subject,
    required this.nilai,
  });

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    if (widget.correctAnswers == widget.totalQuestions) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  double get _percentage => widget.correctAnswers / widget.totalQuestions;

  String get _grade {
    if (_percentage >= 0.9) return 'A+';
    if (_percentage >= 0.8) return 'A';
    if (_percentage >= 0.7) return 'B';
    if (_percentage >= 0.6) return 'C';
    return 'D';
  }

  String get _message {
    if (_percentage >= 0.9) return 'Luar Biasa! Kamu Jenius! 🏆';
    if (_percentage >= 0.8) return 'Bagus Sekali! Terus Semangat! 🌟';
    if (_percentage >= 0.7) return 'Cukup Baik! Terus Belajar! 💪';
    if (_percentage >= 0.6) return 'Sudah Berusaha! Coba Lagi! 🤗';
    return 'Jangan Menyerah! Coba Lagi Yuk! 💖';
  }

  String get _emoji {
    if (_percentage >= 0.9) return '🏆';
    if (_percentage >= 0.8) return '🥇';
    if (_percentage >= 0.7) return '🥈';
    if (_percentage >= 0.6) return '🥉';
    return '💪';
  }

  double get _nilaiAngka {
    return (_percentage * 100).clamp(0, 100);
  }

  String get _predikat {
    if (_nilaiAngka >= 90) return 'Sangat Baik';
    if (_nilaiAngka >= 80) return 'Baik';
    if (_nilaiAngka >= 70) return 'Cukup';
    if (_nilaiAngka >= 60) return 'Perlu Bimbingan';
    return 'Kurang';
  }

  Color get _resultColor {
    if (_percentage >= 0.8) return AppColors.success;
    if (_percentage >= 0.6) return AppColors.accent;
    return AppColors.secondary;
  }

  @override
  Widget build(BuildContext context) {
    final subjectData = AppConstants.subjects.firstWhere(
      (s) => s['id'] == widget.subject,
      orElse: () => AppConstants.subjects.first,
    );

    return Scaffold(
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 50,
              colors: const [
                AppColors.primary,
                AppColors.secondary,
                AppColors.accent,
                AppColors.success,
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_resultColor, AppColors.background],
                stops: const [0.0, 0.5],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Trophy / Emoji
                    Text(_emoji, style: const TextStyle(fontSize: 80))
                        .animate()
                        .scale(duration: 700.ms, curve: Curves.elasticOut)
                        .then()
                        .shimmer(duration: 1.seconds),

                    const SizedBox(height: 16),

                    Text(
                      _message,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 300.ms),

                    const SizedBox(height: 8),

                    Text(
                      '${subjectData['emoji']} ${subjectData['name']}',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 16),
                    ).animate().fadeIn(delay: 400.ms),

                    const SizedBox(height: 32),

                    // Score Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // Grade Circle
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: _resultColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: _resultColor, width: 4),
                              ),
                              child: Center(
                                child: Text(
                                  _grade,
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    color: _resultColor,
                                  ),
                                ),
                              ),
                            )
                                .animate(delay: 200.ms)
                                .scale(curve: Curves.elasticOut),

                            const SizedBox(height: 24),

                            // Stats Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _StatItem(
                                  label: 'Benar',
                                  value:
                                      '${widget.correctAnswers}/${widget.totalQuestions}',
                                  emoji: '✅',
                                  color: AppColors.success,
                                ),
                                _StatItem(
                                  label: 'Skor',
                                  value: '${widget.score}',
                                  emoji: '⭐',
                                  color: AppColors.accent,
                                ),
                                _StatItem(
                                  label: 'Akurasi',
                                  value: '${(_percentage * 100).toInt()}%',
                                  emoji: '🎯',
                                  color: AppColors.primary,
                                ),
                              ],
                            )
                                .animate(delay: 400.ms)
                                .slideY(begin: 0.2)
                                .fadeIn(),

                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 20),
                              decoration: BoxDecoration(
                                color: _resultColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: _resultColor.withOpacity(0.4)),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    '📋 Nilai Kamu',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        _nilaiAngka.toStringAsFixed(0),
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w600,
                                          color: _resultColor,
                                        ),
                                      ),
                                      const Text(
                                        ' / 100',
                                        style: TextStyle(
                                            fontSize: 10, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _resultColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _predikat,
                                      style: TextStyle(
                                        color: _resultColor,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                                .animate(delay: 550.ms)
                                .slideY(begin: 0.2)
                                .fadeIn(),

                            // Progress bar
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Performa:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: _percentage,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        _resultColor),
                                    minHeight: 16,
                                  ),
                                ),
                              ],
                            ).animate(delay: 500.ms).fadeIn(),
                          ],
                        ),
                      ),
                    ).animate(delay: 100.ms).slideY(begin: 0.3).fadeIn(),

                    const SizedBox(height: 24),

                    // XP Earned
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.accent.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🎁', style: TextStyle(fontSize: 28)),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Kamu mendapat:',
                                style: TextStyle(
                                    color: Colors.black54, fontSize: 13),
                              ),
                              Text(
                                '+${widget.score} poin XP! 🌟',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFE6A800),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate(delay: 600.ms).scale(curve: Curves.elasticOut),

                    const SizedBox(height: 24),

                    // Buttons
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                      ),
                      child: const Text('Kembali ke Beranda 🏠',
                          style: TextStyle(fontSize: 16)),
                    ).animate(delay: 700.ms).slideY(begin: 0.2).fadeIn(),

                    const SizedBox(height: 12),

                    OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Coba Lagi! 🔄',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                    ).animate(delay: 800.ms).slideY(begin: 0.2).fadeIn(),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final String emoji;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.emoji,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
