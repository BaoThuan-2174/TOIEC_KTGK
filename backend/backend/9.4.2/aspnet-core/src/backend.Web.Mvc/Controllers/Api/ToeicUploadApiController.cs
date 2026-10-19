using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc;
using backend.Toeic;
using backend.Toeic.Dto;

namespace backend.Web.Controllers.Api
{
    /// <summary>
    /// API dành cho Flutter/Mobile: Upload đề thi dưới dạng Base64 (docx)
    /// Route: /api/ToeicUpload/...
    /// </summary>
    [ApiController]
    [Route("api/ToeicUpload")]
    public class ToeicUploadApiController : ControllerBase
    {
        private readonly IExamAppService _examAppService;
        private readonly IWebHostEnvironment _env;

        public ToeicUploadApiController(IExamAppService examAppService, IWebHostEnvironment env)
        {
            _examAppService = examAppService;
            _env = env;
        }

        /// <summary>
        /// Nhận file .docx encode dưới dạng Base64, parse và lưu vào database.
        /// Flutter gọi endpoint này để upload đề thi từ giảng viên.
        /// </summary>
        [HttpPost("UploadDocxBase64")]
        public async Task<ActionResult<ApiResponse<UploadExamResultDto>>> UploadDocxBase64([FromBody] UploadDocxBase64Input input)
        {
            if (input == null || string.IsNullOrWhiteSpace(input.FileBase64))
            {
                return Ok(new ApiResponse<UploadExamResultDto>
                {
                    Result = new UploadExamResultDto
                    {
                        IsSuccess = false,
                        Errors = { "Dữ liệu file không được để trống." }
                    }
                });
            }

            string ext = (Path.GetExtension(input.FileName ?? "") ?? "").ToLowerInvariant();
            if (ext != ".docx")
            {
                return Ok(new ApiResponse<UploadExamResultDto>
                {
                    Result = new UploadExamResultDto
                    {
                        IsSuccess = false,
                        Errors = { "Hệ thống chỉ chấp nhận file Word định dạng .docx." }
                    }
                });
            }

            byte[] fileBytes;
            try
            {
                fileBytes = Convert.FromBase64String(input.FileBase64);
            }
            catch (FormatException)
            {
                return Ok(new ApiResponse<UploadExamResultDto>
                {
                    Result = new UploadExamResultDto
                    {
                        IsSuccess = false,
                        Errors = { "Dữ liệu Base64 không hợp lệ." }
                    }
                });
            }

            string webRootPath = _env.WebRootPath
                ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");

            var result = await _examAppService.ImportExamFromDocx(input.FileName, fileBytes, webRootPath);

            return Ok(new ApiResponse<UploadExamResultDto> { Result = result });
        }

