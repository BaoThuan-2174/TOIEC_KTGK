using Abp.AspNetCore.Mvc.Views;
using Abp.Runtime.Session;
using Microsoft.AspNetCore.Mvc.Razor.Internal;

namespace backend.Web.Views
{
    public abstract class backendRazorPage<TModel> : AbpRazorPage<TModel>
    {
        [RazorInject]
        public IAbpSession AbpSession { get; set; }

        protected backendRazorPage()
        {
            LocalizationSourceName = backendConsts.LocalizationSourceName;
        }
    }
}
