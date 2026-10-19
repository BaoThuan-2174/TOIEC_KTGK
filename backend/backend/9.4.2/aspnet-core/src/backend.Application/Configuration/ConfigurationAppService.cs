using System.Threading.Tasks;
using Abp.Authorization;
using Abp.Runtime.Session;
using backend.Configuration.Dto;

namespace backend.Configuration
{
    [AbpAuthorize]
    public class ConfigurationAppService : backendAppServiceBase, IConfigurationAppService
    {
        public async Task ChangeUiTheme(ChangeUiThemeInput input)
        {
            await SettingManager.ChangeSettingForUserAsync(AbpSession.ToUserIdentifier(), AppSettingNames.UiTheme, input.Theme);
        }
    }
}
