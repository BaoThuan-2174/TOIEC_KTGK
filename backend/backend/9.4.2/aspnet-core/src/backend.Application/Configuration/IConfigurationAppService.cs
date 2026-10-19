using System.Threading.Tasks;
using backend.Configuration.Dto;

namespace backend.Configuration
{
    public interface IConfigurationAppService
    {
        Task ChangeUiTheme(ChangeUiThemeInput input);
    }
}
