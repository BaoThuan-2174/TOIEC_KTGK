using System.Collections.Generic;
using System.Threading.Tasks;
using Abp.Application.Services;
using Abp.Application.Services.Dto;
using backend.Toeic.Dto;

namespace backend.Toeic
{
    public interface IExamAppService : IApplicationService
    {
        Task<ListResultDto<ExamListDto>> GetAllExams();
        Task<List<ExamListDto>> GetPublishedExams();
        Task<ExamDetailDto> GetExamForEdit(int id);
        Task<ExamDetailDto> GetExamForStudent(int id);
        Task<UploadExamResultDto> ImportExamFromDocx(string fileName, byte[] fileBytes, string webRootPath);
        Task UpdateExam(ExamDetailDto input);
        Task PublishExam(PublishExamInput input);
        Task DeleteExam(int id);
        Task<ExamStatisticsDto> GetExamStatistics(int examId);
    }
}
