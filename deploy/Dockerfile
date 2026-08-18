FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY src/api/GoldDesk.Api.slnx .
COPY src/api/GoldDesk.Api/GoldDesk.Api.csproj GoldDesk.Api/
COPY src/api/GoldDesk.Domain/GoldDesk.Domain.csproj GoldDesk.Domain/
COPY src/api/GoldDesk.Application/GoldDesk.Application.csproj GoldDesk.Application/
COPY src/api/GoldDesk.Infrastructure/GoldDesk.Infrastructure.csproj GoldDesk.Infrastructure/

RUN dotnet restore GoldDesk.Api.slnx

COPY src/api/ .

RUN dotnet publish GoldDesk.Api/GoldDesk.Api.csproj -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app

RUN mkdir -p /app/uploads/order-items /app/uploads/images /app/logs /app/secrets /app/public

COPY --from=build /app/publish .

EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080
ENV Firebase__ServiceAccountPath=/app/secrets/firebase-adminsdk.json

ENTRYPOINT ["dotnet", "GoldDesk.Api.dll"]
