using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Cors;
using Microsoft.AspNetCore.Mvc;
using backend.Toeic;
using backend.Toeic.Dto;

namespace backend.Web.Controllers.Api
{
    [ApiController]
    [Route("api/mobile")]
    public class MobileExamApiController : ControllerBase
    {
        private readonly IExamAppService _examAppService;
        private readonly IExamSubmissionAppService _submissionAppService;

        public MobileExamApiController(
            IExamAppService examAppService,
            IExamSubmissionAppService submissionAppService)
        {
            _examAppService = examAppService;
            _submissionAppService = submissionAppService;
        }

        /// <summary>
        /// Lấy danh sách các đề thi đã xuất bản cho thí sinh
        /// </summary>
        [HttpGet("exams")]
        public async Task<ActionResult<List<ExamListDto>>> GetPublishedExams()
        {
            var exams = await _examAppService.GetPublishedExams();
            return Ok(exams);
        }

        /// <summary>
        /// Lấy chi tiết đề thi để làm bài (đã ẩn đáp án đúng, áp dụng hoán vị nếu có)
        /// </summary>
        [HttpGet("exam/{id}")]
        public async Task<ActionResult<ExamDetailDto>> GetExamForStudent(int id)
        {
            var exam = await _examAppService.GetExamForStudent(id);
            return Ok(exam);
        }

        /// <summary>
        /// Nộp bài thi và nhận kết quả tự động chấm điểm
        /// </summary>
        [HttpPost("submit")]
        public async Task<ActionResult<SubmissionResultDto>> SubmitExam([FromBody] SubmitExamInput input)
        {
            if (input == null || input.ExamId <= 0)
            {
                return BadRequest("Dữ liệu nộp bài không hợp lệ.");
            }

            var result = await _submissionAppService.SubmitExam(input);
            return Ok(result);
        }

        /// <summary>
        /// Xem lại chi tiết bài thi đã nộp (câu đúng, câu sai, đáp án đúng và lời giải)
        /// </summary>
        [HttpGet("review/{submissionId}")]
        public async Task<ActionResult<SubmissionReviewDto>> GetSubmissionReview(int submissionId)
        {
            var review = await _submissionAppService.GetSubmissionReview(submissionId);
            return Ok(review);
        }
    }
}
