using System.IO;
using Abp.Dependency;

namespace backend.Toeic.WordParser
{
    public interface IToeicWordParserService : ITransientDependency
    {
        WordParseResult ParseDocx(Stream fileStream, string imageOutputFolder = null, string imageWebPathPrefix = null);
        byte[] GenerateSampleDocx();
    }
}

