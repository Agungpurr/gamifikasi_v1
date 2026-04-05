// lib/screens/admin/admin_questions_screen.dart

import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/question_model.dart';
import '../../utils/app_theme.dart';

class AdminQuestionsScreen extends StatefulWidget {
  const AdminQuestionsScreen({super.key});

  @override
  State<AdminQuestionsScreen> createState() => _AdminQuestionsScreenState();
}

class _AdminQuestionsScreenState extends State<AdminQuestionsScreen> {
  List<QuestionModel> _questions = [];
  List<QuestionModel> _filtered = [];
  bool _loading = true;
  String _filterSubject = '';
  String _filterGrade = '';
  final _searchCtrl = TextEditingController();

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
    final questions = await AdminService.getAllQuestions();
    if (mounted) {
      setState(() {
        _questions = questions;
        _loading = false;
        _applyFilter();
      });
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _questions.where((item) {
        final matchText = q.isEmpty || item.question.toLowerCase().contains(q);
        final matchSubject =
            _filterSubject.isEmpty || item.subject == _filterSubject;
        final matchGrade = _filterGrade.isEmpty || item.grade == _filterGrade;
        return matchText && matchSubject && matchGrade;
      }).toList();
    });
  }

  void _openFormDialog({QuestionModel? existing}) {
    showDialog(
      context: context,
      builder: (ctx) => _QuestionFormDialog(
        existing: existing,
        onSaved: (data) async {
          if (existing != null) {
            await AdminService.updateQuestion(existing.id, data);
            _showSnack('Soal diperbarui');
          } else {
            final q = QuestionModel(
              id: '',
              subject: data['subject'],
              grade: data['grade'],
              question: data['question'],
              options: List<String>.from(data['options']),
              correctIndex: data['correctIndex'],
              explanation: data['explanation'],
              points: data['points'],
              difficulty: data['difficulty'],
            );
            await AdminService.addQuestion(q);
            _showSnack('Soal ditambahkan');
          }
          _load();
        },
      ),
    );
  }

  Future<void> _delete(QuestionModel q) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Soal'),
        content: Text(
            'Hapus soal ini?\n\n"${q.question.length > 60 ? '${q.question.substring(0, 60)}...' : q.question}"'),
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
      await AdminService.deleteQuestion(q.id);
      _load();
      _showSnack('Soal dihapus');
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
        // Filter bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            children: [
              TextField(
                controller: _searchCtrl,
                onChanged: (_) => _applyFilter(),
                decoration: const InputDecoration(
                  hintText: 'Cari soal...',
                  prefixIcon: Icon(Icons.search, size: 20),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _filterSubject.isEmpty ? null : _filterSubject,
                      decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          hintText: 'Semua Mapel'),
                      items: const [
                        DropdownMenuItem(
                            value: 'matematika', child: Text('Matematika')),
                        DropdownMenuItem(
                            value: 'bahasa', child: Text('B. Indonesia')),
                        DropdownMenuItem(value: 'ipa', child: Text('IPA')),
                        DropdownMenuItem(value: 'ips', child: Text('IPS')),
                      ],
                      onChanged: (val) {
                        setState(() => _filterSubject = val ?? '');
                        _applyFilter();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _filterGrade.isEmpty ? null : _filterGrade,
                      decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          hintText: 'Semua Level'),
                      items: [
                        '1',
                        '2',
                        '3',
                        '4',
                        '5',
                        '6',
                        '7',
                        '8',
                        '9',
                        '10',
                        '11',
                        '12'
                      ]
                          .map((g) => DropdownMenuItem(
                              value: g, child: Text('Level $g')))
                          .toList(),
                      onChanged: (val) {
                        setState(() => _filterGrade = val ?? '');
                        _applyFilter();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_filterSubject.isNotEmpty || _filterGrade.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _filterSubject = '';
                          _filterGrade = '';
                        });
                        _applyFilter();
                      },
                      child: const Text('Reset'),
                    ),
                ],
              ),
            ],
          ),
        ),

        // Counter + Add button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_filtered.length} soal',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ElevatedButton.icon(
                onPressed: () => _openFormDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tambah Soal'),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10)),
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
                      child: Text('Tidak ada soal',
                          style: TextStyle(color: Colors.grey)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                        itemCount: _filtered.length,
                        itemBuilder: (ctx, i) => _QuestionCard(
                          question: _filtered[i],
                          onEdit: () => _openFormDialog(existing: _filtered[i]),
                          onDelete: () => _delete(_filtered[i]),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }
}

// ─── Question Card ─────────────────────────────────────────────────────────

