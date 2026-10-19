using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Abp.Application.Services.Dto;
using Abp.AspNetCore.Mvc.Authorization;
using backend.Authorization;
using backend.Controllers;
using backend.Users;
using backend.Web.Models.Users;

namespace backend.Web.Controllers
{
    [AbpMvcAuthorize(PermissionNames.Pages_Users)]
    public class UsersController : backendControllerBase
    {
        private readonly IUserAppService _userAppService;

        public UsersController(IUserAppService userAppService)
        {
            _userAppService = userAppService;
        }

        public async Task<ActionResult> Index()
        {
            var roles = (await _userAppService.GetRoles()).Items;
            var model = new UserListViewModel
            {
                Roles = roles
            };
            return View(model);
        }

        public async Task<ActionResult> EditModal(long userId)
        {
            var user = await _userAppService.GetAsync(new EntityDto<long>(userId));
            var roles = (await _userAppService.GetRoles()).Items;
            var model = new EditUserModalViewModel
            {
                User = user,
                Roles = roles
            };
            return PartialView("_EditModal", model);
        }

        public ActionResult ChangePassword()
        {
            return View();
        }
    }
}
