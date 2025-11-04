#!/bin/bash

# Brainsait Healthcare Ecosystem - Health Check Script
# This script checks the health of all system components

set -e

echo "======================================"
echo "Brainsait Healthcare System Health Check"
echo "======================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track overall health
ISSUES=0

# Function to check service health
check_service() {
    SERVICE_NAME=$1
    CONTAINER_NAME=$2
    
    echo -n "Checking ${SERVICE_NAME}... "
    
    if docker ps | grep -q "${CONTAINER_NAME}"; then
        HEALTH=$(docker inspect --format='{{.State.Health.Status}}' "${CONTAINER_NAME}" 2>/dev/null || echo "unknown")
        
        if [ "$HEALTH" = "healthy" ] || [ "$HEALTH" = "unknown" ]; then
            echo -e "${GREEN}✓ Running${NC}"
            return 0
        else
            echo -e "${RED}✗ Unhealthy (${HEALTH})${NC}"
            ISSUES=$((ISSUES + 1))
            return 1
        fi
    else
        echo -e "${RED}✗ Not running${NC}"
        ISSUES=$((ISSUES + 1))
        return 1
    fi
}

# Function to check port
check_port() {
    PORT=$1
    SERVICE=$2
    
    echo -n "Checking ${SERVICE} port ${PORT}... "
    
    if nc -z localhost ${PORT} 2>/dev/null; then
        echo -e "${GREEN}✓ Open${NC}"
        return 0
    else
        echo -e "${RED}✗ Closed${NC}"
        ISSUES=$((ISSUES + 1))
        return 1
    fi
}

# Function to check database
check_database() {
    echo -n "Checking PostgreSQL database... "
    
    if docker-compose exec -T postgres psql -U brainsait -d brainsait_healthcare -c "SELECT 1;" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Connected${NC}"
        
        # Check table count
        TABLE_COUNT=$(docker-compose exec -T postgres psql -U brainsait -d brainsait_healthcare -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" | tr -d ' ')
        echo "  Tables: ${TABLE_COUNT}"
        
        # Check patient count
        PATIENT_COUNT=$(docker-compose exec -T postgres psql -U brainsait -d brainsait_healthcare -t -c "SELECT COUNT(*) FROM patients;" 2>/dev/null | tr -d ' ' || echo "0")
        echo "  Patients: ${PATIENT_COUNT}"
        
        return 0
    else
        echo -e "${RED}✗ Cannot connect${NC}"
        ISSUES=$((ISSUES + 1))
        return 1
    fi
}

# Function to check Redis
check_redis() {
    echo -n "Checking Redis cache... "
    
    if docker-compose exec -T redis redis-cli ping >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Responding${NC}"
        return 0
    else
        echo -e "${RED}✗ Not responding${NC}"
        ISSUES=$((ISSUES + 1))
        return 1
    fi
}

# Function to check disk space
check_disk_space() {
    echo -n "Checking disk space... "
    
    USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    if [ "$USAGE" -lt 80 ]; then
        echo -e "${GREEN}✓ ${USAGE}% used${NC}"
        return 0
    elif [ "$USAGE" -lt 90 ]; then
        echo -e "${YELLOW}⚠ ${USAGE}% used (Warning)${NC}"
        ISSUES=$((ISSUES + 1))
        return 1
    else
        echo -e "${RED}✗ ${USAGE}% used (Critical)${NC}"
        ISSUES=$((ISSUES + 1))
        return 1
    fi
}

# Function to check memory
check_memory() {
    echo -n "Checking memory usage... "
    
    MEM_USAGE=$(free | grep Mem | awk '{printf("%.0f", $3/$2 * 100.0)}')
    
    if [ "$MEM_USAGE" -lt 80 ]; then
        echo -e "${GREEN}✓ ${MEM_USAGE}% used${NC}"
        return 0
    elif [ "$MEM_USAGE" -lt 90 ]; then
        echo -e "${YELLOW}⚠ ${MEM_USAGE}% used (Warning)${NC}"
        ISSUES=$((ISSUES + 1))
        return 1
    else
        echo -e "${RED}✗ ${MEM_USAGE}% used (Critical)${NC}"
        ISSUES=$((ISSUES + 1))
        return 1
    fi
}

# Function to check N8n workflows
check_workflows() {
    echo -n "Checking N8n workflows... "
    
    # This is a simplified check - in production you'd use N8n API
    if [ -d "workflows" ] && [ "$(ls -A workflows/*.json 2>/dev/null | wc -l)" -gt 0 ]; then
        WORKFLOW_COUNT=$(ls -1 workflows/*.json 2>/dev/null | wc -l)
        echo -e "${GREEN}✓ ${WORKFLOW_COUNT} workflows found${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ No workflows found${NC}"
        return 0
    fi
}

# Start health checks
echo "System Components:"
echo "===================="
check_service "PostgreSQL" "brainsait-postgres"
check_service "Redis" "brainsait-redis"
check_service "N8n" "brainsait-n8n"
check_service "RabbitMQ" "brainsait-rabbitmq"

echo ""
echo "Port Connectivity:"
echo "===================="
check_port 5678 "N8n"
check_port 5432 "PostgreSQL"
check_port 6379 "Redis"
check_port 15672 "RabbitMQ Management"

echo ""
echo "Data Layer:"
echo "===================="
check_database
check_redis

echo ""
echo "System Resources:"
echo "===================="
check_disk_space
check_memory

echo ""
echo "Application:"
echo "===================="
check_workflows

echo ""
echo "Docker Container Stats:"
echo "===================="
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null || echo "Unable to get stats"

echo ""
echo "======================================"
echo "Health Check Summary"
echo "======================================"

if [ $ISSUES -eq 0 ]; then
    echo -e "${GREEN}✓ All systems operational${NC}"
    echo ""
    echo "System Status: HEALTHY"
    exit 0
elif [ $ISSUES -lt 3 ]; then
    echo -e "${YELLOW}⚠ ${ISSUES} issue(s) detected${NC}"
    echo ""
    echo "System Status: DEGRADED"
    echo "Some non-critical components may need attention"
    exit 1
else
    echo -e "${RED}✗ ${ISSUES} issue(s) detected${NC}"
    echo ""
    echo "System Status: UNHEALTHY"
    echo "Critical components need immediate attention"
    echo ""
    echo "Recommendations:"
    echo "1. Check Docker logs: docker-compose logs"
    echo "2. Review error messages above"
    echo "3. Consult troubleshooting guide: docs/TROUBLESHOOTING.md"
    echo "4. Contact support: support@brainsait.health"
    exit 2
fi
