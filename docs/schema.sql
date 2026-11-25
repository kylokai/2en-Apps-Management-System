-- =============================================================================
-- 2en Apps HR Management System
-- Module: Staff Profile and Details
-- Database schema â€” MySQL 8.0
-- Version 1.0 | 18 November 2026
--
-- NOTES
--  * Columns suffixed _enc are VARBINARY and MUST be encrypted by the
--    application layer (AES-256-GCM) before INSERT/UPDATE. Never store
--    plaintext NRIC / passport / bank numbers.
--  * Columns suffixed _hash store HMAC-SHA256 (server secret) for exact
--    lookup of encrypted identifiers without decrypting every row.
--  * Rates, ceilings and statutory rules live in ref_statutory_rule and are
--    versioned by effective_from / effective_to. Do not hard-code them.
--  * audit_logs is append-only (enforced by triggers at the end of file).
-- =============================================================================

CREATE DATABASE IF NOT EXISTS hr_system
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE hr_system;

-- -----------------------------------------------------------------------------
-- 0. Reset (UNCOMMENT ONLY ON A FRESH DEVELOPMENT DATABASE)
-- -----------------------------------------------------------------------------
-- SET FOREIGN_KEY_CHECKS = 0;
-- DROP TABLE IF EXISTS audit_logs, generated_letters, letter_templates,
--   notifications, approval_steps, change_requests, statutory_profiles,
--   bank_accounts, employee_documents, employee_certifications, employee_skills,
--   employee_experience, employee_education, employee_family, employment_history,
--   employees, user_roles, role_permissions, user_accounts, permissions, roles,
--   positions, departments, branches, companies, ref_statutory_rule,
--   ref_relationship, ref_employment_type, ref_document_type, ref_bank,
--   ref_state, ref_nationality, ref_religion, ref_race, ref_gender;
-- SET FOREIGN_KEY_CHECKS = 1;

-- =============================================================================
-- 1. REFERENCE / LOOKUP TABLES
-- =============================================================================

