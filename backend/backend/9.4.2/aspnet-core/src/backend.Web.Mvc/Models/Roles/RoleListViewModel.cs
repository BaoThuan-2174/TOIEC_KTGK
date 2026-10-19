using System.Collections.Generic;
using backend.Roles.Dto;

namespace backend.Web.Models.Roles
{
    public class RoleListViewModel
    {
        public IReadOnlyList<PermissionDto> Permissions { get; set; }
    }
}
