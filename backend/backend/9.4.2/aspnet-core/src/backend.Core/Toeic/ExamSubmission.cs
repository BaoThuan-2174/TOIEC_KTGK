using System;
using System.Collections.Generic;
using Abp.Domain.Entities.Auditing;

namespace backend.Toeic
{
    public class ExamSubmission : FullAuditedEntity<int>
    {
        public int ExamId { get; set; }
        public virtual Exam Exam { get; set; }

        public string StudentName { get; set; }
        public string StudentCode { get; set; }
        public long? UserId { get; set; }

        public DateTime StartTime { get; set; }
        public DateTime SubmitTime { get; set; }
        public int TimeSpentSeconds { get; set; }

        public int CorrectCount { get; set; }
        public int WrongCount { get; set; }
        public int SkippedCount { get; set; }
        public double Score { get; set; }

        public virtual ICollection<SubmissionDetail> Details { get; set; }

        public ExamSubmission()
        {
            Details = new HashSet<SubmissionDetail>();
        }
    }
}
