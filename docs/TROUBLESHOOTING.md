# Brainsait Healthcare Ecosystem - Troubleshooting Guide

## Common Issues and Solutions

### Installation & Setup Issues

#### Docker Compose Fails to Start

**Symptoms:**
- Services fail to start
- Error messages about ports already in use
- Database connection errors

**Solutions:**

1. **Check if ports are available:**
   ```bash
   # Check if required ports are free
   lsof -i :5678  # N8n
   lsof -i :5432  # PostgreSQL
   lsof -i :6379  # Redis
   lsof -i :5672  # RabbitMQ
   ```

2. **Stop conflicting services:**
   ```bash
   # Stop existing PostgreSQL
   sudo systemctl stop postgresql
   
   # Or modify docker-compose.yml to use different ports
   ```

3. **Clear Docker volumes and restart:**
   ```bash
   docker-compose down -v
   docker-compose up -d
   ```

#### Database Connection Refused

**Symptoms:**
- N8n cannot connect to PostgreSQL
- Error: "Connection refused" or "ECONNREFUSED"

**Solutions:**

1. **Wait for database to be ready:**
   ```bash
   # Check database status
   docker-compose ps postgres
   
   # View database logs
   docker-compose logs postgres
   ```

2. **Verify database credentials:**
   ```bash
   # Check .env file
   cat .env | grep DB_PASSWORD
   
   # Test connection manually
   docker-compose exec postgres psql -U brainsait -d brainsait_healthcare
   ```

3. **Reset database:**
   ```bash
   docker-compose down
   docker volume rm n8n_postgres_data
   docker-compose up -d
   ```

---

### N8n Workflow Issues

#### Workflows Not Executing

**Symptoms:**
- Workflows show as "active" but don't run
- No execution history
- Scheduled workflows not triggering

**Solutions:**

1. **Check workflow is activated:**
   - Open workflow in N8n UI
   - Ensure toggle is set to "Active"
   - Save workflow

2. **Verify trigger configuration:**
   ```javascript
   // For webhooks
   - Check webhook URL is correct
   - Verify HTTP method (GET/POST)
   
   // For scheduled triggers
   - Verify cron expression
   - Check timezone settings
   ```

3. **Check execution mode:**
   ```bash
   # In .env file
   EXECUTIONS_MODE=queue  # Should be 'queue' for production
   
   # Restart N8n after changes
   docker-compose restart n8n
   ```

4. **Review execution logs:**
   ```bash
   docker-compose logs n8n | grep ERROR
   ```

#### Webhook Not Receiving Requests

**Symptoms:**
- External systems cannot reach webhook
- 404 or timeout errors
- Webhook URL not found

**Solutions:**

1. **Verify webhook path:**
   ```bash
   # Test webhook locally
   curl -X POST http://localhost:5678/webhook/patient-intake \
        -H "Content-Type: application/json" \
        -d '{"test": "data"}'
   ```

2. **Check firewall settings:**
   ```bash
   # Ensure port 5678 is open
   sudo ufw status
   sudo ufw allow 5678
   ```

3. **Configure webhook URL:**
   ```bash
   # In .env file
   WEBHOOK_URL=https://yourdomain.com/
   
   # Restart N8n
   docker-compose restart n8n
   ```

#### Workflow Times Out

**Symptoms:**
- Long-running workflows fail
- Timeout errors in logs

**Solutions:**

1. **Increase timeout settings:**
   ```javascript
   // In workflow settings
   {
     "settings": {
       "executionTimeout": 600  // 10 minutes
     }
   }
   ```

2. **Use async execution:**
   ```bash
   # In .env file
   EXECUTIONS_MODE=queue
   ```

3. **Split into smaller workflows:**
   - Break large workflows into smaller, chained workflows
   - Use webhook triggers between workflows

---

### Database Issues

#### Slow Query Performance

**Symptoms:**
- Workflows taking long to execute
- Database queries timing out
- High CPU usage

**Solutions:**

1. **Check database indexes:**
   ```sql
   -- Connect to database
   docker-compose exec postgres psql -U brainsait -d brainsait_healthcare
   
   -- Check for missing indexes
   SELECT schemaname, tablename, indexname 
   FROM pg_indexes 
   WHERE tablename IN ('patients', 'appointments', 'prescriptions');
   ```

2. **Analyze query performance:**
   ```sql
   -- Enable query logging
   ALTER DATABASE brainsait_healthcare SET log_statement = 'all';
   
   -- View slow queries
   SELECT query, mean_exec_time, calls 
   FROM pg_stat_statements 
   ORDER BY mean_exec_time DESC 
   LIMIT 10;
   ```

