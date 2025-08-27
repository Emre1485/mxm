enum QuestionType { essay, multipleChoice, trueFalse }

class Question {
  final String id;
  final QuestionType type;
  final String questionText;
  final String? imageUrl;
  final List<String>? choices;
  final String? answer;
  final String topic;
  final int score;

  Question({
    required this.id,
    required this.type,
    required this.questionText,
    this.imageUrl,
    this.choices,
    this.answer,
    required this.topic,
    required this.score,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'questionText': questionText,
      'imageUrl': imageUrl,
      'choices': choices,
      'answer': answer,
      'topic': topic,
      'score': score,
    };
  }

  factory Question.fromMap(Map<String, dynamic> map, String id) {
    return Question(
      id: id,
      type: QuestionType.values.byName(map['type']),
      questionText: map['questionText'],
      imageUrl: map['imageUrl'],
      choices: map['choices'] != null
          ? List<String>.from(map['choices'])
          : null,
      answer: map['answer'],
      topic: map['topic'],
      score: map['score'],
    );
  }
}
