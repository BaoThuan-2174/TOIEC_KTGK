using System;
using System.Collections.Generic;
using Abp.Domain.Entities.Auditing;

namespace backend.Toeic
{
    public class Exam : FullAuditedEntity<int>
    {
        public string Title { get; set; }
        public string Description { get; set; }
        public int DurationMinutes { get; set; } = 75;
        public int TotalQuestions { get; set; } = 100;
        public bool IsPublished { get; set; } = false;
        public DateTime? PublishedDate { get; set; }

        public virtual ICollection<QuestionGroup> QuestionGroups { get; set; }
        public virtual ICollection<ExamSubmission> Submissions { get; set; }

        public Exam()
        {
            QuestionGroups = new HashSet<QuestionGroup>();
            Submissions = new HashSet<ExamSubmission>();
        }
    }
}