3. **Optimize queries:**
   - Add indexes for frequently queried columns
   - Use EXPLAIN ANALYZE for query plans
   - Consider materialized views for reports

#### Database Running Out of Space

**Symptoms:**
- "No space left on device" errors
- Cannot insert new records
- Backup fails

**Solutions:**

1. **Check disk usage:**
   ```bash
   docker-compose exec postgres df -h
   
   # Check database size
   docker-compose exec postgres psql -U brainsait -d brainsait_healthcare \
       -c "SELECT pg_size_pretty(pg_database_size('brainsait_healthcare'));"
   ```

2. **Clean old data:**
   ```sql
   -- Delete old audit logs (keep 1 year)
   DELETE FROM audit_log 
   WHERE timestamp < NOW() - INTERVAL '1 year';
   
   -- Archive old appointments
   DELETE FROM appointments 
   WHERE status = 'completed' 
   AND appointment_date < NOW() - INTERVAL '2 years';
   ```

3. **Vacuum database:**
   ```bash
   docker-compose exec postgres psql -U brainsait -d brainsait_healthcare \
       -c "VACUUM FULL ANALYZE;"
   ```

---

### Integration Issues

#### Twilio SMS Not Sending

**Symptoms:**
- SMS reminders not delivered
- Twilio authentication errors
- Invalid phone number errors

**Solutions:**

1. **Verify Twilio credentials:**
   ```bash
   # Check .env file
   cat .env | grep TWILIO
   
   # Test credentials
   curl -X POST https://api.twilio.com/2010-04-01/Accounts/YOUR_ACCOUNT_SID/Messages.json \
        --data-urlencode "Body=Test message" \
        --data-urlencode "From=+1234567890" \
        --data-urlencode "To=+0987654321" \
        -u YOUR_ACCOUNT_SID:YOUR_AUTH_TOKEN
   ```

2. **Check phone number format:**
   ```javascript
   // Must be E.164 format
   "+1234567890"  // Correct
   "123-456-7890" // Wrong
   "(123) 456-7890" // Wrong
   ```

3. **Verify Twilio phone number:**
   - Ensure sending number is verified in Twilio
   - Check if number supports SMS
   - Verify country code is correct

#### Email Not Sending (SendGrid)

**Symptoms:**
- Welcome emails not received
- SendGrid API errors
- Authentication failures

**Solutions:**

1. **Verify SendGrid API key:**
   ```bash
   # Test SendGrid API
   curl -X POST https://api.sendgrid.com/v3/mail/send \
        -H "Authorization: Bearer YOUR_API_KEY" \
        -H "Content-Type: application/json" \
        -d '{"personalizations":[{"to":[{"email":"test@example.com"}]}],"from":{"email":"noreply@brainsait.health"},"subject":"Test","content":[{"type":"text/plain","value":"Test email"}]}'
   ```

2. **Check sender verification:**
   - Verify sender email in SendGrid dashboard
   - Complete domain authentication
   - Check DNS records

3. **Review email content:**
   - Avoid spam trigger words
   - Include unsubscribe link
   - Use proper HTML formatting

#### EHR Integration Failing

**Symptoms:**
- Cannot connect to FHIR server
- Authentication errors
- Data sync failures

**Solutions:**

1. **Verify FHIR endpoint:**
   ```bash
   # Test FHIR connection
   curl -H "Authorization: Bearer TOKEN" \
        https://fhir.example.com/R4/metadata
   ```

2. **Check OAuth credentials:**
   ```bash
   # Refresh OAuth token
   curl -X POST https://auth.example.com/token \
        -d "grant_type=client_credentials" \
        -d "client_id=YOUR_CLIENT_ID" \
        -d "client_secret=YOUR_CLIENT_SECRET"
   ```

3. **Validate FHIR resources:**
   - Use FHIR validator: https://validator.fhir.org
   - Check resource conformance
   - Verify required fields

---

### Security Issues

#### Cannot Login to N8n

**Symptoms:**
- Incorrect username/password
- Account locked
- Session expired

**Solutions:**

1. **Reset N8n password:**
   ```bash
   # Stop N8n
   docker-compose stop n8n
   
   # Reset credentials in .env
   N8N_BASIC_AUTH_USER=admin
   N8N_BASIC_AUTH_PASSWORD=newpassword123
   
   # Restart N8n
   docker-compose start n8n
   ```

2. **Clear browser cache:**
   - Clear cookies and cache
   - Try incognito/private mode
   - Try different browser

