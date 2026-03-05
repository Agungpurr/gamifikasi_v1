class QuestionModel {
  final String id;
  final String subject;
  final String grade; // kelas 1-6
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final int points;
  final String difficulty; //easy, medium, hard

  QuestionModel({
    required this.id,
    required this.subject,
    required this.grade,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.points = 10,
    this.difficulty = 'easy',
  });

  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    return QuestionModel(
      id: map['id'] ?? '',
      subject: map['subject'] ?? '',
      grade: map['grade'] ?? '1',
      question: map['question'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctIndex: map['correctIndex'] ?? 0,
      explanation: map['explanation'] ?? '',
      points: map['points'] ?? 10,
      difficulty: map['difficulty'] ?? 'easy',
    );
  }
}