        /// <summary>
        /// Tải file Word mẫu chuẩn TOEIC Reading để giảng viên điền nội dung.
        /// </summary>
        [HttpGet("DownloadSampleWord")]
        public IActionResult DownloadSampleWord()
        {
            using var ms = new MemoryStream();
            using (var wordDoc = DocumentFormat.OpenXml.Packaging.WordprocessingDocument.Create(
                ms, DocumentFormat.OpenXml.WordprocessingDocumentType.Document, true))
            {
                var mainPart = wordDoc.AddMainDocumentPart();
                mainPart.Document = new DocumentFormat.OpenXml.Wordprocessing.Document();
                var body = mainPart.Document.AppendChild(new DocumentFormat.OpenXml.Wordprocessing.Body());

                void AddP(string text)
                {
                    var p = body.AppendChild(new DocumentFormat.OpenXml.Wordprocessing.Paragraph());
                    var r = p.AppendChild(new DocumentFormat.OpenXml.Wordprocessing.Run());
                    r.AppendChild(new DocumentFormat.OpenXml.Wordprocessing.Text(text));
                }

                AddP("[EXAM_TITLE: Đề thi TOEIC Reading Thực hành Chuẩn 01]");
                AddP("[EXAM_DURATION: 75]");
                AddP("");
                AddP("[PART: 5]");
                AddP("[SHUFFLE_QUESTIONS: TRUE]");
                AddP("[SHUFFLE_ANSWERS: TRUE]");
                AddP("");
                AddP("[Q: 101] Ms. Durkin asked for volunteers to help -------- with the employee fitness program.");
                AddP("[A] she");
                AddP("[B] her");
                AddP("[C] hers");
                AddP("[D] herself");
                AddP("[KEY: B]");
                AddP("[EXPLAIN: Đại từ tân ngữ 'her' làm bổ ngữ cho động từ 'help'.]");
                AddP("");
                AddP("[Q: 102] Lasner Electronics' online service station allows customers to -------- their order status.");
                AddP("[A] track");
                AddP("[B] form");
                AddP("[C] save");
                AddP("[D] enter");
                AddP("[KEY: A]");
                AddP("[EXPLAIN: track one's order status = theo dõi trạng thái đơn hàng.]");
                AddP("");
                AddP("[PART: 6]");
                AddP("[GROUP_START]");
                AddP("[SHUFFLE_QUESTIONS: FALSE]");
                AddP("[SHUFFLE_ANSWERS: TRUE]");
                AddP("[PASSAGE_START]");
                AddP("With Global Strength Gym's 30-day trial period, you get the opportunity to try out our classes, equipment, and facilities. -------- [131]. It's completely risk-free!");
                AddP("[PASSAGE_END]");
                AddP("");
                AddP("[Q: 131]");
                AddP("[A] Throughout the trial, you pay nothing and sign no contract.");
                AddP("[B] Weight-lifting classes are not currently available.");
                AddP("[C] A cash deposit is required when you sign up for membership.");
                AddP("[D] All questions should be e-mailed to customerservice@gsgym.com.");
                AddP("[KEY: A]");
                AddP("[EXPLAIN: Câu A phù hợp ngữ cảnh 'risk-free'.]");
                AddP("[GROUP_END]");
                AddP("");
                AddP("[PART: 7]");
                AddP("[GROUP_START]");
                AddP("[SHUFFLE_QUESTIONS: FALSE]");
                AddP("[SHUFFLE_ANSWERS: TRUE]");
                AddP("[PASSAGE_START]");
                AddP("Notice: Sparkle Cleaners will be adjusting its operating hours starting next Monday. Our new schedule will be from 7:00 A.M. to 8:00 P.M., Monday through Saturday.");
                AddP("[PASSAGE_END]");
                AddP("");
                AddP("[Q: 147] What is the purpose of the notice?");
                AddP("[A] To advertise a discount on dry cleaning");
                AddP("[B] To announce changes in store hours");
                AddP("[C] To introduce a new delivery service");
                AddP("[D] To inform customers about a store relocation");
                AddP("[KEY: B]");
                AddP("[EXPLAIN: Thông báo nhằm thông báo thay đổi giờ mở cửa cửa hàng.]");
                AddP("[GROUP_END]");

                mainPart.Document.Save();
            }

            return File(ms.ToArray(),
                "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                "Mau_De_Thi_TOEIC_Reading_Chuan.docx");
        }

        /// <summary>
        /// Trả về danh sách tag và quy định định dạng file Word chuẩn
        /// </summary>
        [HttpGet("GetTagSpecification")]
        public ActionResult<ApiResponse<object>> GetTagSpecification()
        {
            var spec = new
            {
                version = "1.0",
                description = "Quy định tag chuẩn cho file Word đề thi TOEIC Reading",
                tags = new[]
                {
                    new { tag = "[EXAM_TITLE: ...]", required = true, description = "Tiêu đề đề thi" },
                    new { tag = "[EXAM_DURATION: 75]", required = false, description = "Thời gian làm bài (phút)" },
                    new { tag = "[PART: 5|6|7]", required = true, description = "Phần thi (5, 6 hoặc 7)" },
                    new { tag = "[Q: 101] nội dung câu hỏi", required = true, description = "Câu hỏi với số thứ tự" },
                    new { tag = "[A] | [B] | [C] | [D]", required = true, description = "Các lựa chọn đáp án" },
                    new { tag = "[KEY: A|B|C|D]", required = true, description = "Đáp án đúng" },
                    new { tag = "[EXPLAIN: ...]", required = false, description = "Giải thích đáp án" },
                    new { tag = "[GROUP_START] ... [GROUP_END]", required = false, description = "Nhóm câu hỏi Part 6/7 với chung đoạn văn" },
                    new { tag = "[PASSAGE_START] ... [PASSAGE_END]", required = false, description = "Đoạn văn đọc hiểu" },
                    new { tag = "[SHUFFLE_QUESTIONS: TRUE|FALSE]", required = false, description = "Xáo trộn thứ tự câu hỏi" },
                    new { tag = "[SHUFFLE_ANSWERS: TRUE|FALSE]", required = false, description = "Xáo trộn thứ tự đáp án" },
                }
            };

            return Ok(new ApiResponse<object> { Result = spec });
        }
    }

    public class UploadDocxBase64Input
    {
        public string FileName { get; set; }
        public string FileBase64 { get; set; }
    }

    public class ApiResponse<T>
    {
        public T Result { get; set; }
    }
}
