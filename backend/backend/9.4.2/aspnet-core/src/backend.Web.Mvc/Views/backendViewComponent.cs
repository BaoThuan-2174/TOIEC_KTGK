using Abp.AspNetCore.Mvc.ViewComponents;

namespace backend.Web.Views
{
    public abstract class backendViewComponent : AbpViewComponent
    {
        protected backendViewComponent()
        {
            LocalizationSourceName = backendConsts.LocalizationSourceName;
        }
    }
}
