using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Abp.Application.Services.Dto;
using Abp.Domain.Repositories;
using Abp.UI;
using Microsoft.EntityFrameworkCore;
using backend.Toeic.Dto;
using backend.Toeic.WordParser;

namespace backend.Toeic
{
    public class ExamAppService : backendAppServiceBase, IExamAppService
    {
        private readonly IRepository<Exam, int> _examRepository;
        private readonly IRepository<QuestionGroup, int> _groupRepository;
        private readonly IRepository<Question, int> _questionRepository;
        private readonly IRepository<AnswerOption, int> _answerRepository;
        private readonly IRepository<ExamSubmission, int> _submissionRepository;
        private readonly IRepository<SubmissionDetail, int> _submissionDetailRepository;
        private readonly IToeicWordParserService _wordParserService;

        public ExamAppService(
            IRepository<Exam, int> examRepository,
            IRepository<QuestionGroup, int> groupRepository,
            IRepository<Question, int> questionRepository,
            IRepository<AnswerOption, int> answerRepository,
            IRepository<ExamSubmission, int> submissionRepository,
            IRepository<SubmissionDetail, int> submissionDetailRepository,
            IToeicWordParserService wordParserService)
        {
            _examRepository = examRepository;
            _groupRepository = groupRepository;
            _questionRepository = questionRepository;
            _answerRepository = answerRepository;
            _submissionRepository = submissionRepository;
            _submissionDetailRepository = submissionDetailRepository;
            _wordParserService = wordParserService;
        }

        public async Task<ListResultDto<ExamListDto>> GetAllExams()
        {
            var exams = await _examRepository.GetAll()
                .Include(e => e.Submissions)
                .OrderByDescending(e => e.CreationTime)
                .ToListAsync();

            var dtos = exams.Select(e => new ExamListDto
            {
                Id = e.Id,
                Title = e.Title,
                Description = e.Description,
                DurationMinutes = e.DurationMinutes,
                TotalQuestions = e.TotalQuestions,
                IsPublished = e.IsPublished,
                PublishedDate = e.PublishedDate,
                CreationTime = e.CreationTime,
                SubmissionCount = e.Submissions.Count,
                AverageScore = e.Submissions.Count > 0 ? Math.Round(e.Submissions.Average(s => s.Score), 1) : 0
            }).ToList();

            return new ListResultDto<ExamListDto>(dtos);
        }

        public async Task<List<ExamListDto>> GetPublishedExams()
        {
            var exams = await _examRepository.GetAll()
                .Where(e => e.IsPublished)
                .OrderByDescending(e => e.PublishedDate ?? e.CreationTime)
                .ToListAsync();

            return exams.Select(e => new ExamListDto
            {
                Id = e.Id,
                Title = e.Title,
                Description = e.Description,
                DurationMinutes = e.DurationMinutes,
                TotalQuestions = e.TotalQuestions,
                IsPublished = e.IsPublished,
                PublishedDate = e.PublishedDate,
                CreationTime = e.CreationTime
            }).ToList();
        }

        public async Task<ExamDetailDto> GetExamForEdit(int id)
        {
            var exam = await _examRepository.GetAll()
                .Include(e => e.QuestionGroups)
                    .ThenInclude(g => g.Questions)
                        .ThenInclude(q => q.AnswerOptions)
                .FirstOrDefaultAsync(e => e.Id == id);

            if (exam == null)
            {
                throw new UserFriendlyException("Không tìm thấy đề thi.");
            }

            return MapToExamDetailDto(exam, isForStudent: false);
        }

