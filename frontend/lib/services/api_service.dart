import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/exam_model.dart';

class ApiService {
  static const String baseUrl = 'https://localhost:44311'; // Backend URL

  /// Lấy danh sách đề thi đã xuất bản
  Future<List<ExamListItem>> getPublishedExams() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/services/app/Exam/GetPublishedExams'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = data['result'] as List;
        if (result.isNotEmpty) {
          return result.map((e) => ExamListItem.fromJson(e)).toList();
        }
      }
    } catch (e) {
      debugPrint('Backend offline or error: $e. Using Figma Mock Data.');
    }

    // Fallback Mock Data matching Figma design
    return getMockExams();
  }

  /// Lấy chi tiết đề thi cho học viên làm bài
  Future<ExamDetail> getExamForStudent(int examId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/services/app/Exam/GetExamForStudent?id=$examId'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ExamDetail.fromJson(data['result']);
      }
    } catch (e) {
      debugPrint('Backend offline or error: $e. Using Figma Mock Exam.');
    }

    return getMockExamDetail(examId);
  }

  /// Nộp bài thi
  Future<SubmissionResult> submitExam({
    required int examId,
    required String studentName,
    required int timeSpentSeconds,
    required Map<int, int> selectedAnswers, // questionId -> optionId
  }) async {
    final body = jsonEncode({
      'examId': examId,
      'studentName': studentName,
      'timeSpentSeconds': timeSpentSeconds,
      'startTime': DateTime.now().subtract(Duration(seconds: timeSpentSeconds)).toIso8601String(),
      'answers': selectedAnswers.entries
          .map((e) => {
                'questionId': e.key,
                'selectedAnswerOptionId': e.value, // matches SubmitExamInput.Answers[].SelectedAnswerOptionId
              })
          .toList(),
    });

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/services/app/ExamSubmission/SubmitExam'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SubmissionResult.fromJson(data['result']);
      }
    } catch (e) {
      debugPrint('Backend offline or error: $e. Simulating submission.');
    }

    // Mock calculation matching Figma test result
    final totalQ = 100;
    int answeredCount = selectedAnswers.length;
    int correctCount = (answeredCount * 0.82).round();
    int wrongCount = answeredCount - correctCount;
    int skippedCount = totalQ - answeredCount;
    double score = (correctCount / totalQ) * 100;

    return SubmissionResult(
      id: 999,
      examId: examId,
      examTitle: 'Practice 01',
      studentName: studentName,
      score: score,
      correctCount: correctCount,
      wrongCount: wrongCount,
      skippedCount: skippedCount,
      totalQuestions: totalQ,
      timeSpentSeconds: timeSpentSeconds,
    );
  }

  /// Lấy kết quả review chi tiết
  Future<SubmissionReview> getSubmissionReview(int submissionId, ExamDetail exam, Map<int, int> userAnswers) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/services/app/ExamSubmission/GetSubmissionReview?submissionId=$submissionId'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SubmissionReview.fromJson(data['result']);
      }
    } catch (e) {
      debugPrint('Backend offline. Building review from exam data: $e');
    }

    // Build review from exam data
    final allQuestions = exam.getAllQuestions();
    List<ReviewDetail> reviewDetails = [];
    int correct = 0;
    int wrong = 0;
    int skipped = 0;

    for (var q in allQuestions) {
      final selectedOptId = userAnswers[q.id];
      // First option (A) is correct in mock data if not specified
      final correctOpt = q.answerOptions.firstWhere(
        (o) => o.isCorrect == true,
        orElse: () => q.answerOptions.first,
      );

      final isCorr = selectedOptId == correctOpt.id;
      if (selectedOptId == null) {
        skipped++;
      } else if (isCorr) {
        correct++;
      } else {
        wrong++;
      }

      // Find passage if any
      String? passage;
      int partNum = 1;
      for (var g in exam.questionGroups) {
        if (g.questions.any((x) => x.id == q.id)) {
          passage = g.passageText;
          partNum = g.partType;
          break;
        }
      }

      reviewDetails.add(ReviewDetail(
        questionId: q.id,
        questionNumber: q.questionNumber,
        questionContent: q.content,
        partNumber: partNum,
        passageText: passage,
        selectedOptionId: selectedOptId,
        correctOptionId: correctOpt.id,
        isCorrect: isCorr,
        explanation: q.explanation ?? 'The correct answer is (${correctOpt.label}) because it fits the sentence grammatically and contextually.',
        options: q.answerOptions,
      ));
    }

    return SubmissionReview(
      id: submissionId,
      examId: exam.id,
      examTitle: exam.title,
      studentName: 'Jamie Kim',
      score: (correct / (allQuestions.isNotEmpty ? allQuestions.length : 1)) * 100,
      correctCount: correct,
      wrongCount: wrong,
      skippedCount: skipped,
      totalQuestions: allQuestions.length,
      timeSpentSeconds: 4302, // ~71m 42s
      details: reviewDetails,
    );
  }

  // ===================== FIGMA MOCK DATA GENERATOR =====================
  static List<ExamListItem> getMockExams() {
    return [
      ExamListItem(
        id: 1,
        title: 'Practice 01',
        description: 'Build confidence with authentic workplace passages, grammar and vocabulary.',
        durationMinutes: 75,
        totalQuestions: 100,
        isPublished: true,
        submissionCount: 42,
        averageScore: 78.5,
      ),
      ExamListItem(
        id: 2,
        title: 'Practice 02',
        description: 'Build confidence with authentic workplace passages, grammar and vocabulary.',
        durationMinutes: 75,
        totalQuestions: 100,
        isPublished: true,
        submissionCount: 28,
        averageScore: 82.0,
      ),
      ExamListItem(
        id: 3,
        title: 'Practice 03',
        description: 'Build confidence with authentic workplace passages, grammar and vocabulary.',
        durationMinutes: 75,
        totalQuestions: 100,
        isPublished: true,
        submissionCount: 15,
        averageScore: 80.2,
      ),
    ];
  }

  static ExamDetail getMockExamDetail(int examId) {
    List<QuestionGroup> groups = [];
    int qIdCounter = 1;

    // --- PART 5 (101 - 130): Incomplete Sentences ---
    List<ExamQuestion> part5Questions = [];
    for (int qNum = 101; qNum <= 130; qNum++) {
      if (qNum == 121) {
        // Exact question from Figma Screen!
        part5Questions.add(ExamQuestion(
          id: qIdCounter++,
          questionGroupId: 1,
          questionNumber: 121,
          content: 'All employees must submit their travel expenses _____ five business days of returning from a trip.',
          explanation: 'The preposition "within" is used to indicate a period of time before the end of which an action must happen.',
          orderIndex: 21,
          answerOptions: [
            AnswerOption(id: 1001, questionId: qNum, label: 'A', content: 'within', isCorrect: true),
            AnswerOption(id: 1002, questionId: qNum, label: 'B', content: 'during', isCorrect: false),
            AnswerOption(id: 1003, questionId: qNum, label: 'C', content: 'among', isCorrect: false),
            AnswerOption(id: 1004, questionId: qNum, label: 'D', content: 'since', isCorrect: false),
          ],
        ));
      } else if (qNum == 101) {
        part5Questions.add(ExamQuestion(
          id: qIdCounter++,
          questionGroupId: 1,
          questionNumber: 101,
          content: 'Ms. Durkin asked for volunteers to help -------- with the employee fitness program.',
          explanation: 'Objective pronoun "her" is required after the verb "help".',
          orderIndex: 1,
          answerOptions: [
            AnswerOption(id: 1005, questionId: qNum, label: 'A', content: 'she', isCorrect: false),
            AnswerOption(id: 1006, questionId: qNum, label: 'B', content: 'her', isCorrect: true),
            AnswerOption(id: 1007, questionId: qNum, label: 'C', content: 'hers', isCorrect: false),
            AnswerOption(id: 1008, questionId: qNum, label: 'D', content: 'herself', isCorrect: false),
          ],
        ));
      } else {
        part5Questions.add(ExamQuestion(
          id: qIdCounter++,
          questionGroupId: 1,
          questionNumber: qNum,
          content: 'The marketing department will review the advertising budget _____ next Monday.',
          explanation: 'Preposition of time indicating deadline.',
          orderIndex: qNum - 100,
          answerOptions: [
            AnswerOption(id: qNum * 10 + 1, questionId: qNum, label: 'A', content: 'before', isCorrect: true),
            AnswerOption(id: qNum * 10 + 2, questionId: qNum, label: 'B', content: 'between', isCorrect: false),
            AnswerOption(id: qNum * 10 + 3, questionId: qNum, label: 'C', content: 'along', isCorrect: false),
            AnswerOption(id: qNum * 10 + 4, questionId: qNum, label: 'D', content: 'into', isCorrect: false),
          ],
        ));
      }
    }
    groups.add(QuestionGroup(
      id: 1,
      examId: examId,
      partType: 1,
      passageText: null,
      orderIndex: 1,
      questions: part5Questions,
    ));

    // --- PART 6 (131 - 146): Text Completion ---
    // Group 1: 131 - 134
    groups.add(QuestionGroup(
      id: 2,
      examId: examId,
      partType: 2,
      passageText: '''QUESTIONS 131-134 / ADVERTISEMENT

With Global Strength Gym's 30-day trial period, you get the opportunity to try out our classes, equipment, and facilities. ----[131]----. It's completely risk-free! To sign up, we require your contact information and payment details, but you will only be charged if you are a member for ----[132]---- 30 days.

If you decide within this time that you no longer want to be a member of Global Strength, ----[133]---- visit our Web site at www.gsgym.com. On the Membership page, elect to ----[134]---- your membership and enter the necessary information. It's that easy!''',
      orderIndex: 2,
      questions: [
        ExamQuestion(
          id: qIdCounter++,
          questionGroupId: 2,
          questionNumber: 131,
          content: 'Choose the best phrase to fill in blank 131.',
          orderIndex: 1,
          answerOptions: [
            AnswerOption(id: 1311, questionId: 131, label: 'A', content: 'Throughout the trial, you pay nothing and sign no contract.', isCorrect: true),
            AnswerOption(id: 1312, questionId: 131, label: 'B', content: 'Weight-lifting classes are not currently available.', isCorrect: false),
            AnswerOption(id: 1313, questionId: 131, label: 'C', content: 'A cash deposit is required when you sign up for membership.', isCorrect: false),
            AnswerOption(id: 1314, questionId: 131, label: 'D', content: 'All questions should be e-mailed to customerservice@gsgym.com.', isCorrect: false),
          ],
        ),
        ExamQuestion(
          id: qIdCounter++,
          questionGroupId: 2,
          questionNumber: 132,
          content: 'Choose the word that best completes blank 132.',
          orderIndex: 2,
          answerOptions: [
            AnswerOption(id: 1321, questionId: 132, label: 'A', content: 'not even', isCorrect: false),
            AnswerOption(id: 1322, questionId: 132, label: 'B', content: 'almost', isCorrect: false),
            AnswerOption(id: 1323, questionId: 132, label: 'C', content: 'over', isCorrect: true),
            AnswerOption(id: 1324, questionId: 132, label: 'D', content: 'less than', isCorrect: false),
          ],
        ),
        ExamQuestion(
          id: qIdCounter++,
          questionGroupId: 2,
          questionNumber: 133,
          content: 'Choose the word that best completes blank 133.',
          orderIndex: 3,
          answerOptions: [
            AnswerOption(id: 1331, questionId: 133, label: 'A', content: 'justly', isCorrect: false),
            AnswerOption(id: 1332, questionId: 133, label: 'B', content: 'regularly', isCorrect: false),
            AnswerOption(id: 1333, questionId: 133, label: 'C', content: 'evenly', isCorrect: false),
            AnswerOption(id: 1334, questionId: 133, label: 'D', content: 'simply', isCorrect: true),
          ],
        ),
        ExamQuestion(
          id: qIdCounter++,
          questionGroupId: 2,
          questionNumber: 134,
          content: 'Choose the word that best completes blank 134.',
          orderIndex: 4,
          answerOptions: [
            AnswerOption(id: 1341, questionId: 134, label: 'A', content: 'extend', isCorrect: false),
            AnswerOption(id: 1342, questionId: 134, label: 'B', content: 'renew', isCorrect: false),
            AnswerOption(id: 1343, questionId: 134, label: 'C', content: 'cancel', isCorrect: true),
            AnswerOption(id: 1344, questionId: 134, label: 'D', content: 'initiate', isCorrect: false),
          ],
        ),
      ],
    ));

    // Group 2: 135 - 136 (Exact Email passage from Figma Screen!)
    groups.add(QuestionGroup(
      id: 3,
      examId: examId,
      partType: 2,
      passageText: '''QUESTIONS 133–136 / EMAIL

A new chapter for our team

To: All employees
From: Daniel Ortiz, Office Manager
Subject: Office relocation update

Dear colleagues,

We are pleased to announce that our company will move to a larger office next month. The new space has been carefully — [133] — to support our growing team and provide more meeting rooms.

Packing materials will be delivered on Monday. Please label all boxes with your name and department. — [134] —. This will help the moving team place your belongings correctly.

The IT team will — [135] — all computers over the weekend. As a result, staff should save their work to the shared drive by 5 p.m. on Friday.''',
      orderIndex: 3,
      questions: [
        ExamQuestion(
          id: qIdCounter++,
          questionGroupId: 3,
          questionNumber: 135,
          content: 'Choose the word that best completes blank 135.',
          orderIndex: 5,
          answerOptions: [
            AnswerOption(id: 1351, questionId: 135, label: 'A', content: 'relocate', isCorrect: true),
            AnswerOption(id: 1352, questionId: 135, label: 'B', content: 'relocated', isCorrect: false),
            AnswerOption(id: 1353, questionId: 135, label: 'C', content: 'relocation', isCorrect: false),
            AnswerOption(id: 1354, questionId: 135, label: 'D', content: 'relocating', isCorrect: false),
          ],
        ),
        ExamQuestion(
          id: qIdCounter++,
          questionGroupId: 3,
          questionNumber: 136,
          content: 'Choose the word that best completes blank 136.',
          orderIndex: 6,
          answerOptions: [
            AnswerOption(id: 1361, questionId: 136, label: 'A', content: 'cooperation', isCorrect: false),
            AnswerOption(id: 1362, questionId: 136, label: 'B', content: 'cooperative', isCorrect: false),
            AnswerOption(id: 1363, questionId: 136, label: 'C', content: 'cooperate', isCorrect: true),
            AnswerOption(id: 1364, questionId: 136, label: 'D', content: 'cooperatively', isCorrect: false),
          ],
        ),
      ],
    ));

    // Fill remaining Part 6 questions up to 146
    List<ExamQuestion> remainingPart6 = [];
    for (int q = 137; q <= 146; q++) {
      remainingPart6.add(ExamQuestion(
        id: qIdCounter++,
        questionGroupId: 4,
        questionNumber: q,
        content: 'Choose the best word or phrase for sentence $q.',
        orderIndex: q - 130,
        answerOptions: [
          AnswerOption(id: q * 10 + 1, questionId: q, label: 'A', content: 'conveniently', isCorrect: true),
          AnswerOption(id: q * 10 + 2, questionId: q, label: 'B', content: 'convenient', isCorrect: false),
          AnswerOption(id: q * 10 + 3, questionId: q, label: 'C', content: 'convenience', isCorrect: false),
          AnswerOption(id: q * 10 + 4, questionId: q, label: 'D', content: 'more convenient', isCorrect: false),
        ],
      ));
    }
    groups.add(QuestionGroup(
      id: 4,
      examId: examId,
      partType: 2,
      passageText: '''MEMORANDUM
To: Sales Representatives
From: Karen Vance, Vice President
Subject: Client Engagement Guidelines

Please review our updated client consultation procedures effective immediately.''',
      orderIndex: 4,
      questions: remainingPart6,
    ));

    // --- PART 7 (147 - 200): Reading Comprehension ---
    // Group 1: 147 - 151 (Exact Passage & Questions from Figma Screen!)
    groups.add(QuestionGroup(
      id: 5,
      examId: examId,
      partType: 3,
      passageText: '''DOCUMENT 1 / EMAIL
From: Maya Chen · To: All participants · October 12
Subject: Updated venue for the writing workshop

Thank you for registering for our Business Writing Workshop on October 24. Due to maintenance at the library, we will now meet in the Cedar room at Riverside Conference Center at 9:00 a.m.

Please arrive 15 minutes early to collect your materials. Lunch is included. Reply by October 18 if you have any dietary requirements.
We look forward to welcoming you. — Maya Chen

---
DOCUMENT 2 / VISITOR NOTICE
Welcome to Riverside
Enter through the east entrance. Free parking is behind the center. The Cedar room is next to the main hall.
[RIVERSIDE CONFERENCE CENTER · LEVEL 1: Main hall | Cedar room | Entrance]

---
DOCUMENT 3 / WORKSHOP SCHEDULE · OCTOBER 24
8:45 a.m.   Registration & materials
9:00 a.m.   Writing clear business emails
10:30 a.m.  Refreshment break
12:00 p.m.  Lunch in the main hall''',
      orderIndex: 5,
      questions: [
        ExamQuestion(
          id: qIdCounter++,
          questionGroupId: 5,
          questionNumber: 147,
          content: 'Why was the workshop moved to a new location?',
          explanation: 'The email says the venue changed "due to maintenance at the library." Skill: Identifying a stated reason.',
          orderIndex: 1,
          answerOptions: [
            AnswerOption(id: 1471, questionId: 147, label: 'A', content: 'The library is undergoing maintenance.', isCorrect: true),
            AnswerOption(id: 1472, questionId: 147, label: 'B', content: 'More participants registered than expected.', isCorrect: false),
            AnswerOption(id: 1473, questionId: 147, label: 'C', content: 'The original venue was too expensive.', isCorrect: false),
            AnswerOption(id: 1474, questionId: 147, label: 'D', content: 'The coordinator requested a larger room.', isCorrect: false),
          ],
        ),
        ExamQuestion(
          id: qIdCounter++,
          questionGroupId: 5,
          questionNumber: 148,
          content: 'What should participants do by October 18?',
          explanation: 'The email specifies: "Reply by October 18 if you have any dietary requirements."',
          orderIndex: 2,
          answerOptions: [
            AnswerOption(id: 1481, questionId: 148, label: 'A', content: 'Confirm their dietary requirements.', isCorrect: true),
            AnswerOption(id: 1482, questionId: 148, label: 'B', content: 'Collect their workshop materials.', isCorrect: false),
            AnswerOption(id: 1483, questionId: 148, label: 'C', content: 'Pay the registration fee.', isCorrect: false),
            AnswerOption(id: 1484, questionId: 148, label: 'D', content: 'Request a parking permit.', isCorrect: false),
          ],
        ),
        ExamQuestion(
          id: qIdCounter++,
          questionGroupId: 5,
          questionNumber: 149,
          content: 'Where will lunch be served?',
          orderIndex: 3,
          answerOptions: [
            AnswerOption(id: 1491, questionId: 149, label: 'A', content: 'In the main hall.', isCorrect: true),
            AnswerOption(id: 1492, questionId: 149, label: 'B', content: 'In the Cedar room.', isCorrect: false),
            AnswerOption(id: 1493, questionId: 149, label: 'C', content: 'At the public library.', isCorrect: false),
            AnswerOption(id: 1494, questionId: 149, label: 'D', content: 'Behind the conference center.', isCorrect: false),
          ],
        ),
        ExamQuestion(
          id: qIdCounter++,
          questionGroupId: 5,
          questionNumber: 150,
          content: 'What time is the first presentation scheduled to begin?',
          orderIndex: 4,
          answerOptions: [
            AnswerOption(id: 1501, questionId: 150, label: 'A', content: '8:45 a.m.', isCorrect: false),
            AnswerOption(id: 1502, questionId: 150, label: 'B', content: '9:00 a.m.', isCorrect: true),
            AnswerOption(id: 1503, questionId: 150, label: 'C', content: '10:30 a.m.', isCorrect: false),
            AnswerOption(id: 1504, questionId: 150, label: 'D', content: '12:00 p.m.', isCorrect: false),
          ],
        ),
        ExamQuestion(
          id: qIdCounter++,
          questionGroupId: 5,
          questionNumber: 151,
          content: 'According to the notice, what is located behind the center?',
          orderIndex: 5,
          answerOptions: [
            AnswerOption(id: 1511, questionId: 151, label: 'A', content: 'Free parking.', isCorrect: true),
            AnswerOption(id: 1512, questionId: 151, label: 'B', content: 'The library entrance.', isCorrect: false),
            AnswerOption(id: 1513, questionId: 151, label: 'C', content: 'A dining terrace.', isCorrect: false),
            AnswerOption(id: 1514, questionId: 151, label: 'D', content: 'The registration desk.', isCorrect: false),
          ],
        ),
      ],
    ));

    // Fill Questions 152 to 199
    List<ExamQuestion> midPart7 = [];
    for (int q = 152; q <= 199; q++) {
      midPart7.add(ExamQuestion(
        id: qIdCounter++,
        questionGroupId: 6,
        questionNumber: q,
        content: 'According to the article, what is indicated about the new corporate initiative for question $q?',
        orderIndex: q - 150,
        answerOptions: [
          AnswerOption(id: q * 10 + 1, questionId: q, label: 'A', content: 'It will expand international shipping services.', isCorrect: true),
          AnswerOption(id: q * 10 + 2, questionId: q, label: 'B', content: 'It will reduce product manufacturing costs.', isCorrect: false),
          AnswerOption(id: q * 10 + 3, questionId: q, label: 'C', content: 'It was originally delayed by three months.', isCorrect: false),
          AnswerOption(id: q * 10 + 4, questionId: q, label: 'D', content: 'It was endorsed by the board of trustees.', isCorrect: false),
        ],
      ));
    }
    groups.add(QuestionGroup(
      id: 6,
      examId: examId,
      partType: 3,
      passageText: '''BUSINESS DAILY · PRESS RELEASE
Westbridge Chamber of Commerce announces expanding international business relations with partners across Asia and Europe.''',
      orderIndex: 6,
      questions: midPart7,
    ));

    // Exact Question 200 from Figma Screen:
    groups.add(QuestionGroup(
      id: 7,
      examId: examId,
      partType: 3,
      passageText: '''QUESTIONS 196–200 / NOTICE
Building a sustainable future

The Westbridge Chamber of Commerce invites all members to our annual networking evening on Friday, November 15, at 6:30 p.m. at the Harbor Hotel. This year's focus is on sustainable growth for local companies and creating new opportunities in international markets.

The evening includes a keynote address by Dr. Linda Foster, panel conversations on renewable tech, and a networking reception. There is no additional fee for active chamber members. Please RSVP so that we can make proper catering arrangements.

For further information or special assistance requests, we look forward to seeing you at Harbor Hotel.''',
      orderIndex: 7,
      questions: [
        ExamQuestion(
          id: qIdCounter++,
          questionGroupId: 7,
          questionNumber: 200,
          content: 'What are members asked to do by November 1?',
          explanation: 'Members are asked to confirm their attendance by registering before the deadline.',
          orderIndex: 1,
          answerOptions: [
            AnswerOption(id: 2001, questionId: 200, label: 'A', content: 'Register for the networking evening.', isCorrect: true),
            AnswerOption(id: 2002, questionId: 200, label: 'B', content: 'Submit questions for the panel.', isCorrect: false),
            AnswerOption(id: 2003, questionId: 200, label: 'C', content: 'Pay a guest admission fee.', isCorrect: false),
            AnswerOption(id: 2004, questionId: 200, label: 'D', content: 'Contact the Harbor Hotel.', isCorrect: false),
          ],
        ),
      ],
    ));

    return ExamDetail(
      id: examId,
      title: 'Practice 01',
      description: 'Build confidence with authentic workplace passages, grammar and vocabulary.',
      durationMinutes: 75,
      totalQuestions: 100,
      questionGroups: groups,
    );
  }

  // ===================== ADMIN ENDPOINTS & MOCK DATA =====================

  /// Lấy tất cả đề thi (dành cho Admin quản lý)
  Future<List<ExamListItem>> getAllExamsAdmin() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/services/app/Exam/GetAllExams'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // ABP ListResultDto wraps result in { items: [...] }
        final result = data['result'];
        List rawItems;
        if (result is Map && result.containsKey('items')) {
          rawItems = result['items'] as List;
        } else if (result is List) {
          rawItems = result;
        } else {
          rawItems = [];
        }
        return rawItems.map((e) => ExamListItem.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Backend offline. Using Mock Admin Exams: $e');
    }
    return getMockAdminExams();
  }

  /// Xuất bản hoặc hủy xuất bản đề thi
  Future<bool> publishExam(int examId, bool isPublished) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/services/app/Exam/PublishExam'),
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: jsonEncode({'id': examId, 'isPublished': isPublished}),
          )
          .timeout(const Duration(seconds: 8));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('publishExam error: $e');
      return false;
    }
  }

  /// Lấy thống kê số lượt làm bài, điểm trung bình và Top 10 câu sai nhiều nhất
  Future<ExamStatistics> getExamStatistics(int examId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/services/app/Exam/GetExamStatistics?examId=$examId'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ExamStatistics.fromJson(data['result']);
      }
    } catch (e) {
      debugPrint('Backend offline. Using Mock Statistics.');
    }
    return getMockStatistics(examId);
  }

  /// Lấy chi tiết đề thi cho Admin rà soát (kèm đáp án đúng IsCorrect)
  Future<ExamDetail> getExamForAdminPreview(int examId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/services/app/Exam/GetExamForEdit?id=$examId'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ExamDetail.fromJson(data['result']);
      }
    } catch (e) {
      debugPrint('Backend offline. Using Mock Exam for Admin Preview.');
    }
    return getMockExamDetail(examId);
  }

  /// Tải lên file Word (.docx) đề thi TOEIC Reading và thẩm định cấu trúc
  Future<UploadExamResult> uploadExamDocx({
    required String fileName,
    required List<int> fileBytes,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/ToeicUpload/UploadDocxBase64'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'fileName': fileName,
              'fileBase64': base64Encode(fileBytes),
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final resObj = data['result'] ?? data;
        return UploadExamResult.fromJson(resObj);
      } else {
        return UploadExamResult(
          isSuccess: false,
          errors: ['Máy chủ phản hồi mã lỗi ${response.statusCode}: ${response.body}'],
        );
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      return UploadExamResult(
        isSuccess: false,
        errors: ['Không thể kết nối đến máy chủ Backend ($baseUrl): $e'],
      );
    }
  }

  /// Tải về file Word (.docx) mẫu TOEIC Reading chuẩn
  Future<List<int>?> downloadSampleDocx() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/ToeicUpload/DownloadSampleWord'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      debugPrint('Download sample error: $e');
    }
    return null;
  }

  /// Lấy danh sách quy định bộ thẻ Tags chuẩn
  Future<Map<String, dynamic>?> getTagSpecification() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/ToeicUpload/GetTagSpecification'))
          .timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['result'] ?? data;
      }
    } catch (e) {
      debugPrint('GetTagSpecification error: $e');
    }
    return null;
  }

  static List<ExamListItem> getMockAdminExams() {
    return [
      ExamListItem(
        id: 1,
        title: 'TOEIC Reading • Practice 01',
        description: 'Comprehensive workplace passages with updated format.',
        durationMinutes: 75,
        totalQuestions: 100,
        isPublished: false, // Draft in Figma!
        submissionCount: 0,
        averageScore: 0.0,
      ),
      ExamListItem(
        id: 2,
        title: 'TOEIC Reading • Practice 02',
        description: 'Practice exam focusing on Part 5 & Part 6 sentence mastery.',
        durationMinutes: 75,
        totalQuestions: 100,
        isPublished: true, // Published in Figma!
        submissionCount: 1284,
        averageScore: 72.0,
      ),
      ExamListItem(
        id: 3,
        title: 'TOEIC Reading • Practice 03',
        description: 'Full length reading test covering complex multi-passages.',
        durationMinutes: 75,
        totalQuestions: 100,
        isPublished: true,
        submissionCount: 890,
        averageScore: 74.5,
      ),
      ExamListItem(
        id: 4,
        title: 'Business English • Diagnostic',
        description: 'Diagnostic assessment for new learners.',
        durationMinutes: 75,
        totalQuestions: 100,
        isPublished: true,
        submissionCount: 450,
        averageScore: 68.2,
      ),
      ExamListItem(
        id: 5,
        title: 'TOEIC Reading • Foundation',
        description: 'Fundamental vocabulary and reading structures.',
        durationMinutes: 75,
        totalQuestions: 100,
        isPublished: false,
        submissionCount: 320,
        averageScore: 81.0,
      ),
    ];
  }

  static ExamStatistics getMockStatistics(int examId) {
    return ExamStatistics(
      examId: examId,
      examTitle: 'TOEIC Reading • Practice 01',
      totalSubmissions: 1284,
      averageScore: 72.0,
      highestScore: 98.0,
      lowestScore: 32.0,
      topWrongQuestions: [
        TopWrongQuestion(
          questionId: 174,
          questionNumber: 174,
          questionContent: 'What does the email indicate about the shipment schedule?',
          partNumber: 3,
          wrongCount: 873,
          totalAttempts: 1284,
          wrongPercentage: 68.0,
          explanation: 'Skill: Inference · email chain (Common chosen: B -> Correct: D)',
        ),
        TopWrongQuestion(
          questionId: 156,
          questionNumber: 156,
          questionContent: 'Why was the original meeting rescheduled?',
          partNumber: 3,
          wrongCount: 821,
          totalAttempts: 1284,
          wrongPercentage: 64.0,
          explanation: 'Skill: Purpose · notice (Common chosen: C -> Correct: A)',
        ),
        TopWrongQuestion(
          questionId: 139,
          questionNumber: 139,
          questionContent: 'Where would the sentence best fit?',
          partNumber: 2,
          wrongCount: 783,
          totalAttempts: 1284,
          wrongPercentage: 61.0,
          explanation: 'Skill: Sentence insertion (Common chosen: A -> Correct: C)',
        ),
        TopWrongQuestion(
          questionId: 192,
          questionNumber: 192,
          questionContent: 'What qualification is required for the project lead?',
          partNumber: 3,
          wrongCount: 757,
          totalAttempts: 1284,
          wrongPercentage: 59.0,
          explanation: 'Skill: Cross-text reference (Common chosen: D -> Correct: B)',
        ),
        TopWrongQuestion(
          questionId: 118,
          questionNumber: 118,
          questionContent: 'The committee was _____ impressed with the candidate\'s credentials.',
          partNumber: 1,
          wrongCount: 731,
          totalAttempts: 1284,
          wrongPercentage: 57.0,
          explanation: 'Skill: Word form (Adverb modifying adjective: favorably)',
        ),
        TopWrongQuestion(
          questionId: 181,
          questionNumber: 181,
          questionContent: 'What discount is offered for early registration?',
          partNumber: 3,
          wrongCount: 706,
          totalAttempts: 1284,
          wrongPercentage: 55.0,
          explanation: 'Skill: Detail · advertisement (Common chosen: A -> Correct: D)',
        ),
        TopWrongQuestion(
          questionId: 135,
          questionNumber: 135,
          questionContent: 'The IT team will _____ all computers over the weekend.',
          partNumber: 2,
          wrongCount: 667,
          totalAttempts: 1284,
          wrongPercentage: 52.0,
          explanation: 'Skill: Verb tense / Modal verb base form (Common: C -> Correct: A)',
        ),
        TopWrongQuestion(
          questionId: 127,
          questionNumber: 127,
          questionContent: 'Please submit invoices _____ the end of the fiscal quarter.',
          partNumber: 1,
          wrongCount: 629,
          totalAttempts: 1284,
          wrongPercentage: 49.0,
          explanation: 'Skill: Prepositions of deadline (Common: D -> Correct: B)',
        ),
        TopWrongQuestion(
          questionId: 163,
          questionNumber: 163,
          questionContent: 'In the letter, the word "prominent" is closest in meaning to:',
          partNumber: 3,
          wrongCount: 603,
          totalAttempts: 1284,
          wrongPercentage: 47.0,
          explanation: 'Skill: Vocabulary in context (Common: A -> Correct: C)',
        ),
        TopWrongQuestion(
          questionId: 145,
          questionNumber: 145,
          questionContent: '_____ the weather permits, the outdoor seminar will proceed.',
          partNumber: 2,
          wrongCount: 564,
          totalAttempts: 1284,
          wrongPercentage: 44.0,
          explanation: 'Skill: Text cohesion / Conjunction (Common: B -> Correct: D)',
        ),
      ],
    );
  }
}

