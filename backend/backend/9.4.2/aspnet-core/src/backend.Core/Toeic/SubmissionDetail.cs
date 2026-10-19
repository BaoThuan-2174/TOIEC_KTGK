using Abp.Domain.Entities.Auditing;

namespace backend.Toeic
{
    public class SubmissionDetail : FullAuditedEntity<int>
    {
        public int ExamSubmissionId { get; set; }
        public virtual ExamSubmission ExamSubmission { get; set; }

        public int QuestionId { get; set; }
        public virtual Question Question { get; set; }

        public int? SelectedAnswerOptionId { get; set; }
        public virtual AnswerOption SelectedAnswerOption { get; set; }

        public bool IsCorrect { get; set; }
    }
}
