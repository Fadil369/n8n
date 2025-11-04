# Brainsait Healthcare Ecosystem - API Documentation

## Overview

The Brainsait Healthcare Ecosystem provides RESTful APIs through N8n webhooks for healthcare automation workflows.

## Base URL

```
Production: https://api.brainsait.health/v1
Development: http://localhost:5678/webhook
```

## Authentication

All API requests require authentication using Bearer tokens:

```bash
curl -H "Authorization: Bearer YOUR_API_TOKEN" \
     https://api.brainsait.health/v1/endpoint
```

## Rate Limiting

- **Limit**: 1000 requests per hour per user
- **Burst**: 100 requests per minute
- **Headers**: 
  - `X-RateLimit-Limit`: Total requests allowed
  - `X-RateLimit-Remaining`: Requests remaining
  - `X-RateLimit-Reset`: Time when limit resets

## Endpoints

### Patient Management

#### Register New Patient

**POST** `/patient-intake`

Register a new patient in the system.

**Request Body:**
```json
{
  "firstName": "John",
  "lastName": "Doe",
  "dateOfBirth": "1980-01-15",
  "email": "john.doe@email.com",
  "phone": "+1234567890",
  "address": {
    "street": "123 Main St",
    "city": "Boston",
    "state": "MA",
    "zipCode": "02101"
  },
  "emergencyContact": {
    "name": "Jane Doe",
    "relationship": "Spouse",
    "phone": "+1234567891"
  },
  "insuranceNumber": "INS123456",
  "insuranceProvider": "Blue Cross"
}
```

**Response:**
```json
{
  "success": true,
  "patientId": "PT1699056789123",
  "status": "pending_verification",
  "message": "Patient registration successful. Welcome email sent."
}
```

**Status Codes:**
- `200`: Success
- `400`: Invalid request data
- `409`: Patient already exists
- `500`: Server error

---

### Appointment Management

#### Schedule Appointment

**POST** `/appointment/schedule`

Schedule a new appointment.

**Request Body:**
```json
{
  "patientId": "PT1699056789123",
  "providerId": "PROV001",
  "appointmentDate": "2024-12-15",
  "appointmentTime": "10:00",
  "appointmentType": "consultation",
  "reason": "Annual checkup",
  "duration": 30
}
```

**Response:**
```json
{
  "success": true,
  "appointmentId": "APT1699056789456",
  "status": "scheduled",
  "confirmationNumber": "CONF-12345",
  "message": "Appointment scheduled successfully"
}
```

#### Get Available Slots

**GET** `/appointment/available-slots?providerId=PROV001&date=2024-12-15`

Get available appointment slots for a provider.

**Response:**
```json
{
  "success": true,
  "date": "2024-12-15",
  "providerId": "PROV001",
  "slots": [
    {
      "time": "09:00",
      "duration": 30,
      "available": true
    },
    {
      "time": "09:30",
      "duration": 30,
      "available": true
    },
    {
      "time": "10:00",
      "duration": 30,
      "available": false
    }
  ]
}
```

---

### Lab Results

#### Submit Lab Results

**POST** `/lab-results`

Submit lab test results for processing.

**Request Body:**
```json
{
  "orderId": "LAB123456",
  "patientId": "PT1699056789123",
  "providerId": "PROV001",
  "testType": "Complete Blood Count",
  "results": {
    "wbc": 7.5,
    "rbc": 4.8,
    "hemoglobin": 14.2,
    "hematocrit": 42.5,
    "platelets": 250
  },
  "resultDate": "2024-11-04T10:30:00Z",
  "labName": "Quest Diagnostics",
  "status": "completed"
}
```

**Response:**
```json
{
  "success": true,
  "orderId": "LAB123456",
  "isCritical": false,
  "notificationSent": true,
  "message": "Lab results processed and patient notified"
}
```

---

### Prescription Management

#### Request Prescription Refill

**POST** `/prescription-refill`

Request a prescription refill.

**Request Body:**
```json
{
  "prescriptionId": "RX123456",
  "patientId": "PT1699056789123",
  "pharmacyId": "PHARM001"
}
```

**Response:**
```json
{
  "success": true,
  "prescriptionId": "RX123456",
  "status": "approved",
  "remainingRefills": 2,
  "readyDate": "2024-11-05",
  "message": "Prescription sent to pharmacy"
}
```

**Possible Statuses:**
- `approved`: Refill approved and sent to pharmacy
- `pending`: Requires provider approval
- `denied`: No refills remaining or expired

---

### Telemedicine

#### Setup Telemedicine Session

**POST** `/telemedicine-setup`

Create a telemedicine session for an appointment.

**Request Body:**
```json
{
  "appointmentId": "APT1699056789456",
  "platform": "zoom",
  "enableRecording": true,
  "enableWaitingRoom": true
}
```

