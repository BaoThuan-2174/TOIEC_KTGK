using Microsoft.EntityFrameworkCore;
using Abp.Zero.EntityFrameworkCore;
using backend.Authorization.Roles;
using backend.Authorization.Users;
using backend.MultiTenancy;

using backend.Toeic;

namespace backend.EntityFrameworkCore
{
    public class backendDbContext : AbpZeroDbContext<Tenant, Role, User, backendDbContext>
    {
        /* Define a DbSet for each entity of the application */
        public virtual DbSet<Exam> Exams { get; set; }
        public virtual DbSet<QuestionGroup> QuestionGroups { get; set; }
        public virtual DbSet<Question> Questions { get; set; }
        public virtual DbSet<AnswerOption> AnswerOptions { get; set; }
        public virtual DbSet<ExamSubmission> ExamSubmissions { get; set; }
        public virtual DbSet<SubmissionDetail> SubmissionDetails { get; set; }

        public backendDbContext(DbContextOptions<backendDbContext> options)
            : base(options)
        {
        }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.Entity<QuestionGroup>()
                .HasOne(qg => qg.Exam)
                .WithMany(e => e.QuestionGroups)
                .HasForeignKey(qg => qg.ExamId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Question>()
                .HasOne(q => q.QuestionGroup)
                .WithMany(g => g.Questions)
                .HasForeignKey(q => q.QuestionGroupId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<AnswerOption>()
                .HasOne(a => a.Question)
                .WithMany(q => q.AnswerOptions)
                .HasForeignKey(a => a.QuestionId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<SubmissionDetail>()
                .HasOne(sd => sd.ExamSubmission)
                .WithMany(s => s.Details)
                .HasForeignKey(sd => sd.ExamSubmissionId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<SubmissionDetail>()
                .HasOne(sd => sd.Question)
                .WithMany()
                .HasForeignKey(sd => sd.QuestionId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<SubmissionDetail>()
                .HasOne(sd => sd.SelectedAnswerOption)
                .WithMany()
                .HasForeignKey(sd => sd.SelectedAnswerOptionId)
                .OnDelete(DeleteBehavior.Restrict);
        }
    }
}
