FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build

RUN dotnet tool install -g Microsoft.Web.LibraryManager.Cli
RUN ln -s ~/.dotnet/tools/libman /usr/local/bin/libman

WORKDIR /src
COPY ["src/backend.Web.Mvc/backend.Web.Mvc.csproj", "src/backend.Web.Mvc/"]
COPY ["src/backend.Web.Core/backend.Web.Core.csproj", "src/backend.Web.Core/"]
COPY ["src/backend.Application/backend.Application.csproj", "src/backend.Application/"]
COPY ["src/backend.Core/backend.Core.csproj", "src/backend.Core/"]
COPY ["src/backend.EntityFrameworkCore/backend.EntityFrameworkCore.csproj", "src/backend.EntityFrameworkCore/"]
WORKDIR "/src/src/backend.Web.Mvc"
RUN dotnet restore 

WORKDIR /src
COPY ["src/backend.Web.Mvc", "src/backend.Web.Mvc"]
COPY ["src/backend.Web.Core", "src/backend.Web.Core"]
COPY ["src/backend.Application", "src/backend.Application"]
COPY ["src/backend.Core", "src/backend.Core"]
COPY ["src/backend.EntityFrameworkCore", "src/backend.EntityFrameworkCore"]
WORKDIR "/src/src/backend.Web.Mvc"
RUN libman restore
RUN dotnet publish -c Release -o /publish --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:8.0
EXPOSE 80
WORKDIR /app
COPY --from=build /publish .
ENTRYPOINT ["dotnet", "backend.Web.Mvc.dll"]