class _QuestionCard extends StatelessWidget {
  final QuestionModel question;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _QuestionCard({
    required this.question,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _subjectColor {
    switch (question.subject) {
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

  String get _subjectLabel {
    switch (question.subject) {
      case 'matematika':
        return 'Matematika';
      case 'bahasa':
        return 'B. Indonesia';
      case 'ipa':
        return 'IPA';
      case 'ips':
        return 'IPS';
      default:
        return question.subject;
    }
  }

  Color get _difficultyColor {
    switch (question.difficulty) {
      case 'easy':
        return AppColors.success;
      case 'medium':
        return AppColors.accent;
      case 'hard':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  String get _difficultyLabel {
    switch (question.difficulty) {
      case 'easy':
        return 'Mudah';
      case 'medium':
        return 'Sedang';
      case 'hard':
        return 'Sulit';
      default:
        return question.difficulty;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _subjectColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(_subjectLabel,
                      style: TextStyle(
                          color: _subjectColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('Level ${question.grade}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _difficultyColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(_difficultyLabel,
                      style: TextStyle(
                          color: _difficultyColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                Text('${question.points} poin',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary)),
                PopupMenuButton<String>(
                  onSelected: (val) {
                    if (val == 'edit') onEdit();
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
            const SizedBox(height: 10),

            // Question text
            Text(question.question,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),

            // Options
            ...question.options.asMap().entries.map((e) {
              final isCorrect = e.key == question.correctIndex;
              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? AppColors.success.withOpacity(0.1)
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCorrect ? AppColors.success : Colors.grey[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      String.fromCharCode(65 + e.key),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isCorrect ? AppColors.success : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(e.value,
                            style: const TextStyle(fontSize: 12))),
                    if (isCorrect)
                      const Icon(Icons.check_circle,
                          color: AppColors.success, size: 16),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ─── Question Form Dialog ───────────────────────────────────────────────────

class _QuestionFormDialog extends StatefulWidget {
  final QuestionModel? existing;
  final Function(Map<String, dynamic>) onSaved;

  const _QuestionFormDialog({this.existing, required this.onSaved});

  @override
  State<_QuestionFormDialog> createState() => _QuestionFormDialogState();
}

class _QuestionFormDialogState extends State<_QuestionFormDialog> {
  final _questionCtrl = TextEditingController();
  final _explanationCtrl = TextEditingController();
  final List<TextEditingController> _optionCtrls =
      List.generate(4, (_) => TextEditingController());

  String _subject = 'matematika';
  String _grade = '1';
  String _difficulty = 'easy';
  int _correctIndex = 0;
  int _points = 10;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final q = widget.existing!;
      _questionCtrl.text = q.question;
      _explanationCtrl.text = q.explanation;
      _subject = q.subject;
      _grade = q.grade;
      _difficulty = q.difficulty;
      _correctIndex = q.correctIndex;
      _points = switch (q.difficulty) {
        'easy' => 10,
        'medium' => 20,
        'hard' => 35,
        _ => 10,
      };
      for (int i = 0; i < q.options.length && i < 4; i++) {
        _optionCtrls[i].text = q.options[i];
      }
    }
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    _explanationCtrl.dispose();
    for (final c in _optionCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_questionCtrl.text.trim().isEmpty) {
      _showError('Pertanyaan tidak boleh kosong');
      return;
    }
    if (_optionCtrls.any((c) => c.text.trim().isEmpty)) {
      _showError('Semua pilihan jawaban harus diisi');
      return;
    }
    setState(() => _saving = true);
    await widget.onSaved({
      'question': _questionCtrl.text.trim(),
      'subject': _subject,
      'grade': _grade,
      'options': _optionCtrls.map((c) => c.text.trim()).toList(),
      'correctIndex': _correctIndex,
      'explanation': _explanationCtrl.text.trim(),
      'difficulty': _difficulty,
      'points': _points,
    });
    if (mounted) Navigator.pop(context);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing != null ? 'Edit Soal' : 'Tambah Soal'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mapel & Kelas
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _subject,
                    decoration:
                        const InputDecoration(labelText: 'Mata Pelajaran'),
                    items: const [
                      DropdownMenuItem(
                          value: 'matematika', child: Text('Matematika')),
                      DropdownMenuItem(
                          value: 'bahasa', child: Text('B. Indonesia')),
                      DropdownMenuItem(value: 'ipa', child: Text('IPA')),
                      DropdownMenuItem(value: 'ips', child: Text('IPS')),
                    ],
                    onChanged: (v) => setState(() => _subject = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _grade,
                    decoration: const InputDecoration(labelText: 'Level'),
                    items: [
                      '1',
                      '2',
                      '3',
                      '4',
                      '5',
                      '6',
                      '7',
                      '8',
                      '9',
                      '10',
                      '11',
                      '12'
                    ]
                        .map((g) =>
                            DropdownMenuItem(value: g, child: Text('Kelas $g')))
                        .toList(),
                    onChanged: (v) => setState(() => _grade = v!),
                  ),
                ),
              ]),
              const SizedBox(height: 12),

              // Pertanyaan
              TextFormField(
                controller: _questionCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Pertanyaan',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),

              // Pilihan jawaban
              const Text('Pilihan Jawaban',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const Text('Pilih jawaban yang benar dengan radio button',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 8),
              ...List.generate(
                  4,
                  (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Radio<int>(
                              value: i,
                              groupValue: _correctIndex,
                              onChanged: (v) =>
                                  setState(() => _correctIndex = v!),
                              activeColor: AppColors.success,
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: _optionCtrls[i],
                                decoration: InputDecoration(
                                  labelText:
                                      'Pilihan ${String.fromCharCode(65 + i)}',
                                  prefixText: _correctIndex == i ? '✓ ' : '',
                                  prefixStyle: const TextStyle(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
              const SizedBox(height: 8),
              // Tingkat & Poin
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _difficulty,
                      decoration:
                          const InputDecoration(labelText: 'Tingkat Kesulitan'),
                      items: const [
                        DropdownMenuItem(value: 'easy', child: Text('Mudah')),
                        DropdownMenuItem(
                            value: 'medium', child: Text('Sedang')),
                        DropdownMenuItem(value: 'hard', child: Text('Sulit')),
                      ],
                      onChanged: (v) => setState(() {
                        _difficulty = v!;
                        _points = switch (v) {
                          'easy' => 10,
                          'medium' => 20,
                          'hard' => 35,
                          _ => 10,
                        };
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Tampilan poin otomatis (read-only) ← GANTI COMMENT DENGAN INI
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$_points',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const Text('poin',
                            style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Penjelasan
              TextFormField(
                controller: _explanationCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Penjelasan Jawaban',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(widget.existing != null ? 'Simpan' : 'Tambah'),
        ),
      ],
    );
  }
}
