using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using backend.Toeic;
using backend.Toeic.Dto;
using backend.Toeic.WordParser;

namespace backend.Controllers
{
    [Route("api/[controller]/[action]")]
    public class ToeicUploadController : backendControllerBase
    {
        private readonly IExamAppService _examAppService;
        private readonly IToeicWordParserService _wordParserService;
        private readonly IWebHostEnvironment _env;

        public ToeicUploadController(
            IExamAppService examAppService,
            IToeicWordParserService wordParserService,
            IWebHostEnvironment env)
        {
            _examAppService = examAppService;
            _wordParserService = wordParserService;
            _env = env;
        }

        /// <summary>
        /// Upload file Word (.docx) qua Multipart Form Data
        /// </summary>
        [HttpPost]
        [Consumes("multipart/form-data")]
        public async Task<UploadExamResultDto> UploadDocx([FromForm] IFormFile file)
        {
            var formFile = file ?? (Request.Form.Files.Count > 0 ? Request.Form.Files[0] : null);

            if (formFile == null || formFile.Length == 0)
            {
                return new UploadExamResultDto
                {
                    IsSuccess = false,
                    Errors = { "Vui lòng chọn một file Word (.docx) để tải lên." }
                };
            }

            var ext = Path.GetExtension(formFile.FileName).ToLowerInvariant();
            if (ext != ".docx")
            {
                return new UploadExamResultDto
                {
                    IsSuccess = false,
                    Errors = { "Định dạng không hợp lệ. Hệ thống chỉ hỗ trợ file Word (.docx)." }
                };
            }

            byte[] fileBytes;
            using (var ms = new MemoryStream())
            {
                await formFile.CopyToAsync(ms);
                fileBytes = ms.ToArray();
            }

            string webRootPath = _env.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
            return await _examAppService.ImportExamFromDocx(formFile.FileName, fileBytes, webRootPath);
        }

        /// <summary>
        /// Upload file Word (.docx) mã hóa Base64 qua JSON
        /// </summary>
        [HttpPost]
        public async Task<UploadExamResultDto> UploadDocxBase64([FromBody] UploadDocxBase64Input input)
        {
            if (input == null || string.IsNullOrWhiteSpace(input.FileBase64))
            {
                return new UploadExamResultDto
                {
                    IsSuccess = false,
                    Errors = { "Dữ liệu file tải lên rỗng." }
                };
            }

            var fileName = string.IsNullOrWhiteSpace(input.FileName) ? "De_Thi_TOEIC.docx" : input.FileName;
            var ext = Path.GetExtension(fileName).ToLowerInvariant();
            if (ext != ".docx")
            {
                return new UploadExamResultDto
                {
                    IsSuccess = false,
                    Errors = { "Hệ thống chỉ hỗ trợ file Word (.docx)." }
                };
            }

            byte[] fileBytes;
            try
            {
                fileBytes = Convert.FromBase64String(input.FileBase64);
            }
            catch (Exception ex)
            {
                return new UploadExamResultDto
                {
                    IsSuccess = false,
                    Errors = { $"Lỗi giải mã Base64 file Word: {ex.Message}" }
                };
            }

            string webRootPath = _env.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
            return await _examAppService.ImportExamFromDocx(fileName, fileBytes, webRootPath);
        }

        /// <summary>
        /// Tải về file Word mẫu chuẩn TOEIC Reading (.docx)
        /// </summary>
        [HttpGet]
        public IActionResult DownloadSampleWord()
        {
            var bytes = _wordParserService.GenerateSampleDocx();
            return File(
                bytes,
                "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                "Mau_De_Thi_TOEIC_Reading_Chuan.docx"
            );
        }

        /// <summary>
        /// Lấy bảng tra cứu các thẻ Tags quy chuẩn cho đề thi TOEIC Reading
        /// </summary>
        [HttpGet]
        public IActionResult GetTagSpecification()
        {
            return Ok(new
            {
                Title = "Quy định Bộ Thẻ (Tags) Chuẩn Đề Thi TOEIC Reading (.docx)",
                Sections = new[]
                {
                    new
                    {
                        Category = "a) Thông tin đề thi & Cấu trúc câu hỏi, câu trả lời",
                        Tags = new[]
                        {
                            new { Tag = "[EXAM_TITLE: <Tên đề thi>]", Description = "Bắt buộc: Khai báo tiêu đề đề thi (Ví dụ: [EXAM_TITLE: TOEIC Reading Test 01])" },
                            new { Tag = "[EXAM_DURATION: <Số phút>]", Description = "Tùy chọn: Thời gian làm bài (Mặc định 75 phút)" },
                            new { Tag = "[PART: 5 | 6 | 7]", Description = "Bắt buộc: Khai báo phần thi TOEIC Part 5, Part 6 hoặc Part 7" },
                            new { Tag = "[GROUP_START] & [GROUP_END]", Description = "Bắt buộc cho Part 6 & 7: Nhóm các câu hỏi chung một bài đọc" },
                            new { Tag = "[PASSAGE_START] ... [PASSAGE_END]", Description = "Bắt buộc cho Part 6 & 7: Khối nội dung đoạn văn đọc hiểu" },
                            new { Tag = "[IMAGE: <Đường dẫn ảnh>]", Description = "Tùy chọn: Khai báo ảnh đính kèm trong bài đọc" },
                            new { Tag = "[Q: <Số câu>] <Nội dung câu hỏi>", Description = "Bắt buộc: Khai báo câu hỏi (Ví dụ: [Q: 101] What is ...?)" },
                            new { Tag = "[A] ... [B] ... [C] ... [D] ...", Description = "Bắt buộc: Bốn lựa chọn câu trả lời tương ứng A, B, C, D" }
                        }
                    },
                    new
                    {
                        Category = "b) Đáp án đúng",
                        Tags = new[]
                        {
                            new { Tag = "[KEY: A | B | C | D]", Description = "Bắt buộc: Chỉ định duy nhất 1 đáp án đúng cho mỗi câu hỏi (Đồng thời hỗ trợ [CORRECT: X], [ANSWER: X])" }
                        }
                    },
                    new
                    {
                        Category = "c) Gợi ý câu trả lời",
                        Tags = new[]
                        {
                            new { Tag = "[HINT: <Nội dung giải thích>]", Description = "Tùy chọn/Khuyến khích: Cung cấp gợi ý cách làm, ngữ pháp, từ vựng hoặc giải thích lý do chọn đáp án (Đồng thời hỗ trợ [EXPLAIN: ...])" }
                        }
                    },
                    new
                    {
                        Category = "d) Thẻ hoán vị câu hỏi",
                        Tags = new[]
                        {
                            new { Tag = "[SHUFFLE_QUESTIONS: TRUE | FALSE]", Description = "Đặt ở đầu Part hoặc trong nhóm [GROUP_START]. Khi TRUE, câu hỏi trong nhóm sẽ được hoán vị ngẫu nhiên cho từng sinh viên" }
                        }
                    },
                    new
                    {
                        Category = "e) Thẻ hoán vị câu trả lời",
                        Tags = new[]
                        {
                            new { Tag = "[SHUFFLE_ANSWERS: TRUE | FALSE]", Description = "Đặt ở đầu Part hoặc trước câu hỏi. Khi TRUE, thứ tự các phương án A, B, C, D sẽ được xáo trộn tự động khi sinh viên bắt đầu làm bài" }
                        }
                    }
                }
            });
        }
    }

    public class UploadDocxBase64Input
    {
        public string FileName { get; set; }
        public string FileBase64 { get; set; }
    }
}
