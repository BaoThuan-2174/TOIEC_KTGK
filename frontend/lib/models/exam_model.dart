class ExamListItem {
  final int id;
  final String title;
  final String description;
  final int durationMinutes;
  final int totalQuestions;
  final bool isPublished;
  final int submissionCount;
  final double averageScore;

  ExamListItem({
    required this.id,
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.totalQuestions,
    required this.isPublished,
    this.submissionCount = 0,
    this.averageScore = 0.0,
  });

  factory ExamListItem.fromJson(Map<String, dynamic> json) {
    return ExamListItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Untitled Exam',
      description: json['description'] ?? '',
      durationMinutes: json['durationMinutes'] ?? 75,
      totalQuestions: json['totalQuestions'] ?? 100,
      isPublished: json['isPublished'] ?? false,
      submissionCount: json['submissionCount'] ?? 0,
      averageScore: (json['averageScore'] ?? 0.0).toDouble(),
    );
  }
}

class ExamDetail {
  final int id;
  final String title;
  final String description;
  final int durationMinutes;
  final int totalQuestions;
  final List<QuestionGroup> questionGroups;

  ExamDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.totalQuestions,
    required this.questionGroups,
  });

  factory ExamDetail.fromJson(Map<String, dynamic> json) {
    var rawGroups = json['questionGroups'] as List? ?? [];
    return ExamDetail(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      durationMinutes: json['durationMinutes'] ?? 75,
      totalQuestions: json['totalQuestions'] ?? 100,
      questionGroups: rawGroups.map((g) => QuestionGroup.fromJson(g)).toList(),
    );
  }

  /// Flattens all questions into an ordered list for quick lookup
  List<ExamQuestion> getAllQuestions() {
    List<ExamQuestion> all = [];
    for (var g in questionGroups) {
      all.addAll(g.questions);
    }
    all.sort((a, b) => a.questionNumber.compareTo(b.questionNumber));
    return all;
  }
}

class QuestionGroup {
  final int id;
  final int examId;
  final int partType; // 1: Part 5, 2: Part 6, 3: Part 7
  final String? passageText;
  final String? passageImages;
  final int orderIndex;
  final bool allowShuffleQuestions;
  final List<ExamQuestion> questions;

  QuestionGroup({
    required this.id,
    required this.examId,
    required this.partType,
    this.passageText,
    this.passageImages,
    required this.orderIndex,
    this.allowShuffleQuestions = false,
    required this.questions,
  });

  factory QuestionGroup.fromJson(Map<String, dynamic> json) {
    var rawQuestions = json['questions'] as List? ?? [];
    return QuestionGroup(
      id: json['id'] ?? 0,
      examId: json['examId'] ?? 0,
      partType: json['partType'] is int ? json['partType'] : 1,
      passageText: json['passageText'],
      passageImages: json['passageImages'],
      orderIndex: json['orderIndex'] ?? 0,
      allowShuffleQuestions: json['allowShuffleQuestions'] ?? false,
      questions: rawQuestions.map((q) => ExamQuestion.fromJson(q)).toList(),
    );
  }
}

class ExamQuestion {
  final int id;
  final int questionGroupId;
  final int questionNumber;
  final String content;
  final String? explanation;
  final int orderIndex;
  final bool allowShuffleAnswers;
  final List<AnswerOption> answerOptions;

  ExamQuestion({
    required this.id,
    required this.questionGroupId,
    required this.questionNumber,
    required this.content,
    this.explanation,
    required this.orderIndex,
    this.allowShuffleAnswers = false,
    required this.answerOptions,
  });

  factory ExamQuestion.fromJson(Map<String, dynamic> json) {
    var rawOptions = json['answerOptions'] as List? ?? [];
    return ExamQuestion(
      id: json['id'] ?? 0,
      questionGroupId: json['questionGroupId'] ?? 0,
      questionNumber: json['questionNumber'] ?? 0,
      content: json['content'] ?? '',
      explanation: json['explanation'],
      orderIndex: json['orderIndex'] ?? 0,
      allowShuffleAnswers: json['allowShuffleAnswers'] ?? false,
      answerOptions: rawOptions.map((o) => AnswerOption.fromJson(o)).toList(),
    );
  }
}

