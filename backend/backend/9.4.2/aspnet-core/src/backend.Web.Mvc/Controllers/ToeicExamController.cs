using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Abp.AspNetCore.Mvc.Authorization;
using backend.Controllers;
using backend.Toeic;
using backend.Toeic.Dto;

namespace backend.Web.Controllers
{
    public class ToeicExamController : backendControllerBase
    {
        private readonly IExamAppService _examAppService;
        private readonly IWebHostEnvironment _env;

        public ToeicExamController(IExamAppService examAppService, IWebHostEnvironment env)
        {
            _examAppService = examAppService;
            _env = env;
        }

        public async Task<IActionResult> Index()
        {
            var result = await _examAppService.GetAllExams();
            return View(result.Items);
        }

        [HttpGet]
        public IActionResult Upload()
        {
            return View();
        }

        [HttpGet]
        public IActionResult DownloadSampleWord()
        {
            using (var ms = new MemoryStream())
            {
                using (var wordDoc = DocumentFormat.OpenXml.Packaging.WordprocessingDocument.Create(ms, DocumentFormat.OpenXml.WordprocessingDocumentType.Document, true))
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
                    AddP("[KEY: D]");
                    AddP("[EXPLAIN: Đại từ phản thân 'herself' làm tân ngữ cho động từ help khi chủ ngữ tình nguyện giúp chính bản thân mình.]");
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
                    AddP("With Global Strength Gym's 30-day trial period, you get the opportunity to try out our classes, equipment, and facilities. -------- [131]. It's completely risk-free! To sign up, we require your contact information and payment details, but you will only be charged if you are a member for -------- [132] 30 days. If you decide within this time that you no longer want to be a member of Global Strength, -------- [133] visit our Web site at www.gsgym.com. On the Membership page, elect to -------- [134] your membership and enter the necessary information. It's that easy!");
                    AddP("[PASSAGE_END]");
                    AddP("");
                    AddP("[Q: 131]");
                    AddP("[A] Throughout the trial, you pay nothing and sign no contract.");
                    AddP("[B] Weight-lifting classes are not currently available.");
                    AddP("[C] A cash deposit is required when you sign up for membership.");
                    AddP("[D] All questions should be e-mailed to customerservice@gsgym.com.");
                    AddP("[KEY: A]");
                    AddP("[EXPLAIN: Đoạn sau đề cập 'risk-free' nên câu A phù hợp ngữ cảnh.]");
                    AddP("");
                    AddP("[Q: 132]");
                    AddP("[A] not even");
                    AddP("[B] almost");
                    AddP("[C] over");
                    AddP("[D] less than");
                    AddP("[KEY: C]");
                    AddP("[EXPLAIN: over 30 days = quá thời hạn 30 ngày.]");
                    AddP("");
                    AddP("[Q: 133]");
                    AddP("[A] justly");
                    AddP("[B] regularly");
                    AddP("[C] evenly");
                    AddP("[D] simply");
                    AddP("[KEY: D]");
                    AddP("[EXPLAIN: simply visit = chỉ đơn giản là truy cập website.]");
                    AddP("");
                    AddP("[Q: 134]");
                    AddP("[A] extend");
                    AddP("[B] renew");
                    AddP("[C] cancel");
                    AddP("[D] initiate");
                    AddP("[KEY: C]");
                    AddP("[EXPLAIN: cancel your membership = hủy tư cách thành viên theo ngữ cảnh câu trước.]");
                    AddP("[GROUP_END]");
                    AddP("");
                    AddP("[PART: 7]");
                    AddP("[GROUP_START]");
                    AddP("[SHUFFLE_QUESTIONS: FALSE]");
                    AddP("[SHUFFLE_ANSWERS: TRUE]");
                    AddP("[PASSAGE_START]");
                    AddP("Notice: Sparkle Cleaners will be adjusting its operating hours starting next Monday. Our new schedule will be from 7:00 A.M. to 8:00 P.M., Monday through Saturday. All dry cleaning dropped off before 10:00 A.M. will be ready for pickup by 5:00 P.M. on the same day. Please note that special garment care services may require an additional 24 hours.");
                    AddP("[PASSAGE_END]");
                    AddP("[IMAGE: /uploads/toeic/sample_notice.png]");
                    AddP("");
                    AddP("[Q: 147] What is the purpose of the notice?");
                    AddP("[A] To advertise a discount on dry cleaning");
                    AddP("[B] To announce changes in store hours");
                    AddP("[C] To introduce a new delivery service");
                    AddP("[D] To inform customers about a store relocation");
                    AddP("[KEY: B]");
                    AddP("[EXPLAIN: Thông báo nhằm thông báo thay đổi giờ mở cửa cửa hàng.]");
                    AddP("");
                    AddP("[Q: 148] According to the notice, what can customers expect if they drop off clothes at 9:00 A.M.?");
                    AddP("[A] A lower price");
                    AddP("[B] Same-day pickup by 5:00 P.M.");
                    AddP("[C] Free garment bag");
                    AddP("[D] Express delivery service");
                    AddP("[KEY: B]");
                    AddP("[EXPLAIN: Drop off trước 10:00 A.M. sẽ nhận lại cùng ngày lúc 5:00 P.M.]");
                    AddP("[GROUP_END]");

                    mainPart.Document.Save();
                }

                return File(ms.ToArray(), "application/vnd.openxmlformats-officedocument.wordprocessingml.document", "Mau_De_Thi_TOEIC_Reading_Chuan.docx");
            }
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Upload(IFormFile docxFile)
        {
            if (docxFile == null || docxFile.Length == 0)
            {
                ViewBag.ErrorMessage = "Vui lòng chọn một file Word (.docx) để tải lên.";
                return View();
            }

            var ext = Path.GetExtension(docxFile.FileName).ToLowerInvariant();
            if (ext != ".docx")
            {
                ViewBag.ErrorMessage = "Hệ thống chỉ chấp nhận định dạng file Word (.docx).";
                return View();
            }

            byte[] fileBytes;
            using (var memoryStream = new MemoryStream())
            {
                await docxFile.CopyToAsync(memoryStream);
                fileBytes = memoryStream.ToArray();
            }

            string webRootPath = _env.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
            var result = await _examAppService.ImportExamFromDocx(docxFile.FileName, fileBytes, webRootPath);

            if (!result.IsSuccess)
            {
                ViewBag.Errors = result.Errors;
                ViewBag.ErrorMessage = $"Đã phát hiện {result.Errors.Count} lỗi định dạng trong file. Hệ thống đã huỷ bỏ toàn bộ và không lưu vào CSDL.";
                return View();
            }

            TempData["SuccessMessage"] = $"Import thành công đề thi: '{result.ExamTitle}' với {result.TotalQuestions} câu hỏi!";
            return RedirectToAction(nameof(Preview), new { id = result.ExamId });
        }

        public async Task<IActionResult> Preview(int id)
        {
            var exam = await _examAppService.GetExamForEdit(id);
            return View(exam);
        }

        [HttpGet]
        public async Task<IActionResult> Edit(int id)
        {
            var exam = await _examAppService.GetExamForEdit(id);
            return View(exam);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(ExamDetailDto input)
        {
            if (!ModelState.IsValid)
            {
                return View(input);
            }

            await _examAppService.UpdateExam(input);
            TempData["SuccessMessage"] = "Đã cập nhật nội dung đề thi thành công!";
            return RedirectToAction(nameof(Preview), new { id = input.Id });
        }

        [HttpPost]
        public async Task<IActionResult> Publish(int id, bool isPublished)
        {
            await _examAppService.PublishExam(id, isPublished);
            return Json(new { success = true, isPublished = isPublished });
        }

        [HttpPost]
        public async Task<IActionResult> Delete(int id)
        {
            await _examAppService.DeleteExam(id);
            TempData["SuccessMessage"] = "Đã xoá đề thi thành công.";
            return RedirectToAction(nameof(Index));
        }

        public async Task<IActionResult> Statistics(int id)
        {
            var stats = await _examAppService.GetExamStatistics(id);
            return View(stats);
        }
    }
}
