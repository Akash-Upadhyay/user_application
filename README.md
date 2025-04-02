# Microservices Application

This is a simple microservices application with the following components:

## Architecture

| Microservice | Functionality | Database |
|--------------|--------------|----------|
| Auth Service | Handles login & authentication | MySQL (users table) |
| User Service | Stores user profiles | MySQL (users table) |
| Notification Service | Sends email notifications | No DB (just sends emails) |
| API Gateway | Routes requests to appropriate services | No DB |
| Frontend | React-based user interface | No DB |

## Setup

1. Clone this repository
2. Install Docker and Docker Compose
3. Run `docker-compose up -d` to start all services

## Services

- Frontend: http://localhost
- API Gateway: http://localhost:8000
- Auth Service: http://localhost:3001
- User Service: http://localhost:3002
- Notification Service: http://localhost:3003
- MySQL Database: localhost:3306

## API Routes (via Gateway)

- Auth Service: `/auth/*`
- User Service: `/users/*`
- Notification Service: `/notifications/*`

## Tech Stack

- Backend: Python with FastAPI
- Frontend: React with Bootstrap
- Database: MySQL
- ORM: SQLAlchemy
- Container: Docker & Docker Compose

## Features

- User registration and authentication
- User profile management
- Email notifications
- Responsive UI
- Microservices architecture 