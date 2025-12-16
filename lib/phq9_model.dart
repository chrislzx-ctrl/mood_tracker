class PHQ9Question {
  final String questionText;
  int score;

  PHQ9Question({required this.questionText, this.score = 0});
}

class PHQ9Result {
  final DateTime date;
  final int score;

  PHQ9Result({required this.date, required this.score});
}