class AnswerOption {
  final int id;
  final int questionId;
  final String label; // A, B, C, D
  final String content;
  final bool? isCorrect;

  AnswerOption({
    required this.id,
    required this.questionId,
    required this.label,
    required this.content,
    this.isCorrect,
  });

  factory AnswerOption.fromJson(Map<String, dynamic> json) {
    return AnswerOption(
      id: json['id'] ?? 0,
      questionId: json['questionId'] ?? 0,
      label: json['label'] ?? '',
      content: json['content'] ?? '',
      isCorrect: json['isCorrect'],
    );
  }
}

class SubmissionResult {
  final int id;
  final int examId;
  final String examTitle;
  final String studentName;
  final double score;
  final int correctCount;
  final int wrongCount;
  final int skippedCount;
  final int totalQuestions;
  final int timeSpentSeconds;

  SubmissionResult({
    required this.id,
    required this.examId,
    required this.examTitle,
    required this.studentName,
    required this.score,
    required this.correctCount,
    required this.wrongCount,
    required this.skippedCount,
    required this.totalQuestions,
    required this.timeSpentSeconds,
  });

  factory SubmissionResult.fromJson(Map<String, dynamic> json) {
    return SubmissionResult(
      id: json['id'] ?? 0,
      examId: json['examId'] ?? 0,
      examTitle: json['examTitle'] ?? 'TOEIC Reading Practice',
      studentName: json['studentName'] ?? 'Jamie Kim',
      score: (json['score'] ?? 0.0).toDouble(),
      correctCount: json['correctCount'] ?? 0,
      wrongCount: json['wrongCount'] ?? 0,
      skippedCount: json['skippedCount'] ?? 0,
      totalQuestions: json['totalQuestions'] ?? 100,
      timeSpentSeconds: json['timeSpentSeconds'] ?? 0,
    );
  }
}

class SubmissionReview {
  final int id;
  final int examId;
  final String examTitle;
  final String studentName;
  final double score;
  final int correctCount;
  final int wrongCount;
  final int skippedCount;
  final int totalQuestions;
  final int timeSpentSeconds;
  final List<ReviewDetail> details;

  SubmissionReview({
    required this.id,
    required this.examId,
    required this.examTitle,
    required this.studentName,
    required this.score,
    required this.correctCount,
    required this.wrongCount,
    required this.skippedCount,
    required this.totalQuestions,
    required this.timeSpentSeconds,
    required this.details,
  });

  factory SubmissionReview.fromJson(Map<String, dynamic> json) {
    var rawDetails = json['details'] as List? ?? [];
    return SubmissionReview(
      id: json['id'] ?? 0,
      examId: json['examId'] ?? 0,
      examTitle: json['examTitle'] ?? 'TOEIC Reading Practice',
      studentName: json['studentName'] ?? 'Jamie Kim',
      score: (json['score'] ?? 0.0).toDouble(),
      correctCount: json['correctCount'] ?? 0,
      wrongCount: json['wrongCount'] ?? 0,
      skippedCount: json['skippedCount'] ?? 0,
      totalQuestions: json['totalQuestions'] ?? 100,
      timeSpentSeconds: json['timeSpentSeconds'] ?? 0,
      details: rawDetails.map((d) => ReviewDetail.fromJson(d)).toList(),
    );
  }
}

class ReviewDetail {
  final int questionId;
  final int questionNumber;
  final String questionContent;
  final int partNumber;
  final String? passageText;
  final int? selectedOptionId;
  final int? correctOptionId;
  final bool isCorrect;
  final String? explanation;
  final List<AnswerOption> options;

