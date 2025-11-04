/**
 * Brainsait Healthcare Ecosystem
 * Patient Management Module
 * 
 * Handles all patient-related operations including registration,
 * profile management, and medical history tracking.
 */

class PatientManagement {
  constructor(database) {
    this.db = database;
  }

  /**
   * Register a new patient
   * @param {Object} patientData - Patient information
   * @returns {Promise<Object>} Created patient record
   */
  async registerPatient(patientData) {
    // Validate required fields
    const requiredFields = ['firstName', 'lastName', 'dateOfBirth', 'email', 'phone'];
    const missing = requiredFields.filter(field => !patientData[field]);
    
    if (missing.length > 0) {
      throw new Error(`Missing required fields: ${missing.join(', ')}`);
    }

    // Generate unique patient ID
    const patientId = `PT${Date.now()}${Math.random().toString(36).substr(2, 9)}`;
    
    // Prepare patient record
    const patient = {
      patientId,
      firstName: patientData.firstName,
      lastName: patientData.lastName,
      dateOfBirth: patientData.dateOfBirth,
      email: patientData.email,
      phone: patientData.phone,
      address: patientData.address || null,
      emergencyContact: patientData.emergencyContact || null,
      insuranceInfo: patientData.insuranceInfo || null,
      status: 'active',
      registrationDate: new Date().toISOString(),
      lastModified: new Date().toISOString()
    };

    // Store in database
    await this.db.query(
      `INSERT INTO patients (patient_id, first_name, last_name, date_of_birth, 
       email, phone, address, emergency_contact, insurance_info, status, 
       registration_date, last_modified) 
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)`,
      [
        patient.patientId, patient.firstName, patient.lastName, 
        patient.dateOfBirth, patient.email, patient.phone, 
        JSON.stringify(patient.address), JSON.stringify(patient.emergencyContact),
        JSON.stringify(patient.insuranceInfo), patient.status,
        patient.registrationDate, patient.lastModified
      ]
    );

    return patient;
  }

  /**
   * Get patient by ID
   * @param {string} patientId - Patient identifier
   * @returns {Promise<Object>} Patient record
   */
  async getPatient(patientId) {
    const result = await this.db.query(
      'SELECT * FROM patients WHERE patient_id = $1',
      [patientId]
    );

    if (result.rows.length === 0) {
      throw new Error(`Patient not found: ${patientId}`);
    }

    return result.rows[0];
  }

  /**
   * Update patient information
   * @param {string} patientId - Patient identifier
   * @param {Object} updates - Fields to update
   * @returns {Promise<Object>} Updated patient record
   */
  async updatePatient(patientId, updates) {
    const allowedFields = ['firstName', 'lastName', 'email', 'phone', 'address', 
                          'emergencyContact', 'insuranceInfo', 'status'];
    
    const updateFields = Object.keys(updates)
      .filter(key => allowedFields.includes(key))
      .map((key, idx) => `${this.toSnakeCase(key)} = $${idx + 2}`)
      .join(', ');

    if (!updateFields) {
      throw new Error('No valid fields to update');
    }

    const values = Object.keys(updates)
      .filter(key => allowedFields.includes(key))
      .map(key => updates[key]);

    await this.db.query(
      `UPDATE patients SET ${updateFields}, last_modified = NOW() 
       WHERE patient_id = $1`,
      [patientId, ...values]
    );

    return this.getPatient(patientId);
  }

  /**
   * Search patients by criteria
   * @param {Object} criteria - Search parameters
   * @returns {Promise<Array>} List of matching patients
   */
  async searchPatients(criteria) {
    let query = 'SELECT * FROM patients WHERE 1=1';
    const params = [];

    if (criteria.firstName) {
      params.push(`%${criteria.firstName}%`);
      query += ` AND first_name ILIKE $${params.length}`;
    }

    if (criteria.lastName) {
      params.push(`%${criteria.lastName}%`);
      query += ` AND last_name ILIKE $${params.length}`;
    }

    if (criteria.email) {
      params.push(criteria.email);
      query += ` AND email = $${params.length}`;
    }

    if (criteria.phone) {
      params.push(criteria.phone);
      query += ` AND phone = $${params.length}`;
    }

    if (criteria.status) {
      params.push(criteria.status);
      query += ` AND status = $${params.length}`;
    }

    query += ' ORDER BY last_name, first_name LIMIT 100';

    const result = await this.db.query(query, params);
    return result.rows;
  }

  /**
   * Get patient medical history
   * @param {string} patientId - Patient identifier
   * @returns {Promise<Array>} Medical history records
   */
  async getMedicalHistory(patientId) {
    const result = await this.db.query(
      `SELECT * FROM medical_history 
       WHERE patient_id = $1 
       ORDER BY record_date DESC`,
      [patientId]
    );

    return result.rows;
  }

  /**
   * Add medical history entry
   * @param {string} patientId - Patient identifier
   * @param {Object} entry - Medical history entry
   * @returns {Promise<Object>} Created history record
   */
  async addMedicalHistory(patientId, entry) {
    const historyId = `MH${Date.now()}${Math.random().toString(36).substr(2, 9)}`;
    
    await this.db.query(
      `INSERT INTO medical_history (history_id, patient_id, record_date, 
       record_type, description, provider_id, attachments) 
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [
        historyId, patientId, entry.recordDate || new Date().toISOString(),
        entry.recordType, entry.description, entry.providerId,
        JSON.stringify(entry.attachments || [])
      ]
    );

    return { historyId, ...entry };
  }

  /**
   * Utility: Convert camelCase to snake_case
   */
  toSnakeCase(str) {
    return str.replace(/[A-Z]/g, letter => `_${letter.toLowerCase()}`);
  }
}

module.exports = PatientManagement;
