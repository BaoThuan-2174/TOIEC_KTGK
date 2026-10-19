using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using DocumentFormat.OpenXml.Packaging;
using DocumentFormat.OpenXml.Wordprocessing;
using backend.Toeic;

namespace backend.Toeic.WordParser
{
    public class ToeicWordParserService : IToeicWordParserService
    {
        public WordParseResult ParseDocx(Stream fileStream, string imageOutputFolder = null, string imageWebPathPrefix = null)
        {
            var result = new WordParseResult();
            var exam = new Exam
            {
                DurationMinutes = 75,
                TotalQuestions = 0,
                IsPublished = false
            };

            var rawLines = new List<string>();

            try
            {
                using (var doc = WordprocessingDocument.Open(fileStream, false))
                {
                    // Extract embedded images if folder provided
                    var imageMap = new Dictionary<string, string>();
                    if (!string.IsNullOrEmpty(imageOutputFolder) && doc.MainDocumentPart != null)
                    {
                        Directory.CreateDirectory(imageOutputFolder);
                        int imgIdx = 1;
                        foreach (var imgPart in doc.MainDocumentPart.ImageParts)
                        {
                            var extension = Path.GetExtension(imgPart.Uri.OriginalString);
                            if (string.IsNullOrEmpty(extension)) extension = ".png";
                            var savedFileName = $"toeic_img_{DateTime.Now.Ticks}_{imgIdx}{extension}";
                            var fullPath = Path.Combine(imageOutputFolder, savedFileName);

                            using (var partStream = imgPart.GetStream())
                            using (var outStream = File.Create(fullPath))
                            {
                                partStream.CopyTo(outStream);
                            }

                            var webPath = (imageWebPathPrefix ?? "/uploads/toeic/").TrimEnd('/') + "/" + savedFileName;
                            var partId = doc.MainDocumentPart.GetIdOfPart(imgPart);
                            imageMap[partId] = webPath;
                            imageMap[Path.GetFileName(imgPart.Uri.OriginalString)] = webPath;
                            imgIdx++;
                        }
                    }

                    // Extract all paragraphs
                    var body = doc.MainDocumentPart?.Document?.Body;
                    if (body == null)
                    {
                        result.IsSuccess = false;
                        result.Errors.Add("File Word rỗng hoặc không đúng định dạng .docx.");
                        return result;
                    }

                    foreach (var para in body.Descendants<Paragraph>())
                    {
                        var text = para.InnerText?.Trim();
                        if (!string.IsNullOrEmpty(text))
                        {
                            rawLines.Add(text);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                result.IsSuccess = false;
                result.Errors.Add($"Lỗi khi mở hoặc đọc file Word .docx: {ex.Message}");
                return result;
            }

            if (rawLines.Count == 0)
            {
                result.IsSuccess = false;
                result.Errors.Add("File Word không có nội dung văn bản.");
                return result;
            }

            // Parser State Machine
            ToeicPartType currentPart = ToeicPartType.Part5;
            QuestionGroup currentGroup = null;
            Question currentQuestion = null;
            bool insidePassage = false;
            var passageBuilder = new StringBuilder();
            var explanationBuilder = new StringBuilder();

            bool allowShuffleQuestionsForPart = false;
            bool allowShuffleAnswersForPart = false;

            for (int lineIndex = 0; lineIndex < rawLines.Count; lineIndex++)
            {
                var line = rawLines[lineIndex].Trim();
                int lineNumber = lineIndex + 1;

                // 1. Exam Title & Duration
                if (line.StartsWith("[EXAM_TITLE:", StringComparison.OrdinalIgnoreCase))
                {
                    exam.Title = ExtractTagValue(line, "[EXAM_TITLE:");
                    continue;
                }
                if (line.StartsWith("[TIEU_DE:", StringComparison.OrdinalIgnoreCase))
                {
                    exam.Title = ExtractTagValue(line, "[TIEU_DE:");
                    continue;
                }
                if (line.StartsWith("[EXAM_TITLE]", StringComparison.OrdinalIgnoreCase))
                {
                    exam.Title = line.Substring("[EXAM_TITLE]".Length).Replace("[/EXAM_TITLE]", "").Trim();
                    continue;
                }
                if (line.StartsWith("[EXAM_DURATION:", StringComparison.OrdinalIgnoreCase))
                {
                    var durStr = ExtractTagValue(line, "[EXAM_DURATION:");
                    if (int.TryParse(durStr, out int dur)) exam.DurationMinutes = dur;
                    continue;
                }
                if (line.StartsWith("[THOI_GIAN:", StringComparison.OrdinalIgnoreCase))
                {
                    var durStr = ExtractTagValue(line, "[THOI_GIAN:");
                    if (int.TryParse(durStr, out int dur)) exam.DurationMinutes = dur;
                    continue;
                }

                // 2. Part headers: [PART: 5], [PART: 6], [PART: 7]
                var partMatch = Regex.Match(line, @"^\[PART\s*:\s*(\d+)\]", RegexOptions.IgnoreCase);
                if (partMatch.Success)
                {
                    int pNum = int.Parse(partMatch.Groups[1].Value);
                    if (pNum == 5) currentPart = ToeicPartType.Part5;
                    else if (pNum == 6) currentPart = ToeicPartType.Part6;
                    else if (pNum == 7) currentPart = ToeicPartType.Part7;
                    else
                    {
                        result.Errors.Add($"Dòng {lineNumber}: Phần thi [PART: {pNum}] không hợp lệ. Chỉ chấp nhận Part 5, 6, hoặc 7.");
                    }

                    // Reset default group for Part 5
                    if (currentPart == ToeicPartType.Part5)
                    {
                        currentGroup = new QuestionGroup
                        {
                            PartType = ToeicPartType.Part5,
                            OrderIndex = exam.QuestionGroups.Count + 1,
                            AllowShuffleQuestions = allowShuffleQuestionsForPart
                        };
                        exam.QuestionGroups.Add(currentGroup);
                    }
                    else
                    {
                        currentGroup = null;
                    }
                    continue;
                }

                // 3. Shuffle tags (Hoán vị câu hỏi & hoán vị câu trả lời)
                if (line.StartsWith("[SHUFFLE_QUESTIONS:", StringComparison.OrdinalIgnoreCase) ||
                    line.StartsWith("[HOAN_VI_CAU_HOI:", StringComparison.OrdinalIgnoreCase))
                {
                    string pfx = line.StartsWith("[SHUFFLE_QUESTIONS:", StringComparison.OrdinalIgnoreCase) 
                        ? "[SHUFFLE_QUESTIONS:" : "[HOAN_VI_CAU_HOI:";
                    var val = ExtractTagValue(line, pfx).ToUpperInvariant();
                    bool sh = val == "TRUE" || val == "1" || val == "YES" || val == "CO";
                    allowShuffleQuestionsForPart = sh;
                    if (currentGroup != null) currentGroup.AllowShuffleQuestions = sh;
                    continue;
                }
                if (line.StartsWith("[SHUFFLE_ANSWERS:", StringComparison.OrdinalIgnoreCase) ||
                    line.StartsWith("[HOAN_VI_DAP_AN:", StringComparison.OrdinalIgnoreCase))
                {
                    string pfx = line.StartsWith("[SHUFFLE_ANSWERS:", StringComparison.OrdinalIgnoreCase) 
                        ? "[SHUFFLE_ANSWERS:" : "[HOAN_VI_DAP_AN:";
                    var val = ExtractTagValue(line, pfx).ToUpperInvariant();
                    bool sh = val == "TRUE" || val == "1" || val == "YES" || val == "CO";
                    allowShuffleAnswersForPart = sh;
                    if (currentQuestion != null) currentQuestion.AllowShuffleAnswers = sh;
                    continue;
                }

                // 4. Group control for Part 6 & 7: [GROUP_START], [GROUP_END]
                if (line.Equals("[GROUP_START]", StringComparison.OrdinalIgnoreCase))
                {
                    currentGroup = new QuestionGroup
                    {
                        PartType = currentPart,
                        OrderIndex = exam.QuestionGroups.Count + 1,
                        AllowShuffleQuestions = allowShuffleQuestionsForPart
                    };
                    exam.QuestionGroups.Add(currentGroup);
                    insidePassage = false;
                    passageBuilder.Clear();
                    continue;
                }
                if (line.Equals("[GROUP_END]", StringComparison.OrdinalIgnoreCase))
                {
                    if (currentGroup != null)
                    {
                        currentGroup.PassageText = passageBuilder.ToString().Trim();
                    }
                    currentGroup = null;
                    insidePassage = false;
                    passageBuilder.Clear();
                    continue;
                }

                // 5. Passage tags: [PASSAGE_START], [PASSAGE_END]
                if (line.Equals("[PASSAGE_START]", StringComparison.OrdinalIgnoreCase))
                {
                    insidePassage = true;
                    passageBuilder.Clear();
                    continue;
                }
                if (line.Equals("[PASSAGE_END]", StringComparison.OrdinalIgnoreCase))
                {
                    insidePassage = false;
                    if (currentGroup != null)
                    {
                        currentGroup.PassageText = passageBuilder.ToString().Trim();
                    }
                    continue;
                }

                if (insidePassage)
                {
                    passageBuilder.AppendLine(line);
                    continue;
                }

                // 6. Image tag: [IMAGE: ...]
                if (line.StartsWith("[IMAGE:", StringComparison.OrdinalIgnoreCase))
                {
                    var imgVal = ExtractTagValue(line, "[IMAGE:");
                    if (currentGroup == null)
                    {
                        result.Errors.Add($"Dòng {lineNumber}: Tag [IMAGE] phải nằm trong nhóm câu hỏi [GROUP_START] của Part 6 hoặc Part 7.");
                    }
                    else
                    {
                        if (string.IsNullOrEmpty(currentGroup.PassageImages))
                            currentGroup.PassageImages = imgVal;
                        else
                            currentGroup.PassageImages += ";" + imgVal;
                    }
                    continue;
                }

                // 7. Question tag: [Q: 101] hoặc [Q: 101] Nội dung câu hỏi
                var qMatch = Regex.Match(line, @"^\[Q\s*:\s*(\d+)\]\s*(.*)$", RegexOptions.IgnoreCase);
                if (qMatch.Success)
                {
                    int qNum = int.Parse(qMatch.Groups[1].Value);
                    string qContent = qMatch.Groups[2].Value.Trim();

                    // If Part 5 and currentGroup is null, create one
                    if (currentGroup == null)
                    {
                        currentGroup = new QuestionGroup
                        {
                            PartType = currentPart,
                            OrderIndex = exam.QuestionGroups.Count + 1,
                            AllowShuffleQuestions = allowShuffleQuestionsForPart
                        };
                        exam.QuestionGroups.Add(currentGroup);
                    }

                    currentQuestion = new Question
                    {
                        QuestionNumber = qNum,
                        Content = qContent,
                        OrderIndex = currentGroup.Questions.Count + 1,
                        AllowShuffleAnswers = allowShuffleAnswersForPart
                    };
                    currentGroup.Questions.Add(currentQuestion);
                    continue;
                }

                // 8. Answer options: [A] ..., [B] ..., [C] ..., [D] ...
                var optMatch = Regex.Match(line, @"^\[([A-D])\]\s*(.+)$", RegexOptions.IgnoreCase);
                if (optMatch.Success)
                {
                    if (currentQuestion == null)
                    {
                        result.Errors.Add($"Dòng {lineNumber}: Đáp án {line} xuất hiện trước khi khai báo câu hỏi [Q: ...].");
                        continue;
                    }

                    string label = optMatch.Groups[1].Value.ToUpperInvariant();
                    string content = optMatch.Groups[2].Value.Trim();

                    if (currentQuestion.AnswerOptions.Any(o => o.Label == label))
                    {
                        result.Errors.Add($"Dòng {lineNumber}: Câu hỏi số {currentQuestion.QuestionNumber} có đáp án [{label}] bị trùng lặp.");
                    }
                    else
                    {
                        currentQuestion.AnswerOptions.Add(new AnswerOption
                        {
                            Label = label,
                            Content = content,
                            IsCorrect = false,
                            OrderIndex = currentQuestion.AnswerOptions.Count + 1
                        });
                    }
                    continue;
                }

                // 9. Correct Key: [KEY: A] hoặc [CORRECT: A] hoặc [ANSWER: A] hoặc [DAP_AN: A]
                var keyMatch = Regex.Match(line, @"^\[(KEY|CORRECT|ANSWER|DAP_AN)\s*:\s*([A-D])\]", RegexOptions.IgnoreCase);
                if (keyMatch.Success)
                {
                    if (currentQuestion == null)
                    {
                        result.Errors.Add($"Dòng {lineNumber}: Tag đáp án đúng {line} xuất hiện không thuộc câu hỏi nào.");
                        continue;
                    }

                    string correctLabel = keyMatch.Groups[2].Value.ToUpperInvariant();
                    var option = currentQuestion.AnswerOptions.FirstOrDefault(o => o.Label == correctLabel);
                    if (option != null)
                    {
                        option.IsCorrect = true;
                    }
                    else
                    {
                        // Will check after options are collected or mark directly
                        currentQuestion.Explanation = (currentQuestion.Explanation ?? "") + $"[KEY_PENDING:{correctLabel}]";
                    }
                    continue;
                }

                // 10. Explanation / Hint tag: [EXPLAIN: ...], [HINT: ...], [EXPLANATION: ...], [GOI_Y: ...], [GIAI_THICH: ...]
                string[] hintPrefixes = new[] { "[EXPLAIN:", "[HINT:", "[EXPLANATION:", "[GOI_Y:", "[GIAI_THICH:" };
                var matchedHintPrefix = hintPrefixes.FirstOrDefault(p => line.StartsWith(p, StringComparison.OrdinalIgnoreCase));
                if (matchedHintPrefix != null)
                {
                    if (currentQuestion == null)
                    {
                        result.Errors.Add($"Dòng {lineNumber}: Tag gợi ý/giải thích {line} xuất hiện không thuộc câu hỏi nào.");
                        continue;
                    }

                    currentQuestion.Explanation = ExtractTagValue(line, matchedHintPrefix);
                    continue;
                }

                // 11. Multi-line question content fallback:
                // If the line is plain text (not starting with [), and we have a current question that hasn't received options yet
                if (!line.StartsWith("[") && currentQuestion != null && currentQuestion.AnswerOptions.Count == 0)
                {
                    if (string.IsNullOrWhiteSpace(currentQuestion.Content))
                    {
                        currentQuestion.Content = line;
                    }
                    else
                    {
                        currentQuestion.Content += " " + line;
                    }
                    continue;
                }
            }

            // Flush last group passage if any
            if (currentGroup != null && passageBuilder.Length > 0 && string.IsNullOrEmpty(currentGroup.PassageText))
            {
                currentGroup.PassageText = passageBuilder.ToString().Trim();
            }

            // Post-parsing strict validation
            ValidateParsedExam(exam, result);

            if (result.Errors.Count == 0)
            {
                result.IsSuccess = true;
                result.ParsedExam = exam;
            }
            else
            {
                result.IsSuccess = false;
            }

            return result;
        }

        private void ValidateParsedExam(Exam exam, WordParseResult result)
        {
            if (string.IsNullOrWhiteSpace(exam.Title))
            {
                result.Errors.Add("Lỗi: Thiếu tên đề thi (vui lòng thêm tag [EXAM_TITLE: Tên đề thi]).");
            }

            var allQuestions = exam.QuestionGroups.SelectMany(g => g.Questions).ToList();
            exam.TotalQuestions = allQuestions.Count;

            if (allQuestions.Count == 0)
            {
                result.Errors.Add("Lỗi: Không tìm thấy bất kỳ câu hỏi nào trong file Word.");
                return;
            }

            // Check question number sequence and duplicates
            var seenNumbers = new HashSet<int>();

            foreach (var g in exam.QuestionGroups)
            {
                int prevInGroup = -1;
                foreach (var q in g.Questions)
                {
                    if (seenNumbers.Contains(q.QuestionNumber))
                    {
                        result.Errors.Add($"Lỗi: Trùng số thứ tự câu hỏi [Q: {q.QuestionNumber}].");
                    }
                    seenNumbers.Add(q.QuestionNumber);

                    if (prevInGroup != -1 && q.QuestionNumber != prevInGroup + 1)
                    {
                        result.Errors.Add($"Lỗi trong nhóm bài đọc (Part {(int)g.PartType}): Số thứ tự câu hỏi không liên tục (Sau câu {prevInGroup} là câu {q.QuestionNumber}).");
                    }
                    prevInGroup = q.QuestionNumber;

                    // Handle pending key if any
                if (!string.IsNullOrEmpty(q.Explanation) && q.Explanation.Contains("[KEY_PENDING:"))
                {
                    var match = Regex.Match(q.Explanation, @"\[KEY_PENDING:([A-D])\]");
                    if (match.Success)
                    {
                        var lbl = match.Groups[1].Value;
                        var opt = q.AnswerOptions.FirstOrDefault(o => o.Label == lbl);
                        if (opt != null) opt.IsCorrect = true;
                        q.Explanation = q.Explanation.Replace(match.Value, "").Trim();
                    }
                }

                // Check answers: Must have exactly 4 answers A, B, C, D
                if (q.AnswerOptions.Count != 4)
                {
                    result.Errors.Add($"Lỗi câu {q.QuestionNumber}: Phải có đủ 4 lựa chọn [A], [B], [C], [D]. Hiện tại có {q.AnswerOptions.Count} lựa chọn.");
                }
                else
                {
                    var labels = q.AnswerOptions.Select(a => a.Label).OrderBy(l => l).ToList();
                    if (labels[0] != "A" || labels[1] != "B" || labels[2] != "C" || labels[3] != "D")
                    {
                        result.Errors.Add($"Lỗi câu {q.QuestionNumber}: Các đáp án phải được đánh nhãn [A], [B], [C], [D].");
                    }
                }

                // Check correct key: Exactly 1 answer must be marked correct
                int correctCount = q.AnswerOptions.Count(a => a.IsCorrect);
                if (correctCount == 0)
                {
                    result.Errors.Add($"Lỗi câu {q.QuestionNumber}: Chưa chỉ định đáp án đúng (thiếu tag [KEY: A/B/C/D]).");
                }
                else if (correctCount > 1)
                {
                    result.Errors.Add($"Lỗi câu {q.QuestionNumber}: Có nhiều hơn 1 đáp án đúng được chọn.");
                }
            }
        }

        // Check groups for Part 6 and Part 7: Must have passage content or images
            foreach (var g in exam.QuestionGroups.Where(x => x.PartType == ToeicPartType.Part6 || x.PartType == ToeicPartType.Part7))
            {
                if (string.IsNullOrWhiteSpace(g.PassageText) && string.IsNullOrWhiteSpace(g.PassageImages))
                {
                    var firstQ = g.Questions.FirstOrDefault()?.QuestionNumber;
                    result.Errors.Add($"Lỗi Part { (int)g.PartType }: Nhóm câu hỏi (bắt đầu từ câu {firstQ}) thiếu nội dung đoạn văn [PASSAGE_START]...[PASSAGE_END] hoặc [IMAGE: ...].");
                }
            }
        }

        private string ExtractTagValue(string line, string tagPrefix)
        {
            var val = line.Substring(tagPrefix.Length).Trim();
            if (val.EndsWith("]"))
            {
                val = val.Substring(0, val.Length - 1).Trim();
            }
            return val;
        }

        public byte[] GenerateSampleDocx()
        {
            using (var ms = new MemoryStream())
            {
                using (var wordDoc = WordprocessingDocument.Create(ms, DocumentFormat.OpenXml.WordprocessingDocumentType.Document, true))
                {
                    var mainPart = wordDoc.AddMainDocumentPart();
                    mainPart.Document = new DocumentFormat.OpenXml.Wordprocessing.Document();
                    var body = mainPart.Document.AppendChild(new Body());

                    void AddP(string text)
                    {
                        var p = body.AppendChild(new Paragraph());
                        var r = p.AppendChild(new Run());
                        r.AppendChild(new Text(text));
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
                    AddP("[HINT: Đại từ phản thân 'herself' làm tân ngữ cho động từ help khi chủ ngữ tình nguyện giúp chính bản thân mình.]");
                    AddP("");
                    AddP("[Q: 102] Lasner Electronics' online service station allows customers to -------- their order status.");
                    AddP("[A] track");
                    AddP("[B] form");
                    AddP("[C] save");
                    AddP("[D] enter");
                    AddP("[KEY: A]");
                    AddP("[HINT: Cụm từ cố định 'track one's order status' nghĩa là theo dõi trạng thái đơn hàng.]");
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
                    AddP("[HINT: Đoạn sau đề cập 'risk-free' (hoàn toàn không rủi ro) nên phương án A 'không phải trả phí và không hợp đồng' là logic nhất.]");
                    AddP("");
                    AddP("[Q: 132]");
                    AddP("[A] not even");
                    AddP("[B] almost");
                    AddP("[C] over");
                    AddP("[D] less than");
                    AddP("[KEY: C]");
                    AddP("[HINT: 'over 30 days' nghĩa là vượt quá thời hạn 30 ngày dùng thử.]");
                    AddP("");
                    AddP("[Q: 133]");
                    AddP("[A] justly");
                    AddP("[B] regularly");
                    AddP("[C] evenly");
                    AddP("[D] simply");
                    AddP("[KEY: D]");
                    AddP("[HINT: 'simply visit' mang nghĩa 'chỉ đơn giản là truy cập' vào website.]");
                    AddP("");
                    AddP("[Q: 134]");
                    AddP("[A] extend");
                    AddP("[B] renew");
                    AddP("[C] cancel");
                    AddP("[D] initiate");
                    AddP("[KEY: C]");
                    AddP("[HINT: Ngữ cảnh 'không muốn làm hội viên nữa' nên chọn 'cancel' để hủy tư cách thành viên.]");
                    AddP("[GROUP_END]");
                    AddP("");
                    AddP("[PART: 7]");
                    AddP("[GROUP_START]");
                    AddP("[SHUFFLE_QUESTIONS: FALSE]");
                    AddP("[SHUFFLE_ANSWERS: TRUE]");
                    AddP("[PASSAGE_START]");
                    AddP("Notice: Sparkle Cleaners will be adjusting its operating hours starting next Monday. Our new schedule will be from 7:00 A.M. to 8:00 P.M., Monday through Saturday. All dry cleaning dropped off before 10:00 A.M. will be ready for pickup by 5:00 P.M. on the same day. Please note that special garment care services may require an additional 24 hours.");
                    AddP("[PASSAGE_END]");
                    AddP("");
                    AddP("[Q: 147] What is the purpose of the notice?");
                    AddP("[A] To advertise a discount on dry cleaning");
                    AddP("[B] To announce changes in store hours");
                    AddP("[C] To introduce a new delivery service");
                    AddP("[D] To inform customers about a store relocation");
                    AddP("[KEY: B]");
                    AddP("[HINT: 'adjusting its operating hours' = thông báo thay đổi thời gian mở cửa.]");
                    AddP("");
                    AddP("[Q: 148] According to the notice, what can customers expect if they drop off clothes at 9:00 A.M.?");
                    AddP("[A] A lower price");
                    AddP("[B] Same-day pickup by 5:00 P.M.");
                    AddP("[C] Free garment bag");
                    AddP("[D] Express delivery service");
                    AddP("[KEY: B]");
                    AddP("[HINT: Gửi đồ giặt trước 10:00 A.M. (9:00 A.M. thoả mãn) sẽ sẵn sàng nhận lại lúc 5:00 P.M. trong ngày.]");
                    AddP("[GROUP_END]");

                    mainPart.Document.Save();
                }

                return ms.ToArray();
            }
        }
    }
}