  ReviewDetail({
    required this.questionId,
    required this.questionNumber,
    required this.questionContent,
    required this.partNumber,
    this.passageText,
    this.selectedOptionId,
    this.correctOptionId,
    required this.isCorrect,
    this.explanation,
    required this.options,
  });

  factory ReviewDetail.fromJson(Map<String, dynamic> json) {
    var rawOpts = json['options'] as List? ?? [];
    return ReviewDetail(
      questionId: json['questionId'] ?? 0,
      questionNumber: json['questionNumber'] ?? 0,
      questionContent: json['questionContent'] ?? '',
      partNumber: json['partNumber'] ?? 1,
      passageText: json['passageText'],
      selectedOptionId: json['selectedOptionId'],
      correctOptionId: json['correctOptionId'],
      isCorrect: json['isCorrect'] ?? false,
      explanation: json['explanation'],
      options: rawOpts.map((o) => AnswerOption.fromJson(o)).toList(),
    );
  }
}

class ExamStatistics {
  final int examId;
  final String examTitle;
  final int totalSubmissions;
  final double averageScore;
  final double highestScore;
  final double lowestScore;
  final List<TopWrongQuestion> topWrongQuestions;

  ExamStatistics({
    required this.examId,
    required this.examTitle,
    required this.totalSubmissions,
    required this.averageScore,
    required this.highestScore,
    required this.lowestScore,
    required this.topWrongQuestions,
  });

  factory ExamStatistics.fromJson(Map<String, dynamic> json) {
    var rawQuestions = json['topWrongQuestions'] as List? ?? [];
    return ExamStatistics(
      examId: json['examId'] ?? 0,
      examTitle: json['examTitle'] ?? '',
      totalSubmissions: json['totalSubmissions'] ?? 0,
      averageScore: (json['averageScore'] ?? 0.0).toDouble(),
      highestScore: (json['highestScore'] ?? 0.0).toDouble(),
      lowestScore: (json['lowestScore'] ?? 0.0).toDouble(),
      topWrongQuestions: rawQuestions.map((q) => TopWrongQuestion.fromJson(q)).toList(),
    );
  }
}

class TopWrongQuestion {
  final int questionId;
  final int questionNumber;
  final String questionContent;
  final int partNumber;
  final int wrongCount;
  final int totalAttempts;
  final double wrongPercentage;
  final String? explanation;

  TopWrongQuestion({
    required this.questionId,
    required this.questionNumber,
    required this.questionContent,
    required this.partNumber,
    required this.wrongCount,
    required this.totalAttempts,
    required this.wrongPercentage,
    this.explanation,
  });

  factory TopWrongQuestion.fromJson(Map<String, dynamic> json) {
    return TopWrongQuestion(
      questionId: json['questionId'] ?? 0,
      questionNumber: json['questionNumber'] ?? 0,
      questionContent: json['questionContent'] ?? '',
      partNumber: json['partNumber'] ?? 1,
      wrongCount: json['wrongCount'] ?? 0,
      totalAttempts: json['totalAttempts'] ?? 0,
      wrongPercentage: (json['wrongPercentage'] ?? 0.0).toDouble(),
      explanation: json['explanation'],
    );
  }
}

class UploadExamResult {
  final bool isSuccess;
  final int? examId;
  final String? examTitle;
  final int totalQuestions;
  final List<String> errors;

  UploadExamResult({
    required this.isSuccess,
    this.examId,
    this.examTitle,
    this.totalQuestions = 0,
    this.errors = const [],
  });

  factory UploadExamResult.fromJson(Map<String, dynamic> json) {
    var rawErrors = json['errors'] as List? ?? [];
    return UploadExamResult(
      isSuccess: json['isSuccess'] ?? false,
      examId: json['examId'],
      examTitle: json['examTitle'],
      totalQuestions: json['totalQuestions'] ?? 0,
      errors: rawErrors.map((e) => e.toString()).toList(),
    );
  }
}


