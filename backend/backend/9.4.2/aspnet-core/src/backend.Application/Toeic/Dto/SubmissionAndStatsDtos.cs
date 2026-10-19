using System;
using System.Collections.Generic;
using Abp.Application.Services.Dto;

namespace backend.Toeic.Dto
{
    public class SubmitExamInput
    {
        public int ExamId { get; set; }
        public string StudentName { get; set; }
        public string StudentCode { get; set; }
        public DateTime StartTime { get; set; }
        public int TimeSpentSeconds { get; set; }
        public List<StudentAnswerInput> Answers { get; set; } = new List<StudentAnswerInput>();
    }

    public class StudentAnswerInput
    {
        public int QuestionId { get; set; }
        public int? SelectedAnswerOptionId { get; set; } // Null if skipped
    }

    public class SubmissionResultDto : EntityDto<int>
    {
        public int ExamId { get; set; }
        public string ExamTitle { get; set; }
        public string StudentName { get; set; }
        public int CorrectCount { get; set; }
        public int WrongCount { get; set; }
        public int SkippedCount { get; set; }
        public int TotalQuestions { get; set; }
        public double Score { get; set; }
        public int TimeSpentSeconds { get; set; }
        public DateTime SubmitTime { get; set; }
    }

    public class SubmissionReviewDto : SubmissionResultDto
    {
        public List<SubmissionDetailReviewDto> Details { get; set; } = new List<SubmissionDetailReviewDto>();
    }

    public class SubmissionDetailReviewDto
    {
        public int QuestionId { get; set; }
        public int QuestionNumber { get; set; }
        public string QuestionContent { get; set; }
        public string Explanation { get; set; }
        public int? SelectedOptionId { get; set; }
        public string SelectedOptionLabel { get; set; }
        public int CorrectOptionId { get; set; }
        public string CorrectOptionLabel { get; set; }
        public bool IsCorrect { get; set; }
        public List<AnswerOptionDto> Options { get; set; } = new List<AnswerOptionDto>();
    }

    public class ExamStatisticsDto
    {
        public int ExamId { get; set; }
        public string ExamTitle { get; set; }
        public int TotalSubmissions { get; set; }
        public double AverageScore { get; set; }
        public double HighestScore { get; set; }
        public double LowestScore { get; set; }
        public List<TopWrongQuestionDto> TopWrongQuestions { get; set; } = new List<TopWrongQuestionDto>();
    }

    public class TopWrongQuestionDto
    {
        public int QuestionId { get; set; }
        public int QuestionNumber { get; set; }
        public string QuestionContent { get; set; }
        public int PartNumber { get; set; }
        public int WrongCount { get; set; }
        public int TotalAttempts { get; set; }
        public double WrongPercentage { get; set; }
        public string Explanation { get; set; }
    }

    public class UploadExamResultDto
    {
        public bool IsSuccess { get; set; }
        public int? ExamId { get; set; }
        public string ExamTitle { get; set; }
        public int TotalQuestions { get; set; }
        public List<string> Errors { get; set; } = new List<string>();
    }

    public class PublishExamInput
    {
        public int Id { get; set; }
        public bool IsPublished { get; set; }
    }
}
