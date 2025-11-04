-- Brainsait Healthcare Ecosystem Database Schema
-- PostgreSQL Database Schema for Healthcare System

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Patients Table
CREATE TABLE IF NOT EXISTS patients (
    patient_id VARCHAR(50) PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20) NOT NULL,
    address JSONB,
    emergency_contact JSONB,
    insurance_info JSONB,
    status VARCHAR(20) DEFAULT 'active',
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100),
    CONSTRAINT chk_status CHECK (status IN ('active', 'inactive', 'deceased'))
);

-- Healthcare Providers Table
CREATE TABLE IF NOT EXISTS providers (
    provider_id VARCHAR(50) PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20) NOT NULL,
    specialty VARCHAR(100),
    license_number VARCHAR(50) UNIQUE NOT NULL,
    npi_number VARCHAR(20) UNIQUE,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Provider Schedules Table
CREATE TABLE IF NOT EXISTS provider_schedules (
    schedule_id SERIAL PRIMARY KEY,
    provider_id VARCHAR(50) REFERENCES providers(provider_id),
    schedule_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    slot_duration INTEGER DEFAULT 30,
    location VARCHAR(200),
    is_available BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(provider_id, schedule_date)
);

-- Appointments Table
CREATE TABLE IF NOT EXISTS appointments (
    appointment_id VARCHAR(50) PRIMARY KEY,
    patient_id VARCHAR(50) REFERENCES patients(patient_id),
    provider_id VARCHAR(50) REFERENCES providers(provider_id),
    appointment_date DATE NOT NULL,
    appointment_time TIME NOT NULL,
    duration INTEGER DEFAULT 30,
    appointment_type VARCHAR(50),
    reason TEXT,
    status VARCHAR(20) DEFAULT 'scheduled',
    reminder_sent BOOLEAN DEFAULT false,
    cancellation_reason TEXT,
    cancellation_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_apt_status CHECK (status IN ('scheduled', 'confirmed', 'checked_in', 'completed', 'cancelled', 'no_show'))
);