        public async Task<ExamDetailDto> GetExamForStudent(int id)
        {
            var exam = await _examRepository.GetAll()
                .Include(e => e.QuestionGroups)
                    .ThenInclude(g => g.Questions)
                        .ThenInclude(q => q.AnswerOptions)
                .FirstOrDefaultAsync(e => e.Id == id);

            if (exam == null || !exam.IsPublished)
            {
                throw new UserFriendlyException("Đề thi chưa được xuất bản hoặc không tồn tại.");
            }

            var dto = MapToExamDetailDto(exam, isForStudent: true);

            // Apply Question and Answer Shuffling if allowed
            var rnd = new Random();
            foreach (var group in dto.QuestionGroups)
            {
                if (group.AllowShuffleQuestions && group.Questions.Count > 1)
                {
                    group.Questions = group.Questions.OrderBy(_ => rnd.Next()).ToList();
                }

                foreach (var q in group.Questions)
                {
                    if (q.AllowShuffleAnswers && q.AnswerOptions.Count > 1)
                    {
                        var shuffled = q.AnswerOptions.OrderBy(_ => rnd.Next()).ToList();
                        // Re-label to A, B, C, D in presentation order
                        string[] labels = { "A", "B", "C", "D" };
                        for (int i = 0; i < shuffled.Count && i < labels.Length; i++)
                        {
                            shuffled[i].Label = labels[i];
                        }
                        q.AnswerOptions = shuffled;
                    }
                }
            }

            return dto;
        }

        public async Task<UploadExamResultDto> ImportExamFromDocx(string fileName, byte[] fileBytes, string webRootPath)
        {
            var result = new UploadExamResultDto();

            if (fileBytes == null || fileBytes.Length == 0)
            {
                result.IsSuccess = false;
                result.Errors.Add("File không có dữ liệu.");
                return result;
            }

            string imageFolder = Path.Combine(webRootPath, "uploads", "toeic");

            using (var ms = new MemoryStream(fileBytes))
            {
                var parseResult = _wordParserService.ParseDocx(ms, imageFolder, "/uploads/toeic/");

                if (!parseResult.IsSuccess || parseResult.Errors.Count > 0)
                {
                    result.IsSuccess = false;
                    result.Errors = parseResult.Errors;
                    return result;
                }

                var exam = parseResult.ParsedExam;
                if (string.IsNullOrWhiteSpace(exam.Title))
                {
                    exam.Title = Path.GetFileNameWithoutExtension(fileName);
                }

                await _examRepository.InsertAsync(exam);
                await CurrentUnitOfWork.SaveChangesAsync();

                result.IsSuccess = true;
                result.ExamId = exam.Id;
                result.ExamTitle = exam.Title;
                result.TotalQuestions = exam.TotalQuestions;
                return result;
            }
        }

