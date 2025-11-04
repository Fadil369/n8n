/**
 * Brainsait Healthcare Ecosystem
 * Appointment Scheduling Module
 * 
 * Handles appointment booking, rescheduling, cancellation,
 * and availability management.
 */

class AppointmentScheduling {
  constructor(database) {
    this.db = database;
  }

  /**
   * Get available time slots for a provider
   * @param {string} providerId - Healthcare provider ID
   * @param {string} date - Date to check (YYYY-MM-DD)
   * @returns {Promise<Array>} Available time slots
   */
  async getAvailableSlots(providerId, date) {
    // Get provider's schedule
    const scheduleResult = await this.db.query(
      `SELECT * FROM provider_schedules 
       WHERE provider_id = $1 AND schedule_date = $2`,
      [providerId, date]
    );

    if (scheduleResult.rows.length === 0) {
      return [];
    }

    const schedule = scheduleResult.rows[0];
    
    // Get existing appointments
    const appointmentsResult = await this.db.query(
      `SELECT appointment_time, duration FROM appointments 
       WHERE provider_id = $1 AND appointment_date = $2 AND status != 'cancelled'`,
      [providerId, date]
    );

    const bookedSlots = appointmentsResult.rows.map(apt => ({
      start: apt.appointment_time,
      end: this.addMinutes(apt.appointment_time, apt.duration)
    }));

    // Generate available slots
    const slots = [];
    let currentTime = schedule.start_time;
    const slotDuration = schedule.slot_duration || 30; // Default 30 minutes

    while (currentTime < schedule.end_time) {
      const slotEnd = this.addMinutes(currentTime, slotDuration);
      
      // Check if slot is available
      const isBooked = bookedSlots.some(booked => 
        (currentTime >= booked.start && currentTime < booked.end) ||
        (slotEnd > booked.start && slotEnd <= booked.end)
      );

      if (!isBooked) {
        slots.push({
          time: currentTime,
          duration: slotDuration,
          available: true
        });
      }

      currentTime = slotEnd;
    }

    return slots;
  }

  /**
   * Book an appointment
   * @param {Object} appointmentData - Appointment details
   * @returns {Promise<Object>} Created appointment
   */
  async bookAppointment(appointmentData) {
    // Validate required fields
    const required = ['patientId', 'providerId', 'appointmentDate', 'appointmentTime'];
    const missing = required.filter(field => !appointmentData[field]);
    
    if (missing.length > 0) {
      throw new Error(`Missing required fields: ${missing.join(', ')}`);
    }

    // Check if slot is available
    const slots = await this.getAvailableSlots(
      appointmentData.providerId, 
      appointmentData.appointmentDate
    );

    const slotAvailable = slots.some(slot => 
      slot.time === appointmentData.appointmentTime && slot.available
    );

    if (!slotAvailable) {
      throw new Error('Selected time slot is not available');
    }

    // Generate appointment ID
    const appointmentId = `APT${Date.now()}${Math.random().toString(36).substr(2, 9)}`;
    
    // Create appointment
    const appointment = {
      appointmentId,
      patientId: appointmentData.patientId,
      providerId: appointmentData.providerId,
      appointmentDate: appointmentData.appointmentDate,
      appointmentTime: appointmentData.appointmentTime,
      duration: appointmentData.duration || 30,
      appointmentType: appointmentData.appointmentType || 'consultation',
      reason: appointmentData.reason || '',
      status: 'scheduled',
      reminderSent: false,
      createdAt: new Date().toISOString(),
      lastModified: new Date().toISOString()
    };

    await this.db.query(
      `INSERT INTO appointments (appointment_id, patient_id, provider_id, 
       appointment_date, appointment_time, duration, appointment_type, 
       reason, status, reminder_sent, created_at, last_modified) 
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)`,
      [
        appointment.appointmentId, appointment.patientId, appointment.providerId,
        appointment.appointmentDate, appointment.appointmentTime, appointment.duration,
        appointment.appointmentType, appointment.reason, appointment.status,
        appointment.reminderSent, appointment.createdAt, appointment.lastModified
      ]
    );

    return appointment;
  }

