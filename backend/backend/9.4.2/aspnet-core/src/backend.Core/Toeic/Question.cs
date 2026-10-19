using System.Collections.Generic;
using Abp.Domain.Entities.Auditing;

namespace backend.Toeic
{
    public class Question : FullAuditedEntity<int>
    {
        public int QuestionGroupId { get; set; }
        public virtual QuestionGroup QuestionGroup { get; set; }

        public int QuestionNumber { get; set; }
        public string Content { get; set; }
        public string Explanation { get; set; }
        public int OrderIndex { get; set; }

        public bool AllowShuffleAnswers { get; set; } = false;

        public virtual ICollection<AnswerOption> AnswerOptions { get; set; }

        public Question()
        {
            AnswerOptions = new HashSet<AnswerOption>();
        }
    }
}
