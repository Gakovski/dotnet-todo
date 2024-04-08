FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build-env
WORKDIR /App

<<<<<<< HEAD
COPY TodoApi.csproj ./
RUN dotnet restore 

COPY . ./
=======
COPY . .

RUN dotnet restore 
>>>>>>> main

RUN dotnet publish -c Release -o out

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /App
COPY --from=build-env /App/out .
ENTRYPOINT ["dotnet", "TodoApi.dll"]