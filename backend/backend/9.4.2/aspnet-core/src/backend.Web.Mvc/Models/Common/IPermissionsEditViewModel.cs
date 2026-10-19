using System.Collections.Generic;
using backend.Roles.Dto;

namespace backend.Web.Models.Common
{
    public interface IPermissionsEditViewModel
    {
        List<FlatPermissionDto> Permissions { get; set; }
    }
}