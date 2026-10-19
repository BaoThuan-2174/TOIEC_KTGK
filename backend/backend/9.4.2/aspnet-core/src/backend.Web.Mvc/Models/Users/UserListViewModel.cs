using System.Collections.Generic;
using backend.Roles.Dto;

namespace backend.Web.Models.Users
{
    public class UserListViewModel
    {
        public IReadOnlyList<RoleDto> Roles { get; set; }
    }
}