-- Medical History Table
CREATE TABLE IF NOT EXISTS medical_history (
    history_id VARCHAR(50) PRIMARY KEY,
    patient_id VARCHAR(50) REFERENCES patients(patient_id),
    record_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    record_type VARCHAR(50),
    description TEXT,
    provider_id VARCHAR(50) REFERENCES providers(provider_id),
    attachments JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Lab Orders Table
CREATE TABLE IF NOT EXISTS lab_orders (
    order_id VARCHAR(50) PRIMARY KEY,
    patient_id VARCHAR(50) REFERENCES patients(patient_id),
    provider_id VARCHAR(50) REFERENCES providers(provider_id),
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    test_type VARCHAR(100),
    status VARCHAR(20) DEFAULT 'pending',
    results JSONB,
    result_date TIMESTAMP,
    notification_sent BOOLEAN DEFAULT false,
    notification_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_lab_status CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled'))
);

-- Prescriptions Table
CREATE TABLE IF NOT EXISTS prescriptions (
    prescription_id VARCHAR(50) PRIMARY KEY,
    patient_id VARCHAR(50) REFERENCES patients(patient_id),
    provider_id VARCHAR(50) REFERENCES providers(provider_id),
    medication_name VARCHAR(200) NOT NULL,
    dosage VARCHAR(100),
    frequency VARCHAR(100),
    duration VARCHAR(100),
    refills INTEGER DEFAULT 0,
    status VARCHAR(20) DEFAULT 'active',
    prescribed_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expiration_date DATE,
    pharmacy_info JSONB,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_rx_status CHECK (status IN ('active', 'completed', 'cancelled', 'expired'))
);

-- Billing Table
CREATE TABLE IF NOT EXISTS billing (
    billing_id VARCHAR(50) PRIMARY KEY,
    patient_id VARCHAR(50) REFERENCES patients(patient_id),
    appointment_id VARCHAR(50) REFERENCES appointments(appointment_id),
    service_date DATE NOT NULL,
    service_description TEXT,
    amount DECIMAL(10, 2) NOT NULL,
    insurance_claim_id VARCHAR(50),
    insurance_paid DECIMAL(10, 2) DEFAULT 0,
    patient_responsibility DECIMAL(10, 2),
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_billing_status CHECK (status IN ('pending', 'submitted', 'paid', 'denied', 'appealed'))
);

-- Audit Log Table
CREATE TABLE IF NOT EXISTS audit_log (
    log_id SERIAL PRIMARY KEY,
    table_name VARCHAR(50),
    record_id VARCHAR(50),
    action VARCHAR(20),
    user_id VARCHAR(50),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    old_values JSONB,
    new_values JSONB,
    ip_address VARCHAR(45)
);

-- Create Indexes for Performance
CREATE INDEX idx_patients_email ON patients(email);
CREATE INDEX idx_patients_phone ON patients(phone);
CREATE INDEX idx_patients_status ON patients(status);
CREATE INDEX idx_appointments_patient ON appointments(patient_id);
CREATE INDEX idx_appointments_provider ON appointments(provider_id);
CREATE INDEX idx_appointments_date ON appointments(appointment_date);
CREATE INDEX idx_appointments_status ON appointments(status);
CREATE INDEX idx_medical_history_patient ON medical_history(patient_id);
CREATE INDEX idx_lab_orders_patient ON lab_orders(patient_id);
CREATE INDEX idx_prescriptions_patient ON prescriptions(patient_id);
CREATE INDEX idx_billing_patient ON billing(patient_id);
CREATE INDEX idx_audit_log_table_record ON audit_log(table_name, record_id);

-- Create Views for Common Queries
CREATE OR REPLACE VIEW v_upcoming_appointments AS
SELECT 
    a.appointment_id,
    a.appointment_date,
    a.appointment_time,
    a.status,
    p.patient_id,
    p.first_name || ' ' || p.last_name AS patient_name,
    p.phone AS patient_phone,
    p.email AS patient_email,
    pr.provider_id,
    pr.first_name || ' ' || pr.last_name AS provider_name,
    pr.specialty AS provider_specialty
FROM appointments a
JOIN patients p ON a.patient_id = p.patient_id
JOIN providers pr ON a.provider_id = pr.provider_id
WHERE a.appointment_date >= CURRENT_DATE 
  AND a.status NOT IN ('cancelled', 'completed')
ORDER BY a.appointment_date, a.appointment_time;

CREATE OR REPLACE VIEW v_patient_summary AS
SELECT 
    p.patient_id,
    p.first_name,
    p.last_name,
    p.email,
    p.phone,
    p.status,
    COUNT(DISTINCT a.appointment_id) AS total_appointments,
    COUNT(DISTINCT mh.history_id) AS medical_records,
    COUNT(DISTINCT lo.order_id) AS lab_orders,
    COUNT(DISTINCT pr.prescription_id) AS prescriptions
FROM patients p
LEFT JOIN appointments a ON p.patient_id = a.patient_id
LEFT JOIN medical_history mh ON p.patient_id = mh.patient_id
LEFT JOIN lab_orders lo ON p.patient_id = lo.patient_id
LEFT JOIN prescriptions pr ON p.patient_id = pr.patient_id
GROUP BY p.patient_id, p.first_name, p.last_name, p.email, p.phone, p.status;

-- Insert Sample Data for Testing
INSERT INTO providers (provider_id, first_name, last_name, email, phone, specialty, license_number, npi_number)
VALUES 
    ('PROV001', 'Sarah', 'Johnson', 'dr.johnson@brainsait.health', '555-0101', 'General Practice', 'MD12345', '1234567890'),
    ('PROV002', 'Michael', 'Chen', 'dr.chen@brainsait.health', '555-0102', 'Cardiology', 'MD12346', '1234567891'),
    ('PROV003', 'Emily', 'Rodriguez', 'dr.rodriguez@brainsait.health', '555-0103', 'Pediatrics', 'MD12347', '1234567892')
ON CONFLICT (provider_id) DO NOTHING;

-- Grant Permissions (adjust as needed for your deployment)
-- GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO n8n_user;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO n8n_user;
