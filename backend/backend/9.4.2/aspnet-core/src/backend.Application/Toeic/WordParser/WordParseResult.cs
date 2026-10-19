using System.Collections.Generic;
using backend.Toeic;

namespace backend.Toeic.WordParser
{
    public class WordParseResult
    {
        public bool IsSuccess { get; set; }
        public List<string> Errors { get; set; } = new List<string>();
        public Exam ParsedExam { get; set; }
    }
}
