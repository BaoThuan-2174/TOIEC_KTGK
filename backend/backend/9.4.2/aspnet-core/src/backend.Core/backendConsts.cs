using backend.Debugging;

namespace backend
{
    public class backendConsts
    {
        public const string LocalizationSourceName = "backend";

        public const string ConnectionStringName = "Default";

        public const bool MultiTenancyEnabled = true;


        /// <summary>
        /// Default pass phrase for SimpleStringCipher decrypt/encrypt operations
        /// </summary>
        public static readonly string DefaultPassPhrase =
            DebugHelper.IsDebug ? "gsKxGZ012HLL3MI5" : "c3dfa58d076d416c88c45d2b02eec625";
    }
}