3. **Check account lockout:**
   ```sql
   -- Reset failed login attempts
   UPDATE users 
   SET failed_login_attempts = 0, 
       account_locked = false 
   WHERE username = 'admin';
   ```

#### SSL Certificate Issues

**Symptoms:**
- "Certificate not trusted" warnings
- HTTPS connection fails
- Mixed content errors

**Solutions:**

1. **Verify certificate:**
   ```bash
   # Check certificate expiration
   echo | openssl s_client -connect yourdomain.com:443 2>/dev/null \
        | openssl x509 -noout -dates
   ```

2. **Renew Let's Encrypt certificate:**
   ```bash
   certbot renew
   docker-compose restart nginx
   ```

3. **Update certificate in Nginx:**
   ```nginx
   ssl_certificate /etc/nginx/ssl/fullchain.pem;
   ssl_certificate_key /etc/nginx/ssl/privkey.pem;
   ```

---

### Performance Issues

#### High Memory Usage

**Symptoms:**
- System slowdown
- Out of memory errors
- Container restarts

**Solutions:**

1. **Check memory usage:**
   ```bash
   docker stats
   
   # Check specific container
   docker stats brainsait-n8n
   ```

2. **Increase memory limits:**
   ```yaml
   # In docker-compose.yml
   n8n:
     deploy:
       resources:
         limits:
           memory: 4G
   ```

3. **Optimize workflows:**
   - Process data in batches
   - Use pagination for large datasets
   - Limit concurrent executions

#### High CPU Usage

**Symptoms:**
- Slow response times
- Workflows taking long to execute
- Server overload

**Solutions:**

1. **Identify CPU-intensive workflows:**
   ```bash
   # Check N8n execution logs
   docker-compose logs n8n | grep "Execution time"
   ```

2. **Optimize workflow logic:**
   - Use Set node instead of Function for simple operations
   - Avoid nested loops
   - Cache frequently accessed data

3. **Scale horizontally:**
   ```yaml
   # Add more N8n workers
   n8n-worker-2:
     image: n8nio/n8n:latest
     environment:
       - EXECUTIONS_MODE=queue
   ```

---

### Data Issues

#### Missing Patient Records

**Symptoms:**
- Cannot find patient
- Search returns no results
- Patient ID not found

**Solutions:**

1. **Verify patient ID:**
   ```sql
   SELECT * FROM patients WHERE patient_id = 'PT123456';
   ```

2. **Check data consistency:**
   ```sql
   -- Find orphaned appointments
   SELECT a.* FROM appointments a
   LEFT JOIN patients p ON a.patient_id = p.patient_id
   WHERE p.patient_id IS NULL;
   ```

3. **Restore from backup:**
   ```bash
   # Restore specific table
   docker-compose exec -T postgres psql -U brainsait -d brainsait_healthcare \
       -c "COPY patients FROM STDIN WITH CSV HEADER;" < backup_patients.csv
   ```

#### Duplicate Records

**Symptoms:**
- Multiple patients with same email
- Duplicate appointments
- Data integrity violations

**Solutions:**

1. **Find duplicates:**
   ```sql
   -- Find duplicate patients by email
   SELECT email, COUNT(*) 
   FROM patients 
   GROUP BY email 
   HAVING COUNT(*) > 1;
   ```

2. **Merge duplicates:**
   ```sql
   -- Keep newer record, update references
   UPDATE appointments 
   SET patient_id = 'PT_NEW' 
   WHERE patient_id = 'PT_OLD';
   
   DELETE FROM patients WHERE patient_id = 'PT_OLD';
   ```

3. **Add unique constraints:**
   ```sql
   ALTER TABLE patients 
   ADD CONSTRAINT unique_patient_email UNIQUE (email);
   ```

---

## Getting Help

### Log Collection

Collect logs for support:

```bash
# Save all logs
docker-compose logs > brainsait-logs.txt

# Save specific service
docker-compose logs n8n > n8n-logs.txt

# Include system info
uname -a >> brainsait-logs.txt
docker version >> brainsait-logs.txt
docker-compose version >> brainsait-logs.txt
```

### Support Channels

- **Email**: support@brainsait.health
- **GitHub Issues**: https://github.com/Fadil369/N8n/issues
- **Community Forum**: https://community.brainsait.health
- **Emergency Hotline**: 1-800-BRAINSAIT (24/7)

### Information to Include

When reporting issues, include:
1. Error messages (full text)
2. Steps to reproduce
3. Expected vs actual behavior
4. Environment details (OS, Docker version)
5. Relevant logs
6. Screenshots if applicable

---

**Last Updated**: 2024-11-04  
**Version**: 1.0.0
