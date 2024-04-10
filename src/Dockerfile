FROM public.ecr.aws/lambda/dotnet:8.2024.03.28.17 AS base

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build-env
WORKDIR /App

COPY ./TodoApi.csproj ./
RUN dotnet restore 

COPY . ./

RUN dotnet publish -c Release -o out

FROM base as final
WORKDIR /App
COPY --from=build-env /App/out .
ENTRYPOINT ["dotnet", "TodoApi.dll"]