**Response:**
```json
{
  "success": true,
  "appointmentId": "APT1699056789456",
  "meetingId": "123-456-789",
  "patientJoinUrl": "https://zoom.us/j/123456789?pwd=abc123",
  "providerStartUrl": "https://zoom.us/s/123456789?zak=xyz789",
  "meetingPassword": "health123",
  "message": "Telemedicine session created. Invitations sent."
}
```

---

## Webhooks

### Appointment Reminder Webhook

Triggered 24 hours before appointment.

**Payload:**
```json
{
  "event": "appointment.reminder",
  "appointmentId": "APT1699056789456",
  "patientId": "PT1699056789123",
  "appointmentDate": "2024-11-05",
  "appointmentTime": "10:00",
  "providerName": "Dr. Sarah Johnson",
  "location": "Main Clinic"
}
```

### Lab Results Ready Webhook

Triggered when lab results are available.

**Payload:**
```json
{
  "event": "lab.results_ready",
  "orderId": "LAB123456",
  "patientId": "PT1699056789123",
  "isCritical": false,
  "resultDate": "2024-11-04T10:30:00Z"
}
```

---

## Error Responses

All error responses follow this format:

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message",
    "details": "Additional error details"
  }
}
```

### Common Error Codes

| Code | Description |
|------|-------------|
| `INVALID_REQUEST` | Request body validation failed |
| `NOT_FOUND` | Resource not found |
| `UNAUTHORIZED` | Authentication failed |
| `FORBIDDEN` | Insufficient permissions |
| `CONFLICT` | Resource already exists |
| `RATE_LIMIT_EXCEEDED` | Too many requests |
| `SERVER_ERROR` | Internal server error |

---

## FHIR API (Optional)

For EHR integration, the system supports FHIR R4 API:

### Base URL
```
https://fhir.brainsait.health/R4
```

### Supported Resources

- **Patient**: Patient demographics
- **Appointment**: Appointment scheduling
- **Observation**: Lab results and vitals
- **MedicationRequest**: Prescriptions
- **Encounter**: Clinical visits

### Example FHIR Request

**GET Patient:**
```bash
curl -H "Authorization: Bearer TOKEN" \
     -H "Accept: application/fhir+json" \
     https://fhir.brainsait.health/R4/Patient/PT1699056789123
```

**Response:**
```json
{
  "resourceType": "Patient",
  "id": "PT1699056789123",
  "identifier": [
    {
      "system": "https://brainsait.health/patient-id",
      "value": "PT1699056789123"
    }
  ],
  "name": [
    {
      "use": "official",
      "family": "Doe",
      "given": ["John"]
    }
  ],
  "telecom": [
    {
      "system": "phone",
      "value": "+1234567890",
      "use": "mobile"
    },
    {
      "system": "email",
      "value": "john.doe@email.com"
    }
  ],
  "gender": "male",
  "birthDate": "1980-01-15",
  "address": [
    {
      "use": "home",
      "line": ["123 Main St"],
      "city": "Boston",
      "state": "MA",
      "postalCode": "02101"
    }
  ]
}
```

---

## SDKs and Libraries

### JavaScript/Node.js

```javascript
const BrainsaitClient = require('brainsait-health-sdk');

const client = new BrainsaitClient({
  apiKey: 'YOUR_API_KEY',
  environment: 'production'
});

// Register patient
const patient = await client.patients.register({
  firstName: 'John',
  lastName: 'Doe',
  dateOfBirth: '1980-01-15',
  email: 'john.doe@email.com',
  phone: '+1234567890'
});

// Schedule appointment
const appointment = await client.appointments.schedule({
  patientId: patient.id,
  providerId: 'PROV001',
  appointmentDate: '2024-12-15',
  appointmentTime: '10:00'
});
```

### Python

```python
from brainsait_health import BrainsaitClient

client = BrainsaitClient(
    api_key='YOUR_API_KEY',
    environment='production'
)

# Register patient
patient = client.patients.register(
    first_name='John',
    last_name='Doe',
    date_of_birth='1980-01-15',
    email='john.doe@email.com',
    phone='+1234567890'
)

# Schedule appointment
appointment = client.appointments.schedule(
    patient_id=patient.id,
    provider_id='PROV001',
    appointment_date='2024-12-15',
    appointment_time='10:00'
)
```

---

## Testing

### Test Credentials

Use these credentials in the sandbox environment:

```
API Key: test_key_12345
Base URL: https://sandbox.brainsait.health/v1
```

### Test Patient Data

```json
{
  "firstName": "Test",
  "lastName": "Patient",
  "dateOfBirth": "1990-01-01",
  "email": "test.patient@example.com",
  "phone": "+15555555555"
}
```

---

## Support

- **API Status**: https://status.brainsait.health
- **Documentation**: https://docs.brainsait.health
- **Developer Portal**: https://developers.brainsait.health
- **Support Email**: api-support@brainsait.health
- **Community Forum**: https://community.brainsait.health

---

**Version**: 1.0.0  
**Last Updated**: 2024-11-04  
**Changelog**: https://docs.brainsait.health/changelog
