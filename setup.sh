#!/bin/bash

echo "Setting up Microservices Application..."

# Make sure Docker is running
if ! docker info > /dev/null 2>&1; then
  echo "Docker is not running or not installed. Please start Docker and try again."
  exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
  echo "Docker Compose is not installed. Please install it and try again."
  exit 1
fi

# Bring down any existing containers
echo "Stopping any existing containers..."
docker-compose down

# Build and start services
echo "Building and starting services..."
docker-compose build
docker-compose up -d

echo "Waiting for MySQL to be ready..."
WAIT_TIME=0
MAX_WAIT=120
while ! docker exec mysql mysqladmin ping -h localhost -u root -prootpassword --silent && [ $WAIT_TIME -lt $MAX_WAIT ]; do
  sleep 5
  WAIT_TIME=$((WAIT_TIME + 5))
  echo "Still waiting for MySQL... ($WAIT_TIME seconds)"
done

if [ $WAIT_TIME -ge $MAX_WAIT ]; then
  echo "MySQL didn't start in time. Check logs with 'docker logs mysql'"
else
  echo "MySQL is ready!"
fi

echo "Waiting for backend services to start (this may take some time)..."
sleep 60  # Give more time for services to initialize

echo "Checking service health..."
# Check if Frontend is running
if curl -s http://localhost > /dev/null; then
  echo "✅ Frontend is running"
else
  echo "❌ Frontend is not responding"
  echo "Logs: $(docker logs frontend --tail 10)"
fi

# Check if API Gateway is running
if curl -s http://localhost:8000 > /dev/null; then
  echo "✅ API Gateway is running"
else
  echo "❌ API Gateway is not responding"
  echo "Logs: $(docker logs api-gateway --tail 10)"
fi

# Check if Auth Service is running
if curl -s http://localhost:3001 > /dev/null; then
  echo "✅ Auth Service is running"
else
  echo "❌ Auth Service is not responding"
  echo "Logs: $(docker logs auth-service --tail 10)"
fi

# Check if User Service is running
if curl -s http://localhost:3002 > /dev/null; then
  echo "✅ User Service is running"
else
  echo "❌ User Service is not responding"
  echo "Logs: $(docker logs user-service --tail 10)"
fi

# Check if Analytics Service is running
if curl -s http://localhost:3004 > /dev/null; then
  echo "✅ Analytics Service is running"
else
  echo "❌ Analytics Service is not responding"
  echo "Logs: $(docker logs analytics-service --tail 10)"
fi

echo "Container status:"
docker ps

echo "Setup complete! The application is accessible at http://localhost"
echo ""
echo "You can use the following services:"
echo "- Frontend UI: http://localhost"
echo "- API Gateway: http://localhost:8000"
echo "- Auth Service: http://localhost:3001"
echo "- User Service: http://localhost:3002"
echo "- Analytics Service: http://localhost:3004" 