CREATE TABLE ref_gender (
  code        VARCHAR(10)  NOT NULL PRIMARY KEY,
  label_en    VARCHAR(50)  NOT NULL,
  label_bm    VARCHAR(50)  NOT NULL,
  is_active   BOOLEAN      NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;
INSERT INTO ref_gender (code,label_en,label_bm) VALUES
  ('M','Male','Lelaki'), ('F','Female','Perempuan');

CREATE TABLE ref_race (
  code        VARCHAR(20)  NOT NULL PRIMARY KEY,
  label_en    VARCHAR(50)  NOT NULL,
  label_bm    VARCHAR(50)  NOT NULL,
  is_active   BOOLEAN      NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;
INSERT INTO ref_race (code,label_en,label_bm) VALUES
  ('MALAY','Malay','Melayu'), ('CHINESE','Chinese','Cina'),
  ('INDIAN','Indian','India'), ('BUMIPUTERA_OTHER','Other Bumiputera','Bumiputera Lain'),
  ('OTHER','Other','Lain-lain');

CREATE TABLE ref_religion (
  code        VARCHAR(20)  NOT NULL PRIMARY KEY,
  label_en    VARCHAR(50)  NOT NULL,
  label_bm    VARCHAR(50)  NOT NULL,
  is_active   BOOLEAN      NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;
INSERT INTO ref_religion (code,label_en,label_bm) VALUES
  ('ISLAM','Islam','Islam'), ('BUDDHISM','Buddhism','Buddha'),
  ('CHRISTIANITY','Christianity','Kristian'), ('HINDUISM','Hinduism','Hindu'),
  ('OTHER','Other','Lain-lain'), ('NONE','None','Tiada');

CREATE TABLE ref_nationality (
  code        VARCHAR(30)  NOT NULL PRIMARY KEY,
  label_en    VARCHAR(60)  NOT NULL,
  is_active   BOOLEAN      NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;
INSERT INTO ref_nationality (code,label_en) VALUES
  ('MALAYSIAN','Malaysian'), ('INDONESIAN','Indonesian'), ('BANGLADESHI','Bangladeshi'),
  ('INDIAN','Indian'), ('CHINESE','Chinese'), ('NEPALI','Nepali'), ('OTHER','Other');

CREATE TABLE ref_state (
  code        VARCHAR(30)  NOT NULL PRIMARY KEY,
  label_en    VARCHAR(60)  NOT NULL,
  region      VARCHAR(20)  NOT NULL COMMENT 'PENINSULAR | SABAH | SARAWAK | FEDERAL',
  is_active   BOOLEAN      NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;
INSERT INTO ref_state (code,label_en,region) VALUES
  ('JOHOR','Johor','PENINSULAR'), ('KEDAH','Kedah','PENINSULAR'),
  ('KELANTAN','Kelantan','PENINSULAR'), ('MELAKA','Melaka','PENINSULAR'),
  ('NEGERI_SEMBILAN','Negeri Sembilan','PENINSULAR'), ('PAHANG','Pahang','PENINSULAR'),
  ('PERAK','Perak','PENINSULAR'), ('PERLIS','Perlis','PENINSULAR'),
  ('PULAU_PINANG','Pulau Pinang','PENINSULAR'), ('SELANGOR','Selangor','PENINSULAR'),
  ('TERENGGANU','Terengganu','PENINSULAR'), ('SABAH','Sabah','SABAH'),
  ('SARAWAK','Sarawak','SARAWAK'), ('WP_KL','W.P. Kuala Lumpur','FEDERAL'),
  ('WP_LABUAN','W.P. Labuan','FEDERAL'), ('WP_PUTRAJAYA','W.P. Putrajaya','FEDERAL');

CREATE TABLE ref_bank (
  code        VARCHAR(20)  NOT NULL PRIMARY KEY,
  label_en    VARCHAR(80)  NOT NULL,
  is_active   BOOLEAN      NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;
INSERT INTO ref_bank (code,label_en) VALUES
  ('MAYBANK','Maybank'), ('CIMB','CIMB Bank'), ('PUBLIC','Public Bank'),
  ('RHB','RHB Bank'), ('HONG_LEONG','Hong Leong Bank'), ('UOB','United Overseas Bank'),
  ('OCBC','OCBC Bank'), ('STANDARD_CHARTERED','Standard Chartered'), ('HSBC','HSBC'),
  ('ALLIANCE','Alliance Bank'), ('AFFIN','Affin Bank'), ('BANK_ISLAM','Bank Islam'),
  ('BANK_RAKYAT','Bank Rakyat'), ('AGROBANK','Agrobank'), ('BSN','Bank Simpanan Nasional'),
  ('MAYBANK_ISLAMIC','Maybank Islamic'), ('CIMB_ISLAMIC','CIMB Islamic');

CREATE TABLE ref_document_type (
  code          VARCHAR(30)  NOT NULL PRIMARY KEY,
  label_en      VARCHAR(80)  NOT NULL,
  label_bm      VARCHAR(80)  NOT NULL,
  needs_expiry  BOOLEAN      NOT NULL DEFAULT FALSE,
  alert_days    SMALLINT     NOT NULL DEFAULT 30,
  is_sensitive  BOOLEAN      NOT NULL DEFAULT FALSE
) ENGINE=InnoDB;
INSERT INTO ref_document_type (code,label_en,label_bm,needs_expiry,alert_days,is_sensitive) VALUES
  ('IC','Identity Card','Kad Pengenalan',FALSE,30,TRUE),
  ('PASSPORT','Passport','Pasport',TRUE,60,TRUE),
  ('BIRTH_CERT','Birth Certificate','Sijil Kelahiran',FALSE,30,TRUE),
  ('OFFER_LETTER','Offer Letter','Surat Tawaran',FALSE,30,FALSE),
  ('CONTRACT','Employment Contract','Kontrak Pekerjaan',TRUE,30,FALSE),
  ('ACADEMIC_CERT','Academic Certificate','Sijil Akademik',FALSE,30,FALSE),
  ('PROFESSIONAL_CERT','Professional Certificate','Sijil Profesional',TRUE,30,FALSE),
  ('MEDICAL_CERT','Medical Certificate / Record','Sijil Perubatan / Rekod',TRUE,30,TRUE),
  ('WORK_PERMIT','Work Permit / Visa','Permit Kerja / Visa',TRUE,60,TRUE),
  ('DRIVING_LICENCE','Driving Licence','Lesen Memandu',TRUE,30,TRUE),
  ('LETTER','HR Correspondence','Surat-menyurat HR',FALSE,30,FALSE),
  ('OTHER','Other','Lain-lain',FALSE,30,FALSE);

CREATE TABLE ref_employment_type (
  code        VARCHAR(30)  NOT NULL PRIMARY KEY,
  label_en    VARCHAR(60)  NOT NULL,
  label_bm    VARCHAR(60)  NOT NULL,
  is_active   BOOLEAN      NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;
INSERT INTO ref_employment_type (code,label_en,label_bm) VALUES
  ('PERMANENT','Permanent','Tetap'), ('CONTRACT','Contract','Kontrak'),
  ('PROBATION','Probation','Percubaan'), ('INTERN','Intern','Pelatih'),
  ('PART_TIME','Part-time','Sambilan'), ('FOREIGN_WORKER','Foreign Worker','Pekerja Asing'),
  ('DIRECTOR','Director','Pengarah');

CREATE TABLE ref_relationship (
  code        VARCHAR(30)  NOT NULL PRIMARY KEY,
  label_en    VARCHAR(60)  NOT NULL,
  label_bm    VARCHAR(60)  NOT NULL
) ENGINE=InnoDB;
INSERT INTO ref_relationship (code,label_en,label_bm) VALUES
  ('SPOUSE','Spouse','Pasangan'), ('PARENT','Parent','Ibu Bapa'),
  ('CHILD','Child','Anak'), ('SIBLING','Sibling','Adik Beradik'),
  ('FRIEND','Friend','Rakan'), ('OTHER','Other','Lain-lain');

CREATE TABLE ref_statutory_rule (
  id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  rule_code       VARCHAR(40)   NOT NULL COMMENT 'EPF_EMP, EPF_ER, SOCSO_EMP, SOCSO_ER, EIS_EMP, EIS_ER, HRD_LEVY, MIN_WAGE',
  region_rule_set VARCHAR(20)   NOT NULL DEFAULT 'EMACT_1955',
  rate_percent    DECIMAL(6,3)  NULL,
  flat_amount     DECIMAL(10,2) NULL,
  wage_ceiling    DECIMAL(10,2) NULL,
  age_condition   VARCHAR(40)   NULL COMMENT 'e.g. <60, >=60, 18-60',
  effective_from  DATE          NOT NULL,
  effective_to    DATE          NULL,
  source_ref      VARCHAR(255)  NULL,
  notes           TEXT          NULL,
  created_at      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_rule (rule_code, effective_from),
  KEY idx_region (region_rule_set)
) ENGINE=InnoDB;
-- Reference values only â€” verify with KWSP / PERKESO / LHDN before go-live.
INSERT INTO ref_statutory_rule (rule_code,rate_percent,wage_ceiling,age_condition,effective_from,source_ref) VALUES
  ('EPF_EMP',11.000,5000.00,NULL,'2025-01-01','EPF Act 1991 Third Schedule'),
  ('EPF_ER',13.000,5000.00,NULL,'2025-01-01','EPF Act 1991 Third Schedule'),
  ('EPF_ER_ABOVE',12.000,NULL,'>5000','2025-01-01','EPF Act 1991 Third Schedule'),
  ('EPF_FOREIGN_EMP',2.000,NULL,'FOREIGN','2025-10-01','KWSP circular'),
  ('EPF_FOREIGN_ER',2.000,NULL,'FOREIGN','2025-10-01','KWSP circular'),
  ('SOCSO_EMP',0.500,6000.00,'<60','2025-01-01','SOCSO Act 1969'),
  ('SOCSO_ER',1.750,6000.00,'<60','2025-01-01','SOCSO Act 1969'),
  ('SOCSO_ER_60',1.250,6000.00,'>=60','2025-01-01','SOCSO Act 1969'),
  ('EIS_EMP',0.200,6000.00,'18-60','2025-01-01','EIS Act 2017'),
  ('EIS_ER',0.200,6000.00,'18-60','2025-01-01','EIS Act 2017'),
  ('HRD_LEVY',1.000,NULL,'CITIZEN>=10','2025-01-01','HRD Corp Act 2001'),
  ('MIN_WAGE',NULL,1700.00,'MONTHLY','2025-02-01','Minimum Wages Order 2024');

-- =============================================================================
-- 2. ORGANISATION STRUCTURE
-- =============================================================================

CREATE TABLE companies (
  id                  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name                VARCHAR(150)  NOT NULL,
  registration_no     VARCHAR(40)   NULL COMMENT 'SSM number',
  address             TEXT          NULL,
  state_code          VARCHAR(30)   NULL,
  country             VARCHAR(50)   NOT NULL DEFAULT 'MALAYSIA',
  region_rule_set     VARCHAR(20)   NOT NULL DEFAULT 'EMACT_1955' COMMENT 'EMACT_1955 | SABAH | SARAWAK',
  epf_employer_no     VARCHAR(40)   NULL,
  socso_employer_no   VARCHAR(40)   NULL,
  lhdn_tax_no         VARCHAR(40)   NULL,
  hrd_corp_reg_no     VARCHAR(40)   NULL,
  is_active           BOOLEAN       NOT NULL DEFAULT TRUE,
  created_at          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE branches (
  id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  company_id  BIGINT UNSIGNED NOT NULL,
  name        VARCHAR(120)  NOT NULL,
  code        VARCHAR(20)   NOT NULL,
  address     TEXT          NULL,
  state_code  VARCHAR(30)   NULL,
  is_active   BOOLEAN       NOT NULL DEFAULT TRUE,
  created_at  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_branch_code (company_id, code),
  CONSTRAINT fk_branch_company FOREIGN KEY (company_id) REFERENCES companies(id)
) ENGINE=InnoDB;

CREATE TABLE departments (
  id                BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  company_id        BIGINT UNSIGNED NOT NULL,
  branch_id         BIGINT UNSIGNED NULL,
  parent_id         BIGINT UNSIGNED NULL COMMENT 'org tree, self reference',
  name              VARCHAR(120)  NOT NULL,
  code              VARCHAR(20)   NOT NULL,
  head_employee_id  BIGINT UNSIGNED NULL COMMENT 'FK added logically; no DB FK to avoid circular dependency with employees',
  cost_centre       VARCHAR(40)   NULL,
  is_active         BOOLEAN       NOT NULL DEFAULT TRUE,
  created_at        DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at        DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_dept_code (company_id, code),
  KEY idx_dept_parent (parent_id),
  CONSTRAINT fk_dept_company FOREIGN KEY (company_id) REFERENCES companies(id),
  CONSTRAINT fk_dept_branch  FOREIGN KEY (branch_id)  REFERENCES branches(id)
) ENGINE=InnoDB;

CREATE TABLE positions (
  id                    BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  company_id            BIGINT UNSIGNED NOT NULL,
  department_id         BIGINT UNSIGNED NOT NULL,
  title                 VARCHAR(120)  NOT NULL,
  code                  VARCHAR(20)   NOT NULL,
  job_grade             VARCHAR(20)   NULL,
  job_description       TEXT          NULL,
  duties_responsibilities TEXT        NULL,
  manpower_quota        SMALLINT      NULL,
  is_active             BOOLEAN       NOT NULL DEFAULT TRUE,
  created_at            DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at            DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_pos_code (company_id, code),
  CONSTRAINT fk_pos_company FOREIGN KEY (company_id)    REFERENCES companies(id),
  CONSTRAINT fk_pos_dept    FOREIGN KEY (department_id) REFERENCES departments(id)
) ENGINE=InnoDB;

-- =============================================================================
-- 3. AUTHENTICATION & AUTHORISATION (RBAC)
-- =============================================================================

CREATE TABLE roles (
  id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  code          VARCHAR(40)  NOT NULL UNIQUE,
  name          VARCHAR(80)  NOT NULL,
  description   VARCHAR(255) NULL,
  is_system     BOOLEAN      NOT NULL DEFAULT TRUE,
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;
INSERT INTO roles (code,name,description) VALUES
  ('OWNER_BOSS','Owner / Boss','Company owner; final approvals, no employee self-service'),
  ('HR_ADMIN','HR Admin','Creates and maintains all employee data'),
  ('MANAGER','Manager','Team-scoped visibility and leave approvals'),
  ('STAFF','Staff','Own profile, attendance, leave and claims'),
  ('INTERN','Intern','Limited self-service access'),
  ('HR_MANAGER','HR Manager','Approves sensitive changes, full visibility'),
  ('LINE_MANAGER','Line Manager','Team-scoped visibility and approvals'),
  ('EMPLOYEE','Employee','Own profile (ESS) only'),
  ('FINANCE','Finance / Payroll','Read-only salary, bank, statutory fields'),
  ('IT_ADMIN','IT Administrator','Users, roles, integrations; no salary by default'),
  ('AUDITOR','Auditor','Read-only + audit log + download log'),
  ('DPO','Data Protection Officer','Privacy, consent, breach and access requests');

CREATE TABLE permissions (
  id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  code          VARCHAR(80)  NOT NULL UNIQUE COMMENT 'resource.action.scope, e.g. employee.salary.view',
  module        VARCHAR(40)  NOT NULL,
  description   VARCHAR(255) NULL
) ENGINE=InnoDB;
INSERT INTO permissions (code,module,description) VALUES
  ('employee.profile.view.all','Core HR','View any employee profile'),
  ('employee.profile.view.team','Core HR','View team employee profiles'),
  ('employee.profile.view.own','Core HR','View own profile'),
  ('employee.profile.edit.all','Core HR','Edit any employee profile'),
  ('employee.profile.edit.own','Core HR','Request edit of own profile'),
  ('employee.salary.view','Core HR','View salary fields'),
  ('employee.salary.edit','Core HR','Edit salary fields'),
  ('employee.bank.view','Core HR','View bank fields'),
  ('employee.statutory.view','Core HR','View EPF/SOCSO/LHDN fields'),
  ('employee.document.view.sensitive','Core HR','View sensitive documents'),
  ('changerequest.approve','Core HR','Approve change requests'),
  ('auditlog.view','Core HR','View audit log'),
  ('report.export','Core HR','Export HR/statutory reports'),
  ('user.manage','Admin','Manage users and roles'),
  ('privacy.manage','Admin','Manage consent and data subject requests');

CREATE TABLE role_permissions (
  role_id         BIGINT UNSIGNED NOT NULL,
  permission_id   BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (role_id, permission_id),
  CONSTRAINT fk_rp_role FOREIGN KEY (role_id)       REFERENCES roles(id),
  CONSTRAINT fk_rp_perm FOREIGN KEY (permission_id) REFERENCES permissions(id)
) ENGINE=InnoDB;

CREATE TABLE user_accounts (
  id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  username        VARCHAR(80)   NOT NULL UNIQUE,
  email           VARCHAR(150)  NOT NULL UNIQUE,
  password_hash   VARCHAR(255)  NOT NULL,
  mfa_enabled     BOOLEAN       NOT NULL DEFAULT FALSE,
  status          VARCHAR(20)   NOT NULL DEFAULT 'Active' COMMENT 'Active | Locked | Disabled',
  last_login_at   DATETIME      NULL,
  password_changed_at DATETIME  NULL,
  created_by      BIGINT UNSIGNED NULL,
  created_at      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE user_roles (
  user_id   BIGINT UNSIGNED NOT NULL,
  role_id   BIGINT UNSIGNED NOT NULL,
  scope_company_id BIGINT UNSIGNED NULL COMMENT 'NULL = all companies',
  scope_department_id BIGINT UNSIGNED NULL COMMENT 'NULL = all departments',
  assigned_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, role_id),
  CONSTRAINT fk_ur_user FOREIGN KEY (user_id) REFERENCES user_accounts(id),
  CONSTRAINT fk_ur_role FOREIGN KEY (role_id) REFERENCES roles(id)
) ENGINE=InnoDB;

-- =============================================================================
-- 4. EMPLOYEE MASTER & LIFECYCLE
-- =============================================================================

CREATE TABLE employees (
  id                        BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  employee_no               VARCHAR(30)   NOT NULL UNIQUE COMMENT 'e.g. EMP-2026-0042',
  company_id                BIGINT UNSIGNED NOT NULL,
  branch_id                 BIGINT UNSIGNED NULL,
  department_id             BIGINT UNSIGNED NULL,
  position_id               BIGINT UNSIGNED NULL,
  reports_to_employee_id    BIGINT UNSIGNED NULL COMMENT 'line manager',
  user_id                   BIGINT UNSIGNED NULL COMMENT 'login account',

  -- Personal / identity
  first_name                VARCHAR(80)   NOT NULL,
  last_name                 VARCHAR(80)   NOT NULL,
  full_name                 VARCHAR(150)  NOT NULL,
  id_type                   VARCHAR(20)   NOT NULL DEFAULT 'IC' COMMENT 'IC | PASSPORT | WORK_PERMIT',
  id_number_enc             VARBINARY(512) NULL COMMENT 'AES-256-GCM encrypted NRIC/passport',
  id_number_hash            CHAR(64)      NULL COMMENT 'HMAC-SHA256 for lookup',
  date_of_birth             DATE          NULL,
  gender_code               VARCHAR(10)   NULL,
  race_code                 VARCHAR(20)   NULL,
  religion_code             VARCHAR(20)   NULL,
  nationality_code          VARCHAR(30)   NOT NULL DEFAULT 'MALAYSIAN',
  marital_status            VARCHAR(20)   NULL COMMENT 'SINGLE | MARRIED | DIVORCED | WIDOWED',

  -- Contact
  address_1                 VARCHAR(200)  NULL,
  address_2                 VARCHAR(200)  NULL,
  city                      VARCHAR(80)   NULL,
  postcode                  VARCHAR(10)   NULL,
  state_code                VARCHAR(30)   NULL,
  country                   VARCHAR(50)   NOT NULL DEFAULT 'MALAYSIA',
  phone                     VARCHAR(30)   NULL,
  email                     VARCHAR(150)  NULL,

  -- Emergency contact & next of kin
  emergency_contact_name        VARCHAR(150) NULL,
  emergency_contact_relationship VARCHAR(30) NULL,
  emergency_contact_phone       VARCHAR(30)  NULL,
  next_of_kin_name              VARCHAR(150) NULL,
  next_of_kin_relationship      VARCHAR(30)  NULL,
  next_of_kin_phone             VARCHAR(30)  NULL,

  -- Employment
  employment_type           VARCHAR(30)   NOT NULL DEFAULT 'PERMANENT',
  employment_status         VARCHAR(20)   NOT NULL DEFAULT 'Pending'
    COMMENT 'Pending | Probation | Active | OnLeave | Suspended | Resigned | Terminated | ExEmployee',
  hire_date                 DATE          NULL,
  confirmation_date         DATE          NULL,
  probation_end_date        DATE          NULL,
  probation_months          TINYINT UNSIGNED DEFAULT 3,
  notice_period_days        SMALLINT UNSIGNED NULL,
  notice_date               DATE          NULL,
  last_working_day          DATE          NULL,
  termination_date          DATE          NULL,
  termination_reason        VARCHAR(255)  NULL,

  -- Compensation (restricted + audited)
  basic_salary              DECIMAL(12,2) NULL,
  salary_type               VARCHAR(20)   NULL DEFAULT 'MONTHLY',
  bank_id                   VARCHAR(20)   NULL,
  bank_account_enc          VARBINARY(512) NULL COMMENT 'encrypted bank account number',
  bank_account_type         VARCHAR(20)   NULL COMMENT 'SAVINGS | CURRENT',

  -- Statutory (restricted)
  epf_member_no             VARCHAR(40)   NULL,
  socso_member_no           VARCHAR(40)   NULL,
  eis_eligible              BOOLEAN       NOT NULL DEFAULT TRUE,
  lhdn_tax_no               VARCHAR(40)   NULL,
  hrd_corp_no               VARCHAR(40)   NULL,
  work_permit_no            VARCHAR(40)   NULL,
  work_permit_expiry        DATE          NULL,

  -- Extras
  photo_path                VARCHAR(255)  NULL,

  -- PDPA / privacy
  pdpa_notice_version       VARCHAR(20)   NULL,
  pdpa_consent_at           DATETIME      NULL,
  consent_biometrics        BOOLEAN       NOT NULL DEFAULT FALSE,
  biometric_consent_at      DATETIME      NULL,

  -- Retention & audit
  retention_class           VARCHAR(30)   NOT NULL DEFAULT 'EMPLOYEE_STANDARD',
  retention_until           DATE          NULL,
  created_by                BIGINT UNSIGNED NULL,
  updated_by                BIGINT UNSIGNED NULL,
  created_at                DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at                DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at                DATETIME      NULL,

  KEY idx_emp_company_status (company_id, employment_status),
  KEY idx_emp_branch (branch_id),
  KEY idx_emp_dept (department_id),
  KEY idx_emp_position (position_id),
  KEY idx_emp_manager (reports_to_employee_id),
  KEY idx_emp_name (full_name),
  KEY idx_emp_id_hash (id_number_hash),
  KEY idx_emp_email (email),
  KEY idx_emp_permit_expiry (work_permit_expiry),
  CONSTRAINT fk_emp_company  FOREIGN KEY (company_id)             REFERENCES companies(id),
  CONSTRAINT fk_emp_branch   FOREIGN KEY (branch_id)              REFERENCES branches(id),
  CONSTRAINT fk_emp_dept     FOREIGN KEY (department_id)          REFERENCES departments(id),
  CONSTRAINT fk_emp_position FOREIGN KEY (position_id)            REFERENCES positions(id),
  CONSTRAINT fk_emp_manager  FOREIGN KEY (reports_to_employee_id) REFERENCES employees(id),
  CONSTRAINT fk_emp_user     FOREIGN KEY (user_id)                REFERENCES user_accounts(id)
) ENGINE=InnoDB COMMENT='Single canonical employee record';

CREATE TABLE employment_history (
  id                  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  employee_id         BIGINT UNSIGNED NOT NULL,
  event_type          VARCHAR(30)   NOT NULL COMMENT 'Onboard|Confirm|Transfer|Promotion|SalaryRevision|Discipline|Resign|Terminate|Rehire',
  effective_date      DATE          NOT NULL,
  from_position_id    BIGINT UNSIGNED NULL,
  to_position_id      BIGINT UNSIGNED NULL,
  from_department_id  BIGINT UNSIGNED NULL,
  to_department_id    BIGINT UNSIGNED NULL,
  from_branch_id      BIGINT UNSIGNED NULL,
  to_branch_id        BIGINT UNSIGNED NULL,
  from_salary         DECIMAL(12,2) NULL,
  to_salary           DECIMAL(12,2) NULL,
  from_manager_id     BIGINT UNSIGNED NULL,
  to_manager_id       BIGINT UNSIGNED NULL,
  change_reason       VARCHAR(255)  NULL,
  document_ref        VARCHAR(255)  NULL,
  created_by          BIGINT UNSIGNED NULL,
  created_at          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_hist_employee (employee_id, effective_date),
  CONSTRAINT fk_hist_employee FOREIGN KEY (employee_id) REFERENCES employees(id)
) ENGINE=InnoDB COMMENT='Append-only employment timeline';

-- =============================================================================
-- 5. EMPLOYEE DETAIL CHILD TABLES
-- =============================================================================

CREATE TABLE employee_family (
  id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  employee_id   BIGINT UNSIGNED NOT NULL,
  full_name     VARCHAR(150)  NOT NULL,
  relationship  VARCHAR(30)   NOT NULL,
  id_number_enc VARBINARY(512) NULL,
  date_of_birth DATE          NULL,
  occupation    VARCHAR(100)  NULL,
  phone         VARCHAR(30)   NULL,
  is_dependant  BOOLEAN       NOT NULL DEFAULT FALSE,
  is_emergency_contact BOOLEAN NOT NULL DEFAULT FALSE,
  remarks       TEXT          NULL,
  created_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_family_emp (employee_id),
  CONSTRAINT fk_family_emp FOREIGN KEY (employee_id) REFERENCES employees(id)
) ENGINE=InnoDB;

CREATE TABLE employee_education (
  id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  employee_id   BIGINT UNSIGNED NOT NULL,
  institution   VARCHAR(150)  NOT NULL,
  qualification VARCHAR(120)  NOT NULL,
  field_of_study VARCHAR(120) NULL,
  start_date    DATE          NULL,
  end_date      DATE          NULL,
  result        VARCHAR(60)   NULL,
  is_highest    BOOLEAN       NOT NULL DEFAULT FALSE,
  document_id   BIGINT UNSIGNED NULL,
  created_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_edu_emp (employee_id),
  CONSTRAINT fk_edu_emp FOREIGN KEY (employee_id) REFERENCES employees(id)
) ENGINE=InnoDB;

CREATE TABLE employee_experience (
  id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  employee_id   BIGINT UNSIGNED NOT NULL,
  company_name  VARCHAR(150)  NOT NULL,
  title         VARCHAR(120)  NOT NULL,
  start_date    DATE          NULL,
  end_date      DATE          NULL,
  monthly_salary DECIMAL(12,2) NULL,
  reason_for_leaving VARCHAR(255) NULL,
  created_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_exp_emp (employee_id),
  CONSTRAINT fk_exp_emp FOREIGN KEY (employee_id) REFERENCES employees(id)
) ENGINE=InnoDB;

CREATE TABLE employee_skills (
  id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  employee_id   BIGINT UNSIGNED NOT NULL,
  skill_name    VARCHAR(120)  NOT NULL,
  proficiency   VARCHAR(30)   NULL COMMENT 'Beginner|Intermediate|Advanced|Expert',
  years_experience DECIMAL(4,1) NULL,
  created_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_skill_emp (employee_id),
  CONSTRAINT fk_skill_emp FOREIGN KEY (employee_id) REFERENCES employees(id)
) ENGINE=InnoDB;

CREATE TABLE employee_certifications (
  id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  employee_id     BIGINT UNSIGNED NOT NULL,
  name            VARCHAR(150)  NOT NULL,
  issuing_body    VARCHAR(150)  NULL,
  certificate_no  VARCHAR(80)   NULL,
  issue_date      DATE          NULL,
  expiry_date     DATE          NULL,
  document_id     BIGINT UNSIGNED NULL,
  created_at      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_cert_emp (employee_id),
  KEY idx_cert_expiry (expiry_date),
  CONSTRAINT fk_cert_emp FOREIGN KEY (employee_id) REFERENCES employees(id)
) ENGINE=InnoDB;

CREATE TABLE employee_documents (
  id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  employee_id     BIGINT UNSIGNED NOT NULL,
  document_type   VARCHAR(30)   NOT NULL,
  title           VARCHAR(150)  NOT NULL,
  file_path       VARCHAR(500)  NOT NULL COMMENT 'object storage key, never public URL',
  file_hash       CHAR(64)      NOT NULL COMMENT 'SHA-256 integrity check',
  mime_type       VARCHAR(100)  NOT NULL,
  size_bytes      INT UNSIGNED  NOT NULL,
  version         SMALLINT      NOT NULL DEFAULT 1,
  issue_date      DATE          NULL,
  expiry_date     DATE          NULL,
  is_verified     BOOLEAN       NOT NULL DEFAULT FALSE,
  verified_by     BIGINT UNSIGNED NULL,
  verified_at     DATETIME      NULL,
  is_sensitive    BOOLEAN       NOT NULL DEFAULT FALSE,
  retention_class VARCHAR(30)   NOT NULL DEFAULT 'DOC_STANDARD',
  uploaded_by     BIGINT UNSIGNED NULL,
  created_at      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_doc_emp (employee_id),
  KEY idx_doc_type (document_type),
  KEY idx_doc_expiry (expiry_date),
  CONSTRAINT fk_doc_emp FOREIGN KEY (employee_id) REFERENCES employees(id)
) ENGINE=InnoDB COMMENT='Versioned document repository with expiry alerts';

CREATE TABLE bank_accounts (
  id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  employee_id     BIGINT UNSIGNED NOT NULL,
  bank_id         VARCHAR(20)   NOT NULL,
  account_no_enc  VARBINARY(512) NOT NULL,
  account_holder_name VARCHAR(150) NULL,
  account_type    VARCHAR(20)   NOT NULL DEFAULT 'SAVINGS',
  is_primary      BOOLEAN       NOT NULL DEFAULT FALSE,
  is_active       BOOLEAN       NOT NULL DEFAULT TRUE,
  created_at      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_bank_emp (employee_id),
  CONSTRAINT fk_bank_emp FOREIGN KEY (employee_id) REFERENCES employees(id)
) ENGINE=InnoDB;

CREATE TABLE statutory_profiles (
  id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  employee_id     BIGINT UNSIGNED NOT NULL,
  epf_member_no   VARCHAR(40)  NULL,
  epf_effective_date DATE       NULL,
  epf_contrib_rate DECIMAL(6,3) NULL,
  socso_member_no VARCHAR(40)  NULL,
  socso_category  VARCHAR(20)  NULL COMMENT 'UNDER_60 | OVER_60 | FOREIGN',
  eis_eligible    BOOLEAN      NOT NULL DEFAULT TRUE,
  lhdn_tax_no     VARCHAR(40)  NULL,
  tax_status      VARCHAR(20)  NULL COMMENT 'RESIDENT | NON_RESIDENT',
  pcb_method      VARCHAR(20)  NULL COMMENT 'MTD | STREAMLINED',
  hrd_corp_no     VARCHAR(40)  NULL,
  foreign_worker_flag BOOLEAN  NOT NULL DEFAULT FALSE,
  lindung_24jam_optout BOOLEAN NOT NULL DEFAULT FALSE,
  contribution_overrides JSON  NULL,
  effective_from  DATE         NOT NULL,
  effective_to    DATE         NULL,
  created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_stat_emp (employee_id, effective_from),
  CONSTRAINT fk_stat_emp FOREIGN KEY (employee_id) REFERENCES employees(id)
) ENGINE=InnoDB COMMENT='Stricter isolation of statutory identifiers';

-- =============================================================================
-- 6. CHANGE REQUESTS, NOTIFICATIONS, CORRESPONDENCE, AUDIT
-- =============================================================================

CREATE TABLE change_requests (
  id                    BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  request_no            VARCHAR(30)  NOT NULL UNIQUE,
  employee_id           BIGINT UNSIGNED NOT NULL,
  requested_by          BIGINT UNSIGNED NOT NULL,
  field_group           VARCHAR(40)  NOT NULL COMMENT 'PERSONAL|BANK|STATUTORY|SALARY|DOCUMENT|EMPLOYMENT',
  changes_json          JSON         NOT NULL COMMENT '[{"field":"phone","old":"...","new":"..."}]',
  reason                VARCHAR(500) NULL,
  supporting_doc_ids    JSON         NULL,
  status                VARCHAR(20)  NOT NULL DEFAULT 'Pending'
    COMMENT 'Pending | Approved | Rejected | Cancelled',
  current_approver_role VARCHAR(40)  NULL,
  submitted_at          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  resolved_at           DATETIME     NULL,
  resolved_by           BIGINT UNSIGNED NULL,
  resolution_note       VARCHAR(500) NULL,
  created_at            DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at            DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_cr_employee (employee_id),
  KEY idx_cr_status (status),
  CONSTRAINT fk_cr_employee FOREIGN KEY (employee_id)  REFERENCES employees(id),
  CONSTRAINT fk_cr_requester FOREIGN KEY (requested_by) REFERENCES user_accounts(id)
) ENGINE=InnoDB;

CREATE TABLE approval_steps (
  id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  change_request_id BIGINT UNSIGNED NOT NULL,
  step_order      SMALLINT     NOT NULL,
  approver_role   VARCHAR(40)  NOT NULL,
  approver_user_id BIGINT UNSIGNED NULL,
  action          VARCHAR(20)  NULL COMMENT 'Approve | Reject | Escalate',
  action_at       DATETIME     NULL,
  notes           VARCHAR(500) NULL,
  KEY idx_as_request (change_request_id, step_order),
  CONSTRAINT fk_as_request FOREIGN KEY (change_request_id) REFERENCES change_requests(id),
  CONSTRAINT fk_as_user FOREIGN KEY (approver_user_id) REFERENCES user_accounts(id)
) ENGINE=InnoDB;

CREATE TABLE notifications (
  id                BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  recipient_user_id BIGINT UNSIGNED NOT NULL,
  channel           VARCHAR(20)  NOT NULL COMMENT 'EMAIL|SMS|INAPP|WHATSAPP',
  template_code     VARCHAR(60)  NOT NULL,
  payload_json      JSON         NULL,
  related_entity    VARCHAR(40)  NULL,
  related_id        BIGINT UNSIGNED NULL,
  status            VARCHAR(20)  NOT NULL DEFAULT 'Queued' COMMENT 'Queued|Sent|Failed|Read',
  sent_at           DATETIME     NULL,
  created_at        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_notif_user (recipient_user_id, status),
  CONSTRAINT fk_notif_user FOREIGN KEY (recipient_user_id) REFERENCES user_accounts(id)
) ENGINE=InnoDB;

CREATE TABLE letter_templates (
  id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  code        VARCHAR(60)  NOT NULL UNIQUE,
  name        VARCHAR(120) NOT NULL,
  subject     VARCHAR(200) NULL,
  body_html   TEXT         NOT NULL COMMENT 'merge fields e.g. {{employee.full_name}}',
  is_active   BOOLEAN      NOT NULL DEFAULT TRUE,
  created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE generated_letters (
  id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  employee_id   BIGINT UNSIGNED NOT NULL,
  template_id   BIGINT UNSIGNED NOT NULL,
  file_path     VARCHAR(500) NOT NULL,
  merge_data    JSON         NULL,
  generated_by  BIGINT UNSIGNED NULL,
  generated_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_gl_employee (employee_id),
  CONSTRAINT fk_gl_employee FOREIGN KEY (employee_id)  REFERENCES employees(id),
  CONSTRAINT fk_gl_template FOREIGN KEY (template_id)  REFERENCES letter_templates(id)
) ENGINE=InnoDB;

CREATE TABLE audit_logs (
  id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  actor_user_id BIGINT UNSIGNED NULL,
  actor_role    VARCHAR(40)  NULL,
  action        VARCHAR(30)  NOT NULL COMMENT 'CREATE|UPDATE|VIEW_SENSITIVE|APPROVE|REJECT|EXPORT|DELETE|LOGIN',
  table_name    VARCHAR(60)  NOT NULL,
  record_id     BIGINT UNSIGNED NULL,
  employee_id   BIGINT UNSIGNED NULL COMMENT 'subject employee, for fast per-person history',
  before_json   JSON         NULL,
  after_json    JSON         NULL,
  ip_address    VARCHAR(45)  NULL,
  user_agent    VARCHAR(255) NULL,
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_audit_actor (actor_user_id),
  KEY idx_audit_record (table_name, record_id),
  KEY idx_audit_employee (employee_id),
  KEY idx_audit_created (created_at)
) ENGINE=InnoDB COMMENT='Append-only audit trail â€” do not grant UPDATE/DELETE to application user';

-- =============================================================================
-- 7. USEFUL VIEWS
-- =============================================================================

CREATE VIEW v_staff_directory AS
SELECT e.id, e.employee_no, e.full_name, e.email, e.phone,
       e.employment_status, e.employment_type, e.hire_date, e.confirmation_date,
       p.title AS position_title, d.name AS department_name, b.name AS branch_name,
       c.name AS company_name, m.full_name AS manager_name,
       TIMESTAMPDIFF(YEAR, e.hire_date, CURDATE()) AS years_of_service
FROM employees e
LEFT JOIN positions p   ON p.id = e.position_id
LEFT JOIN departments d ON d.id = e.department_id
LEFT JOIN branches b    ON b.id = e.branch_id
LEFT JOIN companies c   ON c.id = e.company_id
LEFT JOIN employees m   ON m.id = e.reports_to_employee_id
WHERE e.deleted_at IS NULL;

CREATE VIEW v_expiring_documents AS
SELECT d.id AS document_id, e.id AS employee_id, e.employee_no, e.full_name,
       d.document_type, d.title, d.expiry_date,
       DATEDIFF(d.expiry_date, CURDATE()) AS days_remaining
FROM employee_documents d
JOIN employees e ON e.id = d.employee_id
WHERE d.expiry_date IS NOT NULL
  AND d.expiry_date <= DATE_ADD(CURDATE(), INTERVAL 60 DAY)
  AND e.deleted_at IS NULL;

CREATE VIEW v_pending_change_requests AS
SELECT cr.id, cr.request_no, e.full_name AS employee_name, cr.field_group,
       cr.status, cr.current_approver_role, cr.submitted_at, u.username AS requested_by
FROM change_requests cr
JOIN employees e ON e.id = cr.employee_id
JOIN user_accounts u ON u.id = cr.requested_by
WHERE cr.status = 'Pending';

-- =============================================================================
-- 8. TRIGGERS â€” PROTECT AUDIT INTEGRITY
-- =============================================================================

DELIMITER $$

CREATE TRIGGER trg_audit_no_update BEFORE UPDATE ON audit_logs
FOR EACH ROW BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'audit_logs is append-only: UPDATE denied';
END$$

CREATE TRIGGER trg_audit_no_delete BEFORE DELETE ON audit_logs
FOR EACH ROW BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'audit_logs is append-only: DELETE denied';
END$$

-- Automatically append a history event when employment status changes.
CREATE TRIGGER trg_employee_status_history
AFTER UPDATE ON employees
FOR EACH ROW BEGIN
  IF NEW.employment_status <> OLD.employment_status THEN
    INSERT INTO employment_history
      (employee_id, event_type, effective_date, from_position_id, to_position_id,
       from_department_id, to_department_id, from_salary, to_salary,
       from_manager_id, to_manager_id, change_reason, created_by)
    VALUES
      (NEW.id, CONCAT('STATUS_', NEW.employment_status), CURDATE(),
       OLD.position_id, NEW.position_id, OLD.department_id, NEW.department_id,
       OLD.basic_salary, NEW.basic_salary, OLD.reports_to_employee_id,
       NEW.reports_to_employee_id, CONCAT('Status changed from ', OLD.employment_status,
       ' to ', NEW.employment_status), NEW.updated_by);
  END IF;
END$$

DELIMITER ;

-- =============================================================================
-- END OF SCHEMA
-- =============================================================================