  /**
   * Reschedule an appointment
   * @param {string} appointmentId - Appointment ID
   * @param {Object} newSchedule - New date and time
   * @returns {Promise<Object>} Updated appointment
   */
  async rescheduleAppointment(appointmentId, newSchedule) {
    // Get existing appointment
    const result = await this.db.query(
      'SELECT * FROM appointments WHERE appointment_id = $1',
      [appointmentId]
    );

    if (result.rows.length === 0) {
      throw new Error(`Appointment not found: ${appointmentId}`);
    }

    const appointment = result.rows[0];

    // Check new slot availability
    const slots = await this.getAvailableSlots(
      appointment.provider_id,
      newSchedule.appointmentDate
    );

    const slotAvailable = slots.some(slot => 
      slot.time === newSchedule.appointmentTime && slot.available
    );

    if (!slotAvailable) {
      throw new Error('Selected time slot is not available');
    }

    // Update appointment
    await this.db.query(
      `UPDATE appointments 
       SET appointment_date = $1, appointment_time = $2, 
           reminder_sent = false, last_modified = NOW() 
       WHERE appointment_id = $3`,
      [newSchedule.appointmentDate, newSchedule.appointmentTime, appointmentId]
    );

    return this.getAppointment(appointmentId);
  }

  /**
   * Cancel an appointment
   * @param {string} appointmentId - Appointment ID
   * @param {string} reason - Cancellation reason
   * @returns {Promise<Object>} Cancelled appointment
   */
  async cancelAppointment(appointmentId, reason) {
    await this.db.query(
      `UPDATE appointments 
       SET status = 'cancelled', cancellation_reason = $1, 
           cancellation_date = NOW(), last_modified = NOW() 
       WHERE appointment_id = $2`,
      [reason, appointmentId]
    );

    return this.getAppointment(appointmentId);
  }

  /**
   * Get appointment by ID
   * @param {string} appointmentId - Appointment ID
   * @returns {Promise<Object>} Appointment details
   */
  async getAppointment(appointmentId) {
    const result = await this.db.query(
      `SELECT a.*, p.first_name as patient_first_name, 
              p.last_name as patient_last_name, p.phone as patient_phone,
              p.email as patient_email, 
              pr.first_name as provider_first_name, 
              pr.last_name as provider_last_name 
       FROM appointments a 
       JOIN patients p ON a.patient_id = p.patient_id 
       JOIN providers pr ON a.provider_id = pr.provider_id 
       WHERE a.appointment_id = $1`,
      [appointmentId]
    );

    if (result.rows.length === 0) {
      throw new Error(`Appointment not found: ${appointmentId}`);
    }

    return result.rows[0];
  }

  /**
   * Get patient appointments
   * @param {string} patientId - Patient ID
   * @param {Object} options - Query options
   * @returns {Promise<Array>} List of appointments
   */
  async getPatientAppointments(patientId, options = {}) {
    let query = `
      SELECT a.*, pr.first_name as provider_first_name, 
             pr.last_name as provider_last_name 
      FROM appointments a 
      JOIN providers pr ON a.provider_id = pr.provider_id 
      WHERE a.patient_id = $1
    `;
    const params = [patientId];

    if (options.status) {
      params.push(options.status);
      query += ` AND a.status = $${params.length}`;
    }

    if (options.fromDate) {
      params.push(options.fromDate);
      query += ` AND a.appointment_date >= $${params.length}`;
    }

    query += ' ORDER BY a.appointment_date DESC, a.appointment_time DESC';

    const result = await this.db.query(query, params);
    return result.rows;
  }

  /**
   * Utility: Add minutes to time string
   */
  addMinutes(time, minutes) {
    const [hours, mins] = time.split(':').map(Number);
    const totalMinutes = hours * 60 + mins + minutes;
    const newHours = Math.floor(totalMinutes / 60);
    const newMins = totalMinutes % 60;
    return `${String(newHours).padStart(2, '0')}:${String(newMins).padStart(2, '0')}`;
  }
}

module.exports = AppointmentScheduling;