        public async Task UpdateExam(ExamDetailDto input)
        {
            var exam = await _examRepository.GetAll()
                .Include(e => e.QuestionGroups)
                    .ThenInclude(g => g.Questions)
                        .ThenInclude(q => q.AnswerOptions)
                .FirstOrDefaultAsync(e => e.Id == input.Id);

            if (exam == null)
            {
                throw new UserFriendlyException("Không tìm thấy đề thi.");
            }

            exam.Title = input.Title;
            exam.Description = input.Description;
            exam.DurationMinutes = input.DurationMinutes;

            foreach (var groupDto in input.QuestionGroups)
            {
                var group = exam.QuestionGroups.FirstOrDefault(g => g.Id == groupDto.Id);
                if (group != null)
                {
                    group.PassageText = groupDto.PassageText;
                    group.PassageImages = groupDto.PassageImages;
                    group.AllowShuffleQuestions = groupDto.AllowShuffleQuestions;

                    foreach (var qDto in groupDto.Questions)
                    {
                        var q = group.Questions.FirstOrDefault(x => x.Id == qDto.Id);
                        if (q != null)
                        {
                            q.Content = qDto.Content;
                            q.Explanation = qDto.Explanation;
                            q.AllowShuffleAnswers = qDto.AllowShuffleAnswers;

                            foreach (var optDto in qDto.AnswerOptions)
                            {
                                var opt = q.AnswerOptions.FirstOrDefault(o => o.Id == optDto.Id);
                                if (opt != null)
                                {
                                    opt.Content = optDto.Content;
                                    if (optDto.IsCorrect.HasValue)
                                    {
                                        opt.IsCorrect = optDto.IsCorrect.Value;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            await _examRepository.UpdateAsync(exam);
        }

        public async Task PublishExam(PublishExamInput input)
        {
            var exam = await _examRepository.GetAsync(input.Id);
            exam.IsPublished = input.IsPublished;
            exam.PublishedDate = input.IsPublished ? DateTime.Now : null;
            await _examRepository.UpdateAsync(exam);
        }

        public async Task DeleteExam(int id)
        {
            await _examRepository.DeleteAsync(id);
        }

        public async Task<ExamStatisticsDto> GetExamStatistics(int examId)
        {
            var exam = await _examRepository.GetAll()
                .Include(e => e.Submissions)
                .FirstOrDefaultAsync(e => e.Id == examId);

            if (exam == null)
            {
                throw new UserFriendlyException("Không tìm thấy đề thi.");
            }

            var submissions = exam.Submissions.ToList();
            var stats = new ExamStatisticsDto
            {
                ExamId = exam.Id,
                ExamTitle = exam.Title,
                TotalSubmissions = submissions.Count,
                AverageScore = submissions.Count > 0 ? Math.Round(submissions.Average(s => s.Score), 1) : 0,
                HighestScore = submissions.Count > 0 ? submissions.Max(s => s.Score) : 0,
                LowestScore = submissions.Count > 0 ? submissions.Min(s => s.Score) : 0
            };

            if (submissions.Count == 0)
            {
                return stats;
            }

            // Top 10 câu hỏi nhiều sinh viên làm sai nhất
            var wrongDetails = await _submissionDetailRepository.GetAll()
                .Include(sd => sd.Question)
                    .ThenInclude(q => q.QuestionGroup)
                .Where(sd => sd.ExamSubmission.ExamId == examId && !sd.IsCorrect)
                .GroupBy(sd => sd.QuestionId)
                .Select(g => new
                {
                    QuestionId = g.Key,
                    WrongCount = g.Count(),
                    Question = g.First().Question
                })
                .OrderByDescending(x => x.WrongCount)
                .Take(10)
                .ToListAsync();

            stats.TopWrongQuestions = wrongDetails.Select(x => new TopWrongQuestionDto
            {
                QuestionId = x.QuestionId,
                QuestionNumber = x.Question.QuestionNumber,
                QuestionContent = x.Question.Content,
                PartNumber = (int)x.Question.QuestionGroup.PartType,
                WrongCount = x.WrongCount,
                TotalAttempts = submissions.Count,
                WrongPercentage = Math.Round((double)x.WrongCount / submissions.Count * 100, 1),
                Explanation = x.Question.Explanation
            }).ToList();

            return stats;
        }

        private ExamDetailDto MapToExamDetailDto(Exam exam, bool isForStudent)
        {
            return new ExamDetailDto
            {
                Id = exam.Id,
                Title = exam.Title,
                Description = exam.Description,
                DurationMinutes = exam.DurationMinutes,
                TotalQuestions = exam.TotalQuestions,
                IsPublished = exam.IsPublished,
                PublishedDate = exam.PublishedDate,
                QuestionGroups = exam.QuestionGroups
                    .OrderBy(g => g.OrderIndex)
                    .Select(g => new QuestionGroupDto
                    {
                        Id = g.Id,
                        ExamId = g.ExamId,
                        PartType = g.PartType,
                        PassageText = g.PassageText,
                        PassageImages = g.PassageImages,
                        OrderIndex = g.OrderIndex,
                        AllowShuffleQuestions = g.AllowShuffleQuestions,
                        Questions = g.Questions
                            .OrderBy(q => q.OrderIndex)
                            .ThenBy(q => q.QuestionNumber)
                            .Select(q => new QuestionDto
                            {
                                Id = q.Id,
                                QuestionGroupId = q.QuestionGroupId,
                                QuestionNumber = q.QuestionNumber,
                                Content = q.Content,
                                Explanation = isForStudent ? null : q.Explanation,
                                OrderIndex = q.OrderIndex,
                                AllowShuffleAnswers = q.AllowShuffleAnswers,
                                AnswerOptions = q.AnswerOptions
                                    .OrderBy(o => o.OrderIndex)
                                    .ThenBy(o => o.Label)
                                    .Select(o => new AnswerOptionDto
                                    {
                                        Id = o.Id,
                                        QuestionId = o.QuestionId,
                                        Label = o.Label,
                                        Content = o.Content,
                                        IsCorrect = isForStudent ? null : o.IsCorrect,
                                        OrderIndex = o.OrderIndex
                                    }).ToList()
                            }).ToList()
                    }).ToList()
            };
        }
    }
}
