#!/bin/bash

# Brainsait Healthcare Ecosystem - Quick Start Script
# This script sets up the Brainsait Healthcare Ecosystem

set -e

echo "======================================"
echo "Brainsait Healthcare Ecosystem Setup"
echo "======================================"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    echo "Visit: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    echo "Visit: https://docs.docker.com/compose/install/"
    exit 1
fi

echo "✅ Docker and Docker Compose found"
echo ""

# Check if .env file exists
if [ ! -f .env ]; then
    echo "📝 Creating .env file from template..."
    cp .env.example .env
    echo "⚠️  Please edit .env file with your configuration before continuing"
    echo "   Especially update passwords and API keys!"
    echo ""
    read -p "Press Enter after editing .env file to continue..."
else
    echo "✅ .env file exists"
fi

echo ""
echo "🚀 Starting Brainsait Healthcare Ecosystem..."
echo ""

# Pull Docker images
echo "📦 Pulling Docker images..."
docker-compose pull

echo ""
echo "🏗️  Building and starting services..."
docker-compose up -d

echo ""
echo "⏳ Waiting for services to be ready..."
sleep 10

# Check if services are running
echo ""
echo "🔍 Checking service status..."
docker-compose ps

echo ""
echo "✅ Brainsait Healthcare Ecosystem is starting!"
echo ""
echo "======================================"
echo "Access Points:"
echo "======================================"
echo "N8n Workflow Engine: http://localhost:5678"
echo "PostgreSQL Database: localhost:5432"
echo "Redis Cache:         localhost:6379"
echo "RabbitMQ Management: http://localhost:15672"
echo ""
echo "Default Credentials (⚠️ CHANGE IMMEDIATELY!):"
echo "N8n:      admin / admin123"
echo "RabbitMQ: brainsait / changeme123"
echo ""
echo "======================================"
echo "Next Steps:"
echo "======================================"
echo "1. Access N8n at http://localhost:5678"
echo "2. Import workflows from the workflows/ directory"
echo "3. Configure external integrations (Twilio, SendGrid, etc.)"
echo "4. Review security settings in docs/SECURITY.md"
echo "5. Read the User Guide in docs/USER_GUIDE.md"
echo ""
echo "For deployment guide, see: docs/DEPLOYMENT.md"
echo "For architecture details, see: docs/ARCHITECTURE.md"
echo ""
echo "📚 Documentation: https://github.com/Fadil369/N8n"
echo "📧 Support: support@brainsait.health"
echo ""
echo "To view logs:"
echo "  docker-compose logs -f"
echo ""
echo "To stop services:"
echo "  docker-compose down"
echo ""
echo "✅ Setup complete! Happy automating! 🎉"
