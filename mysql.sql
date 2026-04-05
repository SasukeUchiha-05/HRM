-- =============================================================
-- FACE RECOGNITION ATTENDANCE & HRM SYSTEM
-- MySQL Schema — Full DDL
-- Generated: April 2026
-- =============================================================

SET FOREIGN_KEY_CHECKS = 0;
SET sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- =============================================================
-- 1. DEPARTMENTS
-- (defined before employees because employees FK → departments)
-- =============================================================
CREATE TABLE departments (
    id                  CHAR(36)        NOT NULL DEFAULT (UUID()),
    name                VARCHAR(100)    NOT NULL,
    description         TEXT,
    head_employee_id    CHAR(36)        NULL,          -- FK added after employees table
    status              ENUM('active','inactive') NOT NULL DEFAULT 'active',
    created_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_departments       PRIMARY KEY (id),
    CONSTRAINT uq_departments_name  UNIQUE (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =============================================================
-- 2. DESIGNATIONS
-- =============================================================
CREATE TABLE designations (
    id              CHAR(36)        NOT NULL DEFAULT (UUID()),
    title           VARCHAR(100)    NOT NULL,
    department_id   CHAR(36)        NOT NULL,
    level           TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '1=entry, higher=senior',
    status          ENUM('active','inactive') NOT NULL DEFAULT 'active',
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_designations          PRIMARY KEY (id),
    CONSTRAINT uq_designations_title    UNIQUE (title, department_id),
    CONSTRAINT fk_designations_dept     FOREIGN KEY (department_id)
        REFERENCES departments(id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =============================================================
-- 3. EMPLOYEES
-- =============================================================
CREATE TABLE employees (
    id                  CHAR(36)        NOT NULL DEFAULT (UUID()),
    employee_code       VARCHAR(20)     NOT NULL,
    first_name          VARCHAR(60)     NOT NULL,
    last_name           VARCHAR(60)     NOT NULL,
    date_of_birth       DATE            NOT NULL,
    gender              ENUM('male','female','other') NOT NULL,
    aadhaar_number      CHAR(12)        NOT NULL,
    pan_number          VARCHAR(10)     NOT NULL,
    department_id       CHAR(36)        NOT NULL,
    designation_id      CHAR(36)        NOT NULL,
    manager_id          CHAR(36)        NULL COMMENT 'Self-ref: direct reporting manager',
    date_of_joining     DATE            NOT NULL,
    date_of_leaving     DATE            NULL,
    status              ENUM('active','on_leave','terminated') NOT NULL DEFAULT 'active',
    bank_account_no     VARCHAR(30)     NULL,
    ifsc_code           VARCHAR(11)     NULL,
    bank_name           VARCHAR(100)    NULL,
    profile_photo_url   VARCHAR(500)    NULL,
    created_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_employees             PRIMARY KEY (id),
    CONSTRAINT uq_employees_code        UNIQUE (employee_code),
    CONSTRAINT uq_employees_aadhaar     UNIQUE (aadhaar_number),
    CONSTRAINT uq_employees_pan         UNIQUE (pan_number),
    CONSTRAINT fk_employees_dept        FOREIGN KEY (department_id)
        REFERENCES departments(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_employees_desig       FOREIGN KEY (designation_id)
        REFERENCES designations(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_employees_manager     FOREIGN KEY (manager_id)
        REFERENCES employees(id) ON DELETE SET NULL ON UPDATE CASCADE,
    INDEX idx_employees_dept            (department_id),
    INDEX idx_employees_desig           (designation_id),
    INDEX idx_employees_status          (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Now that employees exists, wire departments.head_employee_id
ALTER TABLE departments
    ADD CONSTRAINT fk_departments_head
        FOREIGN KEY (head_employee_id)
        REFERENCES employees(id) ON DELETE SET NULL ON UPDATE CASCADE;


-- =============================================================
-- 4. USERS  (auth layer, 1-to-1 with employees)
-- =============================================================
CREATE TABLE users (
    id              CHAR(36)        NOT NULL DEFAULT (UUID()),
    email           VARCHAR(180)    NOT NULL,
    phone           VARCHAR(15)     NULL,
    password_hash   VARCHAR(255)    NOT NULL,
    role            ENUM('admin','hr','manager','employee') NOT NULL DEFAULT 'employee',
    status          ENUM('active','inactive','terminated') NOT NULL DEFAULT 'active',
    employee_id     CHAR(36)        NULL,
    last_login_at   DATETIME        NULL,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_users             PRIMARY KEY (id),
    CONSTRAINT uq_users_email       UNIQUE (email),
    CONSTRAINT uq_users_phone       UNIQUE (phone),
    CONSTRAINT uq_users_employee    UNIQUE (employee_id),
    CONSTRAINT fk_users_employee    FOREIGN KEY (employee_id)
        REFERENCES employees(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =============================================================
-- 5. FACE ENCODINGS
-- =============================================================
CREATE TABLE face_encodings (
    id                  CHAR(36)        NOT NULL DEFAULT (UUID()),
    employee_id         CHAR(36)        NOT NULL,
    encoding_data       MEDIUMBLOB      NOT NULL COMMENT 'Binary face vector',
    capture_angle       ENUM('frontal','left','right') NOT NULL,
    confidence_score    DECIMAL(5,4)    NOT NULL DEFAULT 0.0000
        COMMENT '0.0000–1.0000',
    status              ENUM('active','revoked') NOT NULL DEFAULT 'active',
    registered_at       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_face_encodings        PRIMARY KEY (id),
    CONSTRAINT uq_face_enc_angle        UNIQUE (employee_id, capture_angle, status),
    CONSTRAINT fk_face_enc_employee     FOREIGN KEY (employee_id)
        REFERENCES employees(id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_face_enc_status           (employee_id, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =============================================================
-- 6. GEOFENCES
-- =============================================================
CREATE TABLE geofences (
    id              CHAR(36)        NOT NULL DEFAULT (UUID()),
    name            VARCHAR(100)    NOT NULL,
    latitude        DECIMAL(10,7)   NOT NULL,
    longitude       DECIMAL(10,7)   NOT NULL,
    radius_meters   SMALLINT UNSIGNED NOT NULL DEFAULT 200,
    department_id   CHAR(36)        NULL COMMENT 'NULL = applies to all departments',
    status          ENUM('active','inactive') NOT NULL DEFAULT 'active',
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_geofences         PRIMARY KEY (id),
    CONSTRAINT fk_geofences_dept    FOREIGN KEY (department_id)
        REFERENCES departments(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =============================================================
-- 7. GEOFENCE ASSIGNMENTS  (employee-level overrides)
-- =============================================================
CREATE TABLE geofence_assignments (
    id              CHAR(36)    NOT NULL DEFAULT (UUID()),
    geofence_id     CHAR(36)    NOT NULL,
    employee_id     CHAR(36)    NOT NULL,
    effective_from  DATE        NOT NULL,
    effective_to    DATE        NULL,
    CONSTRAINT pk_geofence_asgn         PRIMARY KEY (id),
    CONSTRAINT fk_geofence_asgn_geo     FOREIGN KEY (geofence_id)
        REFERENCES geofences(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_geofence_asgn_emp     FOREIGN KEY (employee_id)
        REFERENCES employees(id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_geofence_asgn_emp         (employee_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =============================================================
-- 8. SHIFTS
-- =============================================================
CREATE TABLE shifts (
    id                  CHAR(36)        NOT NULL DEFAULT (UUID()),
    name                VARCHAR(80)     NOT NULL,
    start_time          TIME            NOT NULL,
    end_time            TIME            NOT NULL,
    grace_period_min    TINYINT UNSIGNED NOT NULL DEFAULT 15,
    max_overtime_min    SMALLINT UNSIGNED NOT NULL DEFAULT 120,
    shift_type          ENUM('fixed','flexible','rotational') NOT NULL DEFAULT 'fixed',
    status              ENUM('active','inactive') NOT NULL DEFAULT 'active',
    created_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_shifts    PRIMARY KEY (id),
    CONSTRAINT uq_shifts_name UNIQUE (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =============================================================
-- 9. WEEK OFFS
-- =============================================================
CREATE TABLE week_offs (
    id              CHAR(36)    NOT NULL DEFAULT (UUID()),
    shift_id        CHAR(36)    NOT NULL,
    day_of_week     ENUM('mon','tue','wed','thu','fri','sat','sun') NOT NULL,
    CONSTRAINT pk_week_offs         PRIMARY KEY (id),
    CONSTRAINT uq_week_off_day      UNIQUE (shift_id, day_of_week),
    CONSTRAINT fk_week_off_shift    FOREIGN KEY (shift_id)
        REFERENCES shifts(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =============================================================
-- 10. SHIFT ASSIGNMENTS
-- =============================================================
CREATE TABLE shift_assignments (
    id              CHAR(36)    NOT NULL DEFAULT (UUID()),
    employee_id     CHAR(36)    NOT NULL,
    shift_id        CHAR(36)    NOT NULL,
    effective_from  DATE        NOT NULL,
    effective_to    DATE        NULL,
    assigned_by     CHAR(36)    NOT NULL COMMENT 'FK → users.id',
    created_at      DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_shift_asgn        PRIMARY KEY (id),
    CONSTRAINT fk_shift_asgn_emp    FOREIGN KEY (employee_id)
        REFERENCES employees(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_shift_asgn_shift  FOREIGN KEY (shift_id)
        REFERENCES shifts(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_shift_asgn_user   FOREIGN KEY (assigned_by)
        REFERENCES users(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_shift_asgn_emp        (employee_id, effective_from)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =============================================================
-- 11. ATTENDANCE
-- =============================================================
CREATE TABLE attendance (
    id                  CHAR(36)        NOT NULL DEFAULT (UUID()),
    employee_id         CHAR(36)        NOT NULL,
    attendance_date     DATE            NOT NULL,
    punch_in_time       TIME            NULL,
    punch_out_time      TIME            NULL,
    punch_in_lat        DECIMAL(10,7)   NULL,
    punch_in_lng        DECIMAL(10,7)   NULL,
    punch_out_lat       DECIMAL(10,7)   NULL,
    punch_out_lng       DECIMAL(10,7)   NULL,
    total_minutes       SMALLINT UNSIGNED NULL COMMENT 'Computed on punch-out',
    overtime_minutes    SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    status              ENUM('present','absent','half_day','week_off','holiday','on_leave')
                            NOT NULL DEFAULT 'absent',
    entry_mode          ENUM('face','manual','kiosk') NOT NULL DEFAULT 'face',
    approved_by         CHAR(36)        NULL COMMENT 'FK → users.id, for manual entries',
    remarks             VARCHAR(255)    NULL,
    created_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_attendance            PRIMARY KEY (id),
    CONSTRAINT uq_attendance_emp_date   UNIQUE (employee_id, attendance_date),
    CONSTRAINT fk_attendance_emp        FOREIGN KEY (employee_id)
        REFERENCES employees(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_attendance_approver   FOREIGN KEY (approved_by)
        REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
    INDEX idx_attendance_date           (attendance_date),
    INDEX idx_attendance_status         (employee_id, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =============================================================
-- 12. ATTENDANCE ADJUSTMENTS
-- =============================================================
CREATE TABLE attendance_adjustments (
    id                  CHAR(36)    NOT NULL DEFAULT (UUID()),
    attendance_id       CHAR(36)    NOT NULL,
    requested_by        CHAR(36)    NOT NULL COMMENT 'FK → users.id',
    approved_by         CHAR(36)    NULL     COMMENT 'FK → users.id',
    reason              TEXT        NOT NULL,
    old_punch_in        TIME        NULL,
    new_punch_in        TIME        NULL,
    old_punch_out       TIME        NULL,
    new_punch_out       TIME        NULL,
    status              ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending',
    requested_at        DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resolved_at         DATETIME    NULL,
    CONSTRAINT pk_att_adj           PRIMARY KEY (id),
    CONSTRAINT fk_att_adj_att       FOREIGN KEY (attendance_id)
        REFERENCES attendance(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_att_adj_req       FOREIGN KEY (requested_by)
        REFERENCES users(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_att_adj_appr      FOREIGN KEY (approved_by)
        REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =============================================================
-- 13. LEAVE TYPES
-- =============================================================
CREATE TABLE leave_types (
    id                          CHAR(36)        NOT NULL DEFAULT (UUID()),
    name                        VARCHAR(80)     NOT NULL,
    code                        VARCHAR(10)     NOT NULL,
    paid_status                 ENUM('paid','unpaid') NOT NULL DEFAULT 'paid',
    default_days_per_year       TINYINT UNSIGNED NOT NULL DEFAULT 0,
    carry_forward               TINYINT(1)      NOT NULL DEFAULT 0,
    max_carry_forward_days      TINYINT UNSIGNED NOT NULL DEFAULT 0,
    requires_approval           TINYINT(1)      NOT NULL DEFAULT 1,
    status                      ENUM('active','inactive') NOT NULL DEFAULT 'active',
    created_at                  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_leave_types       PRIMARY KEY (id),
    CONSTRAINT uq_leave_types_code  UNIQUE (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =============================================================
-- 14. LEAVE BALANCES
-- =============================================================
CREATE TABLE leave_balances (
    id              CHAR(36)        NOT NULL DEFAULT (UUID()),
    employee_id     CHAR(36)        NOT NULL,
    leave_type_id   CHAR(36)        NOT NULL,
    year            YEAR            NOT NULL,
    total_days      TINYINT UNSIGNED NOT NULL DEFAULT 0,
    used_days       TINYINT UNSIGNED NOT NULL DEFAULT 0,
    pending_days    TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Awaiting approval',
    remaining_days  TINYINT UNSIGNED NOT NULL DEFAULT 0
        COMMENT 'Computed: total - used - pending',
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_leave_bal             PRIMARY KEY (id),
    CONSTRAINT uq_leave_bal_emp_year    UNIQUE (employee_id, leave_type_id, year),
    CONSTRAINT fk_leave_bal_emp         FOREIGN KEY (employee_id)
        REFERENCES employees(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_leave_bal_type        FOREIGN KEY (leave_type_id)
        REFERENCES leave_types(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_leave_bal_year            (year)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =============================================================
-- 15. LEAVE REQUESTS
-- =============================================================
CREATE TABLE leave_requests (
    id                  CHAR(36)        NOT NULL DEFAULT (UUID()),
    employee_id         CHAR(36)        NOT NULL,
    leave_type_id       CHAR(36)        NOT NULL,
    start_date          DATE            NOT NULL,
    end_date            DATE            NOT NULL,
    total_days          TINYINT UNSIGNED NOT NULL,
    reason              TEXT            NOT NULL,
    status              ENUM('pending','approved','rejected','cancelled')
                            NOT NULL DEFAULT 'pending',
    approved_by         CHAR(36)        NULL COMMENT 'FK → users.id',
    rejection_reason    VARCHAR(255)    NULL,
    applied_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resolved_at         DATETIME        NULL,
    CONSTRAINT pk_leave_req         PRIMARY KEY (id),
    CONSTRAINT chk_leave_dates      CHECK (end_date >= start_date),
    CONSTRAINT fk_leave_req_emp     FOREIGN KEY (employee_id)
        REFERENCES employees(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_leave_req_type    FOREIGN KEY (leave_type_id)
        REFERENCES leave_types(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_leave_req_appr    FOREIGN KEY (approved_by)
        REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
    INDEX idx_leave_req_status      (employee_id, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =============================================================
-- 16. HOLIDAYS
-- =============================================================
CREATE TABLE holidays (
    id              CHAR(36)        NOT NULL DEFAULT (UUID()),
    name            VARCHAR(100)    NOT NULL,
    holiday_date    DATE            NOT NULL,
    holiday_type    ENUM('national','company','restricted') NOT NULL DEFAULT 'company',
    is_paid         TINYINT(1)      NOT NULL DEFAULT 1,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_holidays          PRIMARY KEY (id),
    CONSTRAINT uq_holidays_date     UNIQUE (holiday_date, holiday_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =============================================================
-- 17. HOLIDAY ASSIGNMENTS  (per-department applicability)
-- =============================================================
CREATE TABLE holiday_assignments (
    id              CHAR(36)    NOT NULL DEFAULT (UUID()),
    holiday_id      CHAR(36)    NOT NULL,
    department_id   CHAR(36)    NOT NULL,
    CONSTRAINT pk_holiday_asgn          PRIMARY KEY (id),
    CONSTRAINT uq_holiday_dept          UNIQUE (holiday_id, department_id),
    CONSTRAINT fk_holiday_asgn_hol      FOREIGN KEY (holiday_id)
        REFERENCES holidays(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_holiday_asgn_dept     FOREIGN KEY (department_id)
        REFERENCES departments(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =============================================================
-- 18. SALARY STRUCTURES  (designation-level templates)
-- =============================================================
CREATE TABLE salary_structures (
    id                  CHAR(36)        NOT NULL DEFAULT (UUID()),
    designation_id      CHAR(36)        NOT NULL,
    name                VARCHAR(100)    NOT NULL,
    basic_salary        DECIMAL(12,2)   NOT NULL,
    hra_percent         DECIMAL(5,2)    NOT NULL DEFAULT 40.00
        COMMENT 'HRA as % of basic',
    special_allowance   DECIMAL(12,2)   NOT NULL DEFAULT 0.00,
    effective_from      DATE            NOT NULL,
    status              ENUM('active','inactive') NOT NULL DEFAULT 'active',
    created_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_sal_struct        PRIMARY KEY (id),
    CONSTRAINT fk_sal_struct_desig  FOREIGN KEY (designation_id)
        REFERENCES designations(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_sal_struct_eff        (designation_id, effective_from)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =============================================================
-- 19. EMPLOYEE SALARY  (individual overrides + history)
-- =============================================================
CREATE TABLE employee_salary (
    id                      CHAR(36)        NOT NULL DEFAULT (UUID()),
    employee_id             CHAR(36)        NOT NULL,
    salary_structure_id     CHAR(36)        NOT NULL,
    basic_salary            DECIMAL(12,2)   NOT NULL,
    hra                     DECIMAL(12,2)   NOT NULL,
    special_allowance       DECIMAL(12,2)   NOT NULL DEFAULT 0.00,
    effective_from          DATE            NOT NULL,
    effective_to            DATE            NULL COMMENT 'NULL = currently active',
    created_at              DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_emp_sal               PRIMARY KEY (id),
    CONSTRAINT fk_emp_sal_emp           FOREIGN KEY (employee_id)
        REFERENCES employees(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_emp_sal_struct        FOREIGN KEY (salary_structure_id)
        REFERENCES salary_structures(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_emp_sal_eff               (employee_id, effective_from)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =============================================================
-- 20. PAYROLL RUNS  (monthly batch header)
-- =============================================================
CREATE TABLE payroll_runs (
    id              CHAR(36)        NOT NULL DEFAULT (UUID()),
    month           TINYINT UNSIGNED NOT NULL COMMENT '1–12',
    year            YEAR            NOT NULL,
    status          ENUM('draft','processing','completed','cancelled')
                        NOT NULL DEFAULT 'draft',
    processed_by    CHAR(36)        NOT NULL COMMENT 'FK → users.id',
    run_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    finalized_at    DATETIME        NULL,
    CONSTRAINT pk_payroll_runs          PRIMARY KEY (id),
    CONSTRAINT uq_payroll_run_period    UNIQUE (month, year),
    CONSTRAINT chk_payroll_month        CHECK (month BETWEEN 1 AND 12),
    CONSTRAINT fk_payroll_run_user      FOREIGN KEY (processed_by)
        REFERENCES users(id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =============================================================
-- 21. PAYROLL RECORDS  (one row per employee per run)
-- =============================================================
CREATE TABLE payroll_records (
    id                  CHAR(36)        NOT NULL DEFAULT (UUID()),
    payroll_run_id      CHAR(36)        NOT NULL,
    employee_id         CHAR(36)        NOT NULL,
    working_days        TINYINT UNSIGNED NOT NULL DEFAULT 0,
    paid_days           TINYINT UNSIGNED NOT NULL DEFAULT 0,
    basic_salary        DECIMAL(12,2)   NOT NULL DEFAULT 0.00,
    hra                 DECIMAL(12,2)   NOT NULL DEFAULT 0.00,
    special_allowance   DECIMAL(12,2)   NOT NULL DEFAULT 0.00,
    gross_salary        DECIMAL(12,2)   NOT NULL DEFAULT 0.00,
    pf_deduction        DECIMAL(12,2)   NOT NULL DEFAULT 0.00 COMMENT '12% of basic',
    esi_deduction       DECIMAL(12,2)   NOT NULL DEFAULT 0.00 COMMENT '0.75% of gross',
    tds_deduction       DECIMAL(12,2)   NOT NULL DEFAULT 0.00,
    professional_tax    DECIMAL(12,2)   NOT NULL DEFAULT 0.00,
    loan_emi_deduction  DECIMAL(12,2)   NOT NULL DEFAULT 0.00,
    other_deductions    DECIMAL(12,2)   NOT NULL DEFAULT 0.00,
    total_deductions    DECIMAL(12,2)   NOT NULL DEFAULT 0.00,
    net_salary          DECIMAL(12,2)   NOT NULL DEFAULT 0.00,
    status              ENUM('draft','approved','disbursed') NOT NULL DEFAULT 'draft',
    created_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_payroll_rec           PRIMARY KEY (id),
    CONSTRAINT uq_payroll_rec_emp_run   UNIQUE (payroll_run_id, employee_id),
    CONSTRAINT fk_payroll_rec_run       FOREIGN KEY (payroll_run_id)
        REFERENCES payroll_runs(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_payroll_rec_emp       FOREIGN KEY (employee_id)
        REFERENCES employees(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_payroll_rec_emp           (employee_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =============================================================
-- 22. LOANS
-- =============================================================
CREATE TABLE loans (
    id                      CHAR(36)        NOT NULL DEFAULT (UUID()),
    employee_id             CHAR(36)        NOT NULL,
    principal_amount        DECIMAL(12,2)   NOT NULL,
    emi_amount              DECIMAL(12,2)   NOT NULL,
    total_installments      TINYINT UNSIGNED NOT NULL,
    paid_installments       TINYINT UNSIGNED NOT NULL DEFAULT 0,
    outstanding_amount      DECIMAL(12,2)   NOT NULL,
    disbursement_date       DATE            NOT NULL,
    status                  ENUM('active','closed','defaulted') NOT NULL DEFAULT 'active',
    approved_by             CHAR(36)        NOT NULL COMMENT 'FK → users.id',
    created_at              DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_loans             PRIMARY KEY (id),
    CONSTRAINT fk_loans_emp         FOREIGN KEY (employee_id)
        REFERENCES employees(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_loans_approver    FOREIGN KEY (approved_by)
        REFERENCES users(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_loans_emp             (employee_id, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =============================================================
-- 23. LOAN EMIs
-- =============================================================
CREATE TABLE loan_emis (
    id                  CHAR(36)        NOT NULL DEFAULT (UUID()),
    loan_id             CHAR(36)        NOT NULL,
    payroll_record_id   CHAR(36)        NULL COMMENT 'Linked once deducted',
    installment_number  TINYINT UNSIGNED NOT NULL,
    amount              DECIMAL(12,2)   NOT NULL,
    deduction_month     DATE            NOT NULL COMMENT 'First day of the month',
    status              ENUM('pending','deducted') NOT NULL DEFAULT 'pending',
    CONSTRAINT pk_loan_emis         PRIMARY KEY (id),
    CONSTRAINT uq_loan_emi_inst     UNIQUE (loan_id, installment_number),
    CONSTRAINT fk_loan_emis_loan    FOREIGN KEY (loan_id)
        REFERENCES loans(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_loan_emis_pay     FOREIGN KEY (payroll_record_id)
        REFERENCES payroll_records(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =============================================================
-- 24. REIMBURSEMENTS
-- =============================================================
CREATE TABLE reimbursements (
    id                  CHAR(36)        NOT NULL DEFAULT (UUID()),
    employee_id         CHAR(36)        NOT NULL,
    payroll_record_id   CHAR(36)        NULL COMMENT 'Linked when paid in payroll',
    description         VARCHAR(255)    NOT NULL,
    amount              DECIMAL(12,2)   NOT NULL,
    receipt_url         VARCHAR(500)    NULL,
    status              ENUM('pending','approved','rejected','paid')
                            NOT NULL DEFAULT 'pending',
    approved_by         CHAR(36)        NULL COMMENT 'FK → users.id',
    submitted_at        DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resolved_at         DATETIME        NULL,
    CONSTRAINT pk_reimbursements        PRIMARY KEY (id),
    CONSTRAINT fk_reimb_emp             FOREIGN KEY (employee_id)
        REFERENCES employees(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_reimb_pay             FOREIGN KEY (payroll_record_id)
        REFERENCES payroll_records(id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_reimb_approver        FOREIGN KEY (approved_by)
        REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =============================================================
-- 25. EMPLOYEE DOCUMENTS
-- =============================================================
CREATE TABLE employee_documents (
    id                      CHAR(36)        NOT NULL DEFAULT (UUID()),
    employee_id             CHAR(36)        NOT NULL,
    document_type           VARCHAR(30)     NOT NULL
        COMMENT 'aadhaar|pan|offer_letter|contract|other',
    document_url            VARCHAR(500)    NOT NULL,
    verification_status     ENUM('pending','verified','rejected')
                                NOT NULL DEFAULT 'pending',
    verified_by             CHAR(36)        NULL COMMENT 'FK → users.id',
    uploaded_at             DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    verified_at             DATETIME        NULL,
    CONSTRAINT pk_emp_docs          PRIMARY KEY (id),
    CONSTRAINT fk_emp_docs_emp      FOREIGN KEY (employee_id)
        REFERENCES employees(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_emp_docs_verifier FOREIGN KEY (verified_by)
        REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
    INDEX idx_emp_docs_type         (employee_id, document_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =============================================================
-- 26. DAILY TASKS
-- =============================================================
CREATE TABLE daily_tasks (
    id                  CHAR(36)        NOT NULL DEFAULT (UUID()),
    employee_id         CHAR(36)        NOT NULL,
    task_date           DATE            NOT NULL,
    description         TEXT            NOT NULL,
    status              ENUM('pending','in_progress','completed') NOT NULL DEFAULT 'pending',
    manager_comments    TEXT            NULL,
    reviewed_by         CHAR(36)        NULL COMMENT 'FK → users.id',
    created_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_daily_tasks       PRIMARY KEY (id),
    CONSTRAINT fk_tasks_emp         FOREIGN KEY (employee_id)
        REFERENCES employees(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_tasks_reviewer    FOREIGN KEY (reviewed_by)
        REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
    INDEX idx_tasks_date            (employee_id, task_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =============================================================
-- 27. NOTIFICATIONS
-- =============================================================
CREATE TABLE notifications (
    id              CHAR(36)        NOT NULL DEFAULT (UUID()),
    recipient_id    CHAR(36)        NOT NULL COMMENT 'FK → users.id',
    title           VARCHAR(150)    NOT NULL,
    message         TEXT            NOT NULL,
    channel         ENUM('whatsapp','email','sms','in_app') NOT NULL DEFAULT 'in_app',
    type            ENUM('leave','attendance','payroll','announcement','general')
                        NOT NULL DEFAULT 'general',
    is_read         TINYINT(1)      NOT NULL DEFAULT 0,
    sent_at         DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    read_at         DATETIME        NULL,
    CONSTRAINT pk_notifications         PRIMARY KEY (id),
    CONSTRAINT fk_notif_recipient       FOREIGN KEY (recipient_id)
        REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_notif_unread              (recipient_id, is_read)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =============================================================
-- 28. ACTIVITY LOGS  (immutable audit trail)
-- =============================================================
CREATE TABLE activity_logs (
    id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
        COMMENT 'Sequential INT for fast inserts on audit table',
    user_id         CHAR(36)        NOT NULL COMMENT 'FK → users.id',
    action          VARCHAR(80)     NOT NULL COMMENT 'e.g. CREATE, UPDATE, DELETE, LOGIN',
    entity_type     VARCHAR(60)     NOT NULL COMMENT 'e.g. employee, attendance, payroll_record',
    entity_id       CHAR(36)        NULL,
    old_values      JSON            NULL,
    new_values      JSON            NULL,
    ip_address      VARCHAR(45)     NULL COMMENT 'IPv4 or IPv6',
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_activity_logs     PRIMARY KEY (id),
    CONSTRAINT fk_act_log_user      FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_act_log_entity        (entity_type, entity_id),
    INDEX idx_act_log_user          (user_id),
    INDEX idx_act_log_created       (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =============================================================
-- RE-ENABLE FK CHECKS
-- =============================================================
SET FOREIGN_KEY_CHECKS = 1;

-- =============================================================
-- END OF SCHEMA
-- 28 tables | InnoDB | utf8mb4_unicode_ci
-- =============================================================