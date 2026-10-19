using System.Collections.Generic;
using Abp.Domain.Entities.Auditing;

namespace backend.Toeic
{
    public class QuestionGroup : FullAuditedEntity<int>
    {
        public int ExamId { get; set; }
        public virtual Exam Exam { get; set; }

        public ToeicPartType PartType { get; set; }
        public string PassageText { get; set; }
        public string PassageImages { get; set; }
        public int OrderIndex { get; set; }

        public bool AllowShuffleQuestions { get; set; } = false;

        public virtual ICollection<Question> Questions { get; set; }

        public QuestionGroup()
        {
            Questions = new HashSet<Question>();
        }
    }
}
