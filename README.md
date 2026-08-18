# GoldDesk - Digital Partner for Gold Shop

Order tracking and Karigar management SaaS platform for gold/jewellery shops.

## Tech Stack

- **Frontend:** Flutter 3.x (Android, iOS, Web) with BLoC/Cubit
- **Backend:** .NET 10 Web API (Vertical Slice Architecture)
- **Database:** PostgreSQL 16 with Entity Framework Core
- **Auth:** JWT + Refresh Tokens
- **Notifications:** Firebase Cloud Messaging (FCM)
- **Containerization:** Docker + Docker Compose

## Project Structure

```
GoldDesk/
├── src/
│   ├── api/                    # .NET 10 Backend API
│   │   ├── GoldDesk.Api/       # Host, endpoints, middleware
│   │   ├── GoldDesk.Application/ # Features, interfaces, models
│   │   ├── GoldDesk.Domain/    # Entities, enums, value objects
│   │   └── GoldDesk.Infrastructure/ # EF Core, services
│   │
│   └── flutter_app/            # Flutter Mobile + Web App
│       └── lib/
│           ├── core/           # Theme, DI, routing, network
│           └── features/       # Feature modules (auth, orders, etc.)
│
├── docker-compose.yml          # Production compose (clone and run)
├── deploy/                     # Production Dockerfile
├── secrets/                    # Firebase Admin SDK for FCM
├── database/seeds/             # Seed data
├── docker/                     # Local development Docker
└── docs/                       # Documentation
```

## Getting Started

### Prerequisites

- .NET 10 SDK
- Flutter 3.x SDK
- Docker & Docker Compose
- PostgreSQL 16 (or use Docker)

### Run with Docker (server)

From the repo root:

```bash
git clone https://github.com/ArijitManna/golddesk.git
cd golddesk
# Copy Firebase Admin JSON onto the server (required for push notifications):
#   secrets/firebase-adminsdk.json
docker compose up -d --build
```

API: `http://SERVER_IP:8082`  
Health: `GET http://SERVER_IP:8082/api/health`

The compose file mounts `./secrets` into the API container. GitHub blocks committing the Firebase private key, so that JSON must be copied onto the server once.

### Run API Locally

```bash
cd src/api
dotnet restore GoldDesk.Api.slnx
dotnet run --project GoldDesk.Api
```

API runs at `http://localhost:5000`. Health check: `GET /api/health`

### Run Flutter App

```bash
cd src/flutter_app
flutter pub get
flutter run
```

## Environment Variables

Copy `.env.example` to `.env` and configure:
- PostgreSQL credentials
- JWT secret key
- JWT secret key (change `Jwt__Key` in `docker-compose.yml` for production)

## API Health Check

```
GET /api/health
Response: { "status": "Healthy", "service": "GoldDesk API", "version": "1.0.0" }
```
