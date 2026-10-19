using Microsoft.AspNetCore.Mvc;
using Abp.AspNetCore.Mvc.Authorization;
using backend.Controllers;

namespace backend.Web.Controllers
{
    [AbpMvcAuthorize]
    public class HomeController : backendControllerBase
    {
        public ActionResult Index()
        {
            return View();
        }
    }
}
