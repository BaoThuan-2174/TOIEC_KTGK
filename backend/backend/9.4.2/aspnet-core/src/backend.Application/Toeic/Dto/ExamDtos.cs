using System;
using System.Collections.Generic;
using Abp.Application.Services.Dto;

namespace backend.Toeic.Dto
{
    public class ExamListDto : EntityDto<int>
    {
        public string Title { get; set; }
        public string Description { get; set; }
        public int DurationMinutes { get; set; }
        public int TotalQuestions { get; set; }
        public bool IsPublished { get; set; }
        public DateTime? PublishedDate { get; set; }
        public DateTime CreationTime { get; set; }
        public int SubmissionCount { get; set; }
        public double AverageScore { get; set; }
    }

    public class ExamDetailDto : EntityDto<int>
    {
        public string Title { get; set; }
        public string Description { get; set; }
        public int DurationMinutes { get; set; }
        public int TotalQuestions { get; set; }
        public bool IsPublished { get; set; }
        public DateTime? PublishedDate { get; set; }
        public List<QuestionGroupDto> QuestionGroups { get; set; } = new List<QuestionGroupDto>();
    }

    public class QuestionGroupDto : EntityDto<int>
    {
        public int ExamId { get; set; }
        public ToeicPartType PartType { get; set; }
        public string PassageText { get; set; }
        public string PassageImages { get; set; }
        public int OrderIndex { get; set; }
        public bool AllowShuffleQuestions { get; set; }
        public List<QuestionDto> Questions { get; set; } = new List<QuestionDto>();
    }

    public class QuestionDto : EntityDto<int>
    {
        public int QuestionGroupId { get; set; }
        public int QuestionNumber { get; set; }
        public string Content { get; set; }
        public string Explanation { get; set; }
        public int OrderIndex { get; set; }
        public bool AllowShuffleAnswers { get; set; }
        public List<AnswerOptionDto> AnswerOptions { get; set; } = new List<AnswerOptionDto>();
    }

    public class AnswerOptionDto : EntityDto<int>
    {
        public int QuestionId { get; set; }
        public string Label { get; set; }
        public string Content { get; set; }
        public bool? IsCorrect { get; set; } // Nullable: hidden when sent to student taking exam!
        public int OrderIndex { get; set; }
    }
}
