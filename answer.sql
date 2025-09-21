-- clinic_booking_system.sql
-- MySQL schema for a Clinic Booking System
-- Server: MySQL (InnoDB, utf8mb4)
-- Contains CREATE DATABASE, CREATE TABLEs, constraints, and relationships.

DROP DATABASE IF EXISTS clinic_booking;
CREATE DATABASE clinic_booking
  CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;
USE clinic_booking;

-- ---------------------
-- Table: specialties
-- (specialty types for doctors, e.g., "General Practice", "Dentistry")
-- ---------------------
CREATE TABLE specialties (
  specialty_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  description TEXT
) ENGINE=InnoDB;

-- ---------------------
-- Table: doctors
-- ---------------------
CREATE TABLE doctors (
  doctor_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(80) NOT NULL,
  last_name VARCHAR(80) NOT NULL,
  email VARCHAR(150) NOT NULL UNIQUE,
  phone VARCHAR(30) UNIQUE,
  license_number VARCHAR(50) NOT NULL UNIQUE,
  hire_date DATE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ---------------------
-- Table: doctor_specialties (many-to-many doctors <-> specialties)
-- ---------------------
CREATE TABLE doctor_specialties (
  doctor_id INT UNSIGNED NOT NULL,
  specialty_id INT UNSIGNED NOT NULL,
  PRIMARY KEY (doctor_id, specialty_id),
  FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  FOREIGN KEY (specialty_id) REFERENCES specialties(specialty_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ---------------------
-- Table: patients
-- ---------------------
CREATE TABLE patients (
  patient_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(80) NOT NULL,
  last_name VARCHAR(80) NOT NULL,
  date_of_birth DATE,
  gender ENUM('Male','Female','Other') DEFAULT 'Other',
  email VARCHAR(150) UNIQUE,
  phone VARCHAR(30) UNIQUE,
  address VARCHAR(255),
  nhis_number VARCHAR(100) UNIQUE, -- optional national health insurance id
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ---------------------
-- Table: rooms
-- (rooms where appointments happen)
-- ---------------------
CREATE TABLE rooms (
  room_id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(50) NOT NULL UNIQUE,
  location VARCHAR(100),
  capacity SMALLINT UNSIGNED DEFAULT 1,
  is_available BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

-- ---------------------
-- Table: services
-- (treatments or service types offered)
-- ---------------------
CREATE TABLE services (
  service_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(30) NOT NULL UNIQUE,
  name VARCHAR(120) NOT NULL,
  description TEXT,
  duration_minutes SMALLINT UNSIGNED NOT NULL DEFAULT 30,
  price DECIMAL(10,2) NOT NULL DEFAULT 0.00
) ENGINE=InnoDB;

-- ---------------------
-- Table: appointments
-- (core: patient books with doctor at a date/time)
-- Relationships:
--  - Many appointments per patient (one-to-many)
--  - Many appointments per doctor (one-to-many)
--  - Appointment scheduled in a room (optional)
-- ---------------------
CREATE TABLE appointments (
  appointment_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  patient_id INT UNSIGNED NOT NULL,
  doctor_id INT UNSIGNED NOT NULL,
  room_id SMALLINT UNSIGNED NULL,
  scheduled_start DATETIME NOT NULL,
  scheduled_end DATETIME NOT NULL,
  status ENUM('Scheduled','Confirmed','Completed','Cancelled','No-Show') NOT NULL DEFAULT 'Scheduled',
  reason VARCHAR(255),
  created_by_user VARCHAR(100), -- who created booking (staff username)
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT chk_appointment_times CHECK (scheduled_end > scheduled_start),
  FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  FOREIGN KEY (room_id) REFERENCES rooms(room_id)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Indexes for quick lookups
CREATE INDEX idx_appointments_patient ON appointments(patient_id);
CREATE INDEX idx_appointments_doctor ON appointments(doctor_id);
CREATE INDEX idx_appointments_status ON appointments(status);
CREATE INDEX idx_appointments_start ON appointments(scheduled_start);

-- ---------------------
-- Table: appointment_services
-- (many-to-many: an appointment may include multiple services)
-- ---------------------
CREATE TABLE appointment_services (
  appointment_id BIGINT UNSIGNED NOT NULL,
  service_id INT UNSIGNED NOT NULL,
  quantity SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  unit_price DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (appointment_id, service_id),
  FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  FOREIGN KEY (service_id) REFERENCES services(service_id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ---------------------
-- Table: medications
-- ---------------------
CREATE TABLE medications (
  medication_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  brand VARCHAR(150),
  sku VARCHAR(100) UNIQUE,
  dosage_form VARCHAR(80), -- e.g., tablet, syrup
  strength VARCHAR(80),    -- e.g., 500 mg
  instructions TEXT
) ENGINE=InnoDB;

-- ---------------------
-- Table: prescriptions
-- (each prescription is linked to an appointment and patient; one-to-many patient->prescriptions)
-- ---------------------
CREATE TABLE prescriptions (
  prescription_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  appointment_id BIGINT UNSIGNED NULL,
  patient_id INT UNSIGNED NOT NULL,
  prescribed_by INT UNSIGNED NOT NULL, -- doctor_id
  notes TEXT,
  issued_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  FOREIGN KEY (prescribed_by) REFERENCES doctors(doctor_id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ---------------------
-- Table: prescription_medications (many-to-many prescriptions <-> medications)
-- ---------------------
CREATE TABLE prescription_medications (
  prescription_id BIGINT UNSIGNED NOT NULL,
  medication_id INT UNSIGNED NOT NULL,
  dose VARCHAR(100) NOT NULL,
  frequency VARCHAR(100),
  duration_days SMALLINT UNSIGNED,
  notes TEXT,
  PRIMARY KEY (prescription_id, medication_id),
  FOREIGN KEY (prescription_id) REFERENCES prescriptions(prescription_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  FOREIGN KEY (medication_id) REFERENCES medications(medication_id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ---------------------
-- Table: payments
-- (payments for appointments/services)
-- ---------------------
CREATE TABLE payments (
  payment_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  appointment_id BIGINT UNSIGNED NULL,
  patient_id INT UNSIGNED NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  method ENUM('Cash','Card','Mobile Money','Insurance','Other') NOT NULL,
  reference VARCHAR(200),
  paid_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE INDEX idx_payments_patient ON payments(patient_id);
CREATE INDEX idx_payments_appointment ON payments(appointment_id);

-- ---------------------
-- Optional: users (clinic staff) - to record who created/updated records (simple user table)
-- ---------------------
CREATE TABLE users (
  user_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(80) NOT NULL UNIQUE,
  full_name VARCHAR(150),
  email VARCHAR(150) UNIQUE,
  role ENUM('Admin','Receptionist','Nurse','Doctor','Accountant','Other') DEFAULT 'Other',
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ---------------------
-- Example integrity constraints and helpful triggers (optional)
-- Note: Triggers are optional and commented out. Uncomment if you want trigger behavior.
-- ---------------------

-- Example: Ensure appointment times do not overlap for the same doctor (simple check via trigger)
-- WARNING: implementing robust scheduling conflict detection often belongs to application logic.
-- The following trigger provides a basic safeguard (BE SURE to test it in your environment).
/*
DELIMITER //
CREATE TRIGGER trg_appointments_no_overlap
BEFORE INSERT ON appointments
FOR EACH ROW
BEGIN
  IF EXISTS (
    SELECT 1 FROM appointments a
    WHERE a.doctor_id = NEW.doctor_id
      AND a.status <> 'Cancelled'
      AND (
        (NEW.scheduled_start BETWEEN a.scheduled_start AND a.scheduled_end)
        OR (NEW.scheduled_end BETWEEN a.scheduled_start AND a.scheduled_end)
        OR (a.scheduled_start BETWEEN NEW.scheduled_start AND NEW.scheduled_end)
      )
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Doctor has a conflicting appointment in the specified time range.';
  END IF;
END;
//
DELIMITER ;
*/

-- ---------------------
-- Final notes:
-- - All tables use InnoDB for transactional integrity.
-- - Many-to-many relationships represented via junction tables:
--      doctor_specialties, appointment_services, prescription_medications.
-- - Referential actions:
--      CASCADE for dependent data where appropriate,
--      RESTRICT where deletion should be prevented,
--      SET NULL for optional relations (room, appointment link on prescription/payment).
-- - Add application-level checks for advanced rules (appointment overlaps, doctor availability, insurance validation).
-- ---------------------
