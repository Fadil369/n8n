# Brainsait Healthcare Ecosystem - Deployment Guide

## Overview

This guide provides step-by-step instructions for deploying the Brainsait Healthcare Ecosystem.

## Prerequisites

- Docker and Docker Compose installed
- Minimum 4GB RAM
- PostgreSQL 15+ (if not using Docker)
- Node.js 16+ (if running N8n outside Docker)
- SSL certificates for production deployment

## Quick Start with Docker

### 1. Clone the Repository

```bash
git clone https://github.com/Fadil369/N8n.git
cd N8n
```

### 2. Configure Environment Variables

```bash
cp .env.example .env
```

Edit `.env` file and update the following:
- Database passwords
- N8n credentials
- API keys for external services (Twilio, SendGrid, etc.)

### 3. Start Services

```bash
docker-compose up -d
```

This will start:
- PostgreSQL database
- Redis cache
- N8n workflow engine
- RabbitMQ message queue

### 4. Initialize Database

The database schema will be automatically initialized on first run. To verify:

```bash
docker-compose exec postgres psql -U brainsait -d brainsait_healthcare -c "\dt"
```

### 5. Access N8n

Open your browser and navigate to:
```
http://localhost:5678
```

Login with credentials from your `.env` file (default: admin/admin123)

### 6. Import Workflows

1. Go to N8n UI
2. Click on "Workflows" in the sidebar
3. Click "Import from File"
4. Import workflows from the `workflows/` directory:
   - `patient-intake.json`
   - `appointment-reminder.json`
   - `lab-results-notification.json`

## Production Deployment

### Security Considerations

1. **Change Default Passwords**: Update all default passwords in `.env`

2. **Enable HTTPS**: Configure SSL/TLS certificates
   ```yaml
   # Add to docker-compose.yml
   nginx:
     image: nginx:alpine
     ports:
       - "443:443"
     volumes:
       - ./nginx.conf:/etc/nginx/nginx.conf
       - ./ssl:/etc/nginx/ssl
   ```

3. **Configure Firewall**: Only expose necessary ports
   - 443 (HTTPS)
   - Close 5432, 6379, 5672 to public access

4. **Enable MFA**: Configure multi-factor authentication in N8n

5. **Database Encryption**: Enable encryption at rest
   ```sql
   ALTER DATABASE brainsait_healthcare SET encryption = 'on';
   ```

### HIPAA Compliance Setup

1. **Enable Audit Logging**
   - All database operations are logged in `audit_log` table
   - Configure log retention policy

2. **Data Encryption**
   - Enable PostgreSQL SSL connections
   - Use AES-256 for data at rest
   - Implement field-level encryption for PHI

3. **Access Controls**
   - Implement role-based access control (RBAC)
   - Require MFA for all users
   - Set session timeout to 15 minutes

4. **Regular Backups**
   ```bash
   # Add to crontab
   0 2 * * * docker-compose exec postgres pg_dump -U brainsait brainsait_healthcare > /backups/backup_$(date +\%Y\%m\%d).sql
   ```

### Scaling for Production

#### Horizontal Scaling

1. **Multiple N8n Workers**
   ```yaml
   # docker-compose.yml
   n8n-worker-1:
     image: n8nio/n8n:latest
     environment:
       - EXECUTIONS_MODE=queue
     # ... other config
   
   n8n-worker-2:
     image: n8nio/n8n:latest
     environment:
       - EXECUTIONS_MODE=queue
     # ... other config
   ```

2. **Database Replication**
   - Set up PostgreSQL streaming replication
   - Configure read replicas for reporting queries

3. **Load Balancer**
   ```yaml
   load-balancer:
     image: nginx:alpine
     ports:
       - "80:80"
       - "443:443"
     volumes:
       - ./nginx-lb.conf:/etc/nginx/nginx.conf
   ```

#### Monitoring Setup

1. **Prometheus + Grafana**
   ```yaml
   prometheus:
     image: prom/prometheus:latest
     ports:
       - "9090:9090"
     volumes:
       - ./prometheus.yml:/etc/prometheus/prometheus.yml
   
   grafana:
     image: grafana/grafana:latest
     ports:
       - "3000:3000"
     environment:
       - GF_SECURITY_ADMIN_PASSWORD=admin
   ```

2. **Health Checks**
   - Configure health check endpoints
   - Set up alerting for critical services

## Cloud Deployment Options

### AWS Deployment

1. **Use AWS RDS for PostgreSQL**
2. **Deploy N8n on ECS or EKS**
3. **Use AWS ElastiCache for Redis**
4. **Configure ALB for load balancing**
5. **Use AWS Secrets Manager for credentials**

### Azure Deployment

1. **Use Azure Database for PostgreSQL**
2. **Deploy on Azure Container Instances or AKS**
3. **Use Azure Cache for Redis**
4. **Configure Application Gateway**

### Google Cloud Deployment

1. **Use Cloud SQL for PostgreSQL**
2. **Deploy on GKE**
3. **Use Memorystore for Redis**
4. **Configure Cloud Load Balancer**

## Environment Configuration

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| DB_PASSWORD | Database password | `SecurePass123!` |
| N8N_USER | N8n admin username | `admin` |
| N8N_PASSWORD | N8n admin password | `SecurePass456!` |
| TWILIO_ACCOUNT_SID | Twilio account ID | `AC...` |
| TWILIO_AUTH_TOKEN | Twilio auth token | `...` |
| SENDGRID_API_KEY | SendGrid API key | `SG...` |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| TIMEZONE | System timezone | `America/New_York` |
| LOG_LEVEL | Logging level | `info` |
| N8N_HOST | N8n hostname | `localhost` |

## Backup and Restore

### Database Backup

```bash
# Create backup
docker-compose exec postgres pg_dump -U brainsait brainsait_healthcare > backup.sql

# Restore backup
docker-compose exec -T postgres psql -U brainsait brainsait_healthcare < backup.sql
```

### N8n Configuration Backup

```bash
# Backup workflows and credentials
docker cp brainsait-n8n:/home/node/.n8n ./n8n-backup
```

## Troubleshooting

### Common Issues

1. **N8n Cannot Connect to Database**
   - Check database is running: `docker-compose ps`
   - Verify credentials in `.env`
   - Check network connectivity

2. **Workflows Not Executing**
   - Verify Redis is running
   - Check N8n logs: `docker-compose logs n8n`
   - Ensure EXECUTIONS_MODE is set correctly

3. **Performance Issues**
   - Check resource utilization: `docker stats`
   - Scale up resources if needed
   - Review database query performance

### Logs

```bash
# View all logs
docker-compose logs

# View specific service logs
docker-compose logs n8n
docker-compose logs postgres

# Follow logs in real-time
docker-compose logs -f
```

## Support

For issues and support:
- Email: support@brainsait.health
- Documentation: https://docs.brainsait.health
- GitHub Issues: https://github.com/Fadil369/N8n/issues
