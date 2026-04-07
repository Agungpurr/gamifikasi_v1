// lib/screens/quiz/subject_select_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../utils/app_theme.dart';
import 'quiz_screen.dart';

class SubjectSelectScreen extends StatefulWidget {
  final String? initialSubject;

  const SubjectSelectScreen({super.key, this.initialSubject});

  @override
  State<SubjectSelectScreen> createState() => _SubjectSelectScreenState();
}

class _SubjectSelectScreenState extends State<SubjectSelectScreen> {
  String? _selectedSubject;
  String _selectedGrade = '1';

  @override
  void initState() {
    super.initState();
    _selectedSubject = widget.initialSubject;
  }

  void _startQuiz() {
    if (_selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pilih mata pelajaran dulu ya!'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          subject: _selectedSubject!,
          grade: _selectedGrade,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pilih Pelajaran 📚',
            style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: widget.initialSubject != null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grade selector
            Text('Level berapa?',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(12, (i) {
                  final grade = '${i + 1}';
                  final isSelected = _selectedGrade == grade;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedGrade = grade),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.grey.shade200,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                      color: AppColors.primary.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3))
                                ]
                              : [],
                        ),
                        child: Text(
                          'Level ${i + 1}',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ).animate().slideX(begin: -0.2).fadeIn(),

            const SizedBox(height: 28),

            Text('Pilih Mata Pelajaran!',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),

            ...AppConstants.subjects.asMap().entries.map((entry) {
              final subject = entry.value;
              final color = subject['color'] as Color;
              final isSelected = _selectedSubject == subject['id'];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedSubject = subject['id']),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? color : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? color : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? color.withOpacity(0.3)
                              : Colors.black.withOpacity(0.04),
                          blurRadius: isSelected ? 12 : 4,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withOpacity(0.3)
                                : color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(subject['emoji'],
                              style: const TextStyle(fontSize: 28)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                subject['name'],
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                              Text(
                                subject['description'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      isSelected ? Colors.white70 : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle, color: Colors.white),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .slideX(
                        begin: 0.2,
                        delay: Duration(milliseconds: 50 * entry.key))
                    .fadeIn(),
              );
            }),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _startQuiz,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: AppColors.primary,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Mulai Kuis! 🎯', style: TextStyle(fontSize: 18)),
                ],
              ),
            ).animate().scale(delay: 400.ms, curve: Curves.elasticOut),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
