using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Abp.Domain.Repositories;
using Abp.UI;
using Microsoft.EntityFrameworkCore;
using backend.Toeic.Dto;

namespace backend.Toeic
{
    public class ExamSubmissionAppService : backendAppServiceBase, IExamSubmissionAppService
    {
        private readonly IRepository<Exam, int> _examRepository;
        private readonly IRepository<ExamSubmission, int> _submissionRepository;
        private readonly IRepository<SubmissionDetail, int> _submissionDetailRepository;
        private readonly IRepository<Question, int> _questionRepository;
        private readonly IRepository<AnswerOption, int> _answerOptionRepository;

        public ExamSubmissionAppService(
            IRepository<Exam, int> examRepository,
            IRepository<ExamSubmission, int> submissionRepository,
            IRepository<SubmissionDetail, int> submissionDetailRepository,
            IRepository<Question, int> questionRepository,
            IRepository<AnswerOption, int> answerOptionRepository)
        {
            _examRepository = examRepository;
            _submissionRepository = submissionRepository;
            _submissionDetailRepository = submissionDetailRepository;
            _questionRepository = questionRepository;
            _answerOptionRepository = answerOptionRepository;
        }

        public async Task<SubmissionResultDto> SubmitExam(SubmitExamInput input)
        {
            var exam = await _examRepository.GetAll()
                .Include(e => e.QuestionGroups)
                    .ThenInclude(g => g.Questions)
                        .ThenInclude(q => q.AnswerOptions)
                .FirstOrDefaultAsync(e => e.Id == input.ExamId);

            if (exam == null)
            {
                throw new UserFriendlyException("Đề thi không tồn tại.");
            }

            var allQuestions = exam.QuestionGroups.SelectMany(g => g.Questions).ToList();
            var submission = new ExamSubmission
            {
                ExamId = exam.Id,
                StudentName = string.IsNullOrWhiteSpace(input.StudentName) ? "Thí sinh" : input.StudentName.Trim(),
                StudentCode = input.StudentCode?.Trim(),
                StartTime = input.StartTime,
                SubmitTime = DateTime.Now,
                TimeSpentSeconds = input.TimeSpentSeconds,
                UserId = AbpSession.UserId
            };

            int correct = 0;
            int wrong = 0;
            int skipped = 0;

            var answersMap = input.Answers.ToDictionary(a => a.QuestionId, a => a.SelectedAnswerOptionId);

            foreach (var q in allQuestions)
            {
                var correctOption = q.AnswerOptions.FirstOrDefault(o => o.IsCorrect);
                int? selectedOptId = answersMap.ContainsKey(q.Id) ? answersMap[q.Id] : null;

                bool isCorrect = false;
                if (!selectedOptId.HasValue)
                {
                    skipped++;
                }
                else if (correctOption != null && selectedOptId.Value == correctOption.Id)
                {
                    correct++;
                    isCorrect = true;
                }
                else
                {
                    wrong++;
                }

                submission.Details.Add(new SubmissionDetail
                {
                    QuestionId = q.Id,
                    SelectedAnswerOptionId = selectedOptId,
                    IsCorrect = isCorrect
                });
            }

            submission.CorrectCount = correct;
            submission.WrongCount = wrong;
            submission.SkippedCount = skipped;
            // Score: phần trăm câu đúng (thang 0-100) khớp với màn hình kết quả Flutter
            submission.Score = Math.Round((double)correct / (allQuestions.Count > 0 ? allQuestions.Count : 1) * 100, 1);

            await _submissionRepository.InsertAsync(submission);
            await CurrentUnitOfWork.SaveChangesAsync();

            return new SubmissionResultDto
            {
                Id = submission.Id,
                ExamId = exam.Id,
                ExamTitle = exam.Title,
                StudentName = submission.StudentName,
                CorrectCount = correct,
                WrongCount = wrong,
                SkippedCount = skipped,
                TotalQuestions = allQuestions.Count,
                Score = submission.Score,
                TimeSpentSeconds = submission.TimeSpentSeconds,
                SubmitTime = submission.SubmitTime
            };
        }

        public async Task<SubmissionReviewDto> GetSubmissionReview(int submissionId)
        {
            var submission = await _submissionRepository.GetAll()
                .Include(s => s.Exam)
                .Include(s => s.Details)
                    .ThenInclude(d => d.Question)
                        .ThenInclude(q => q.AnswerOptions)
                .Include(s => s.Details)
                    .ThenInclude(d => d.SelectedAnswerOption)
                .FirstOrDefaultAsync(s => s.Id == submissionId);

            if (submission == null)
            {
                throw new UserFriendlyException("Không tìm thấy kết quả bài thi.");
            }

            var review = new SubmissionReviewDto
            {
                Id = submission.Id,
                ExamId = submission.ExamId,
                ExamTitle = submission.Exam.Title,
                StudentName = submission.StudentName,
                CorrectCount = submission.CorrectCount,
                WrongCount = submission.WrongCount,
                SkippedCount = submission.SkippedCount,
                TotalQuestions = submission.Details.Count,
                Score = submission.Score,
                TimeSpentSeconds = submission.TimeSpentSeconds,
                SubmitTime = submission.SubmitTime
            };

            foreach (var detail in submission.Details.OrderBy(d => d.Question.QuestionNumber))
            {
                var q = detail.Question;
                var correctOpt = q.AnswerOptions.FirstOrDefault(o => o.IsCorrect);

                review.Details.Add(new SubmissionDetailReviewDto
                {
                    QuestionId = q.Id,
                    QuestionNumber = q.QuestionNumber,
                    QuestionContent = q.Content,
                    Explanation = q.Explanation,
                    SelectedOptionId = detail.SelectedAnswerOptionId,
                    SelectedOptionLabel = detail.SelectedAnswerOption?.Label,
                    CorrectOptionId = correctOpt?.Id ?? 0,
                    CorrectOptionLabel = correctOpt?.Label ?? "",
                    IsCorrect = detail.IsCorrect,
                    Options = q.AnswerOptions
                        .OrderBy(o => o.OrderIndex)
                        .Select(o => new AnswerOptionDto
                        {
                            Id = o.Id,
                            QuestionId = o.QuestionId,
                            Label = o.Label,
                            Content = o.Content,
                            IsCorrect = o.IsCorrect,
                            OrderIndex = o.OrderIndex
                        }).ToList()
                });
            }

            return review;
        }
    }
}
