// lib/screens/quiz/quiz_screen.dart

import 'dart:async';
import 'dart:math';
import 'package:edu_kids_app/services/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import '../../models/question_model.dart';
import '../../services/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../utils/app_theme.dart';
import 'quiz_result_screen.dart';

class QuizScreen extends StatefulWidget {
  final String subject;
  final String grade;

  const QuizScreen({super.key, required this.subject, required this.grade});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  List<QuestionModel> _questions = [];
  int _currentIndex = 0;
  int? _selectedAnswer;
  bool _answered = false;
  int _score = 0;
  int _correctAnswers = 0;
  bool _isLoading = true;
  int _timeLeft = 30;
  Timer? _timer;
  int _totalTime = 0;
  late ConfettiController _confettiController;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    AudioService.playQuizBgm();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    _shakeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _loadQuestions();
  }

  @override
  void dispose() {
    AudioService.playHomeBgm();
    _timer?.cancel();
    _confettiController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    try {
      final questions = await FirebaseService.getQuestions(
        widget.subject,
        widget.grade,
        limit: 8,
      );

      if (questions.isEmpty) {
        // Use built-in fallback questions
        setState(() {
          _questions = _fisherYatesShuffle(_getFallbackQuestions());
          _isLoading = false;
        });
      } else {
        setState(() {
          _questions = _fisherYatesShuffle(questions);
          _isLoading = false;
        });
      }
      _startTimer();
    } catch (e) {
      setState(() {
        _questions = _fisherYatesShuffle(_getFallbackQuestions());
        _isLoading = false;
      });
      _startTimer();
    }
  }

  /// Algoritma Fisher-Yates Shuffle — mengacak urutan soal
  /// Kompleksitas waktu: O(n) | Kompleksitas ruang: O(1)
  List<QuestionModel> _fisherYatesShuffle(List<QuestionModel> questions) {
    final Random random = Random();
    final List<QuestionModel> shuffled = List.from(questions);
    for (int i = shuffled.length - 1; i > 0; i--) {
      final int j = random.nextInt(i + 1);
      final temp = shuffled[i];
      shuffled[i] = shuffled[j];
      shuffled[j] = temp;
    }
    // Acak juga pilihan jawaban tiap soal
    return shuffled.map((q) => _shuffleOptions(q)).toList();
  }

  /// Fisher-Yates Shuffle untuk pilihan jawaban (options)
  /// correctIndex diperbarui otomatis mengikuti posisi baru jawaban benar
  QuestionModel _shuffleOptions(QuestionModel question) {
    final Random random = Random();

    // Buat list index [0, 1, 2, 3] lalu acak
    final List<int> indices = List.generate(question.options.length, (i) => i);
    for (int i = indices.length - 1; i > 0; i--) {
      final int j = random.nextInt(i + 1);
      final temp = indices[i];
      indices[i] = indices[j];
      indices[j] = temp;
    }

    // Susun options baru berdasarkan index yang sudah diacak
    final List<String> shuffledOptions =
        indices.map((i) => question.options[i]).toList();

    // Temukan posisi baru dari jawaban yang benar
    final int newCorrectIndex = indices.indexOf(question.correctIndex);

    return QuestionModel(
      id: question.id,
      subject: question.subject,
      grade: question.grade,
      question: question.question,
      options: shuffledOptions,
      correctIndex: newCorrectIndex,
      explanation: question.explanation,
      points: question.points,
      difficulty: question.difficulty,
    );
  }

  List<QuestionModel> _getFallbackQuestions() {
    // Built-in questions in case Firestore is empty
    final fallback = {
      'matematika': [
        QuestionModel(
            id: '1',
            subject: 'matematika',
            grade: widget.grade,
            question: 'Berapa hasil 6 + 7?',
            options: ['11', '12', '13', '14'],
            correctIndex: 2,
            explanation: '6 + 7 = 13',
            points: 10),
        QuestionModel(
            id: '2',
            subject: 'matematika',
            grade: widget.grade,
            question: 'Berapa hasil 9 × 4?',
            options: ['32', '34', '36', '38'],
            correctIndex: 2,
            explanation: '9 × 4 = 36',
            points: 15),
        QuestionModel(
            id: '3',
            subject: 'matematika',
            grade: widget.grade,
            question: 'Berapa hasil 50 ÷ 5?',
            options: ['8', '9', '10', '11'],
            correctIndex: 2,
            explanation: '50 ÷ 5 = 10',
            points: 15),
        QuestionModel(
            id: '4',
            subject: 'matematika',
            grade: widget.grade,
            question: 'Berapa 100 - 37?',
            options: ['53', '63', '73', '83'],
            correctIndex: 1,
            explanation: '100 - 37 = 63',
            points: 20),
      ],
      'bahasa': [
        QuestionModel(
            id: '5',
            subject: 'bahasa',
            grade: widget.grade,
            question: 'Kalimat "Saya pergi ke sekolah" adalah kalimat...',
            options: ['Tanya', 'Seru', 'Berita', 'Larangan'],
            correctIndex: 2,
            explanation:
                'Kalimat yang menyatakan informasi adalah kalimat berita.',
            points: 10),
        QuestionModel(
            id: '6',
            subject: 'bahasa',
            grade: widget.grade,
            question: 'Kata "indah" termasuk kata...',
            options: ['Benda', 'Kerja', 'Sifat', 'Keterangan'],
            correctIndex: 2,
            explanation:
                'Indah adalah kata sifat karena menggambarkan keadaan.',
            points: 10),
      ],
      'ipa': [
        QuestionModel(
            id: '7',
            subject: 'ipa',
            grade: widget.grade,
            question: 'Hewan yang bertelur adalah...',
            options: ['Kucing', 'Ayam', 'Kuda', 'Sapi'],
            correctIndex: 1,
            explanation: 'Ayam adalah hewan ovipar (bertelur).',
            points: 10),
        QuestionModel(
            id: '8',
            subject: 'ipa',
            grade: widget.grade,
            question: 'Air mendidih pada suhu...',
            options: ['80°C', '90°C', '100°C', '110°C'],
            correctIndex: 2,
            explanation: 'Air mendidih pada suhu 100°C pada tekanan normal.',
            points: 15),
      ],
      'ips': [
        QuestionModel(
            id: '9',
            subject: 'ips',
            grade: widget.grade,
            question:
                'Hari Kemerdekaan Indonesia diperingati setiap tanggal...',
            options: ['17 Agustus', '1 Juni', '20 Mei', '28 Oktober'],
            correctIndex: 0,
            explanation: 'Indonesia merdeka pada 17 Agustus 1945.',
            points: 10),
        QuestionModel(
            id: '10',
            subject: 'ips',
            grade: widget.grade,
            question: 'Pulau terbesar di Indonesia adalah...',
            options: ['Jawa', 'Sulawesi', 'Kalimantan', 'Sumatra'],
            correctIndex: 2,
            explanation: 'Kalimantan adalah pulau terbesar di Indonesia.',
            points: 15),
      ],
      'bahasa_inggris': [
        QuestionModel(
          id: '11',
          subject: 'bahasa_inggris',
          grade: widget.grade,
          question: 'What is the meaning of "book"?',
          options: ['Buku', 'Pensil', 'Meja', 'Kursi'],
          correctIndex: 0,
          explanation: '"Book" berarti buku.',
          points: 10,
        ),
        QuestionModel(
          id: '12',
          subject: 'bahasa_inggris',
          grade: widget.grade,
          question: 'How do you say "air" in English?',
          options: ['Water', 'Fire', 'Earth', 'Wind'],
          correctIndex: 0,
          explanation: '"Air" dalam bahasa Inggris adalah "water".',
          points: 15,
        ),
      ],
      'seni_budaya': [
        QuestionModel(
          id: '13',
          subject: 'seni_budaya',
          grade: widget.grade,
          question: 'Alat musik angklung dimainkan dengan cara...',
          options: ['Dipukul', 'Ditiup', 'Digoyang', 'Dipetik'],
          correctIndex: 2,
          explanation: 'Angklung dimainkan dengan cara digoyang.',
          points: 10,
        ),
        QuestionModel(
          id: '14',
          subject: 'seni_budaya',
          grade: widget.grade,
          question: 'Tari tradisional berasal dari...',
          options: ['Luar negeri', 'Daerah tertentu', 'Sekolah', 'Internet'],
          correctIndex: 1,
          explanation:
              'Tari tradisional berasal dari daerah tertentu di Indonesia.',
          points: 15,
        ),
      ],
    };
    return (fallback[widget.subject] ?? fallback['matematika'])!;
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _timeLeft = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
          _totalTime++;
        });
      } else {
        _autoAnswer();
      }
    });
  }

  void _autoAnswer() {
    if (!_answered) {
      _selectAnswer(-1); // Time's up
    }
  }

  void _selectAnswer(int index) {
    if (_answered) return;
    _timer?.cancel();

    final question = _questions[_currentIndex];
    final isCorrect = index == question.correctIndex;

    setState(() {
      _selectedAnswer = index;
      _answered = true;
      if (isCorrect) {
        _score += question.points;
        _correctAnswers++;
        AudioService.playCorrect();
        _confettiController.play();
      } else {
        AudioService.playWrong();
        _shakeController.forward(from: 0);
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _answered = false;
      });
      _startTimer();
    } else {
      _finishQuiz();
    }
  }

  Future<void> _finishQuiz() async {
    _timer?.cancel();
    final auth = context.read<AuthProvider>();

    if (auth.firebaseUser != null) {
      await FirebaseService.saveQuizResult(
        uid: auth.firebaseUser!.uid,
        subject: widget.subject,
        grade: widget.grade,
        score: _score,
        totalQuestions: _questions.length,
        correctAnswers: _correctAnswers,
        timeTaken: _totalTime,
        nilai: (_correctAnswers / _questions.length * 100).roundToDouble(),
      );
      await auth.addPoints(_score, widget.subject);

      // ✅ Daily Challenge — panggil setelah addPoints
      final bonusGranted = await auth.incrementDailyChallenge();

      // ✅ Cek Perfect score
      if (_correctAnswers == _questions.length &&
          !auth.userModel!.badges.contains('perfect_score')) {
        await FirebaseService.addBadge(auth.firebaseUser!.uid, 'perfect_score');
        await auth.refreshUserModel();
      }

      // ✅ Tampilkan snackbar bonus jika dapat +50 XP
      if (mounted && bonusGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Text('⚡', style: TextStyle(fontSize: 20)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tantangan Hari Ini Selesai! +50 XP Bonus! 🎁',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFFF9F43),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QuizResultScreen(
            score: _score,
            correctAnswers: _correctAnswers,
            totalQuestions: _questions.length,
            subject: widget.subject,
            nilai: (_correctAnswers / _questions.length * 100).roundToDouble(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('⏳', style: TextStyle(fontSize: 48)),
              SizedBox(height: 16),
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text('Memuat soal...', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kuis')),
        body: const Center(child: Text('Tidak ada soal tersedia')),
      );
    }

    final question = _questions[_currentIndex];
    final subjectData = AppConstants.subjects.firstWhere(
      (s) => s['id'] == widget.subject,
      orElse: () => AppConstants.subjects.first,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.1,
              colors: const [
                AppColors.primary,
                AppColors.secondary,
                AppColors.accent,
                AppColors.success,
              ],
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        (subjectData['color'] as Color),
                        (subjectData['color'] as Color).withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                          Expanded(
                            child: Text(
                              '${subjectData['emoji']} ${subjectData['name']}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '⭐ $_score',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Progress bar
                      Row(
                        children: [
                          Text(
                            '${_currentIndex + 1}/${_questions.length}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: (_currentIndex + 1) / _questions.length,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Timer
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _timeLeft <= 10
                                  ? Colors.red
                                  : Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Text('⏱', style: TextStyle(fontSize: 12)),
                                const SizedBox(width: 4),
                                Text(
                                  '$_timeLeft',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Question
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Question card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: (subjectData['color'] as Color)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    question.difficulty == 'easy'
                                        ? '😊 Mudah'
                                        : question.difficulty == 'medium'
                                            ? '🤔 Sedang'
                                            : '💪 Sulit',
                                    style: TextStyle(
                                      color: subjectData['color'] as Color,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  question.question,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        height: 1.5,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '+${question.points} poin',
                                  style: TextStyle(
                                    color: (subjectData['color'] as Color),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                            .animate()
                            .scale(duration: 300.ms, curve: Curves.elasticOut),

                        const SizedBox(height: 20),

                        // Options
                        ...question.options.asMap().entries.map((entry) {
                          final index = entry.key;
                          final option = entry.value;

                          Color? bgColor;
                          Color? borderColor;
                          Color? textColor;

                          if (_answered) {
                            if (index == question.correctIndex) {
                              bgColor = AppColors.success.withOpacity(0.15);
                              borderColor = AppColors.success;
                              textColor = AppColors.success;
                            } else if (index == _selectedAnswer) {
                              bgColor = AppColors.error.withOpacity(0.15);
                              borderColor = AppColors.error;
                              textColor = AppColors.error;
                            } else {
                              bgColor = Colors.white;
                              borderColor = Colors.grey.shade200;
                              textColor = Colors.grey;
                            }
                          } else {
                            bgColor = Colors.white;
                            borderColor = Colors.grey.shade200;
                            textColor = Colors.black87;
                          }

                          final labels = ['A', 'B', 'C', 'D'];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GestureDetector(
                              onTap: () => _selectAnswer(index),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border:
                                      Border.all(color: borderColor!, width: 2),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: borderColor.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          labels[index],
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: textColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        option,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                        ),
                                      ),
                                    ),
                                    if (_answered &&
                                        index == question.correctIndex)
                                      const Text('✅',
                                          style: TextStyle(fontSize: 20)),
                                    if (_answered &&
                                        index == _selectedAnswer &&
                                        index != question.correctIndex)
                                      const Text('❌',
                                          style: TextStyle(fontSize: 20)),
                                  ],
                                ),
                              ),
                            ),
                          )
                              .animate()
                              .slideX(
                                begin: 0.3,
                                delay: Duration(milliseconds: 100 * index),
                              )
                              .fadeIn();
                        }),

                        // Explanation
                        if (_answered) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                const Text('💡',
                                    style: TextStyle(fontSize: 24)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    question.explanation,
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ).animate().slideY(begin: 0.2).fadeIn(),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _nextQuestion,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 52),
                            ),
                            child: Text(
                              _currentIndex < _questions.length - 1
                                  ? 'Soal Berikutnya ➡️'
                                  : 'Lihat Hasil! 🏆',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ).animate().scale(curve: Curves.elasticOut),
                          const SizedBox(height: 20),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
