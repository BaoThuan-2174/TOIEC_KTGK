using Abp.Domain.Entities.Auditing;

namespace backend.Toeic
{
    public class AnswerOption : FullAuditedEntity<int>
    {
        public int QuestionId { get; set; }
        public virtual Question Question { get; set; }

        public string Label { get; set; } // A, B, C, D
        public string Content { get; set; }
        public bool IsCorrect { get; set; }
        public int OrderIndex { get; set; }
    }
}
