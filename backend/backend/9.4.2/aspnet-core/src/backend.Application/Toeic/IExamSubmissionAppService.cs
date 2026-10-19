using System.Threading.Tasks;
using Abp.Application.Services;
using backend.Toeic.Dto;

namespace backend.Toeic
{
    public interface IExamSubmissionAppService : IApplicationService
    {
        Task<SubmissionResultDto> SubmitExam(SubmitExamInput input);
        Task<SubmissionReviewDto> GetSubmissionReview(int submissionId);
    }
}
