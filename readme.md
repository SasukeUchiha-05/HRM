# Enterprise Human Resource Management (HRM) Portal

![Python Version](https://img.shields.io/badge/python-3.13+-blue.svg)
![Flask Version](https://img.shields.io/badge/flask-3.1.3-lightgrey.svg)
![MySQL](https://img.shields.io/badge/MySQL-8.0+-orange.svg)
![License](https://img.shields.io/badge/license-Proprietary-red.svg)

## Executive Summary
The Enterprise HRM Portal is a lightweight, high-performance web application designed to streamline Human Resources operations. Built on a robust Python/Flask micro-architecture and backed by a strictly normalized MySQL 8.0 relational database, this system provides real-time visibility into employee data, attendance tracking, and automated onboarding workflows.

## Core Features
* **Centralized HR Dashboard:** Real-time monitoring of employee statuses and daily attendance logs.
* **Self-Service Employee Onboarding:** Automated registration portal handling strict database constraints and UUID generation.
* **Referential Integrity Management:** Deeply normalized database schema enforcing strict department, designation, and employee relationships.
* **Modern Security Standards:** Support for MySQL `caching_sha2_password` authentication and enterprise password validation policies.

## Architecture & Technology Stack
* **Backend Framework:** Python 3.13, Flask 3.1
* **ORM Layer:** Flask-SQLAlchemy 3.1
* **Database Engine:** MySQL 8.0+ (via PyMySQL + Cryptography)
* **Frontend UI:** HTML5, Jinja2 Templating, Bootstrap 5.3 (CDN)

---

## Prerequisites
Ensure the following dependencies are installed on your host infrastructure before proceeding:
1.  **Python 3.13** or higher.
2.  **MySQL Server 8.0** or higher (with administrative access).
3.  **Git** (for version control).

---

## Installation & Environment Setup

### 1. Clone the Repository
```bash
git clone <repository_url>
cd hrm_app
```

### 2. Provision the Virtual Environment
To comply with PEP 668 and prevent OS-level package conflicts, the application must be run inside an isolated virtual environment.
```bash
python3 -m venv .venv
source .venv/bin/activate  # On Linux/macOS
# .venv\Scripts\activate   # On Windows
```

### 3. Install Dependencies
```bash
pip install flask flask-sqlalchemy pymysql cryptography
```

### 4. Database Initialization
1. Log into your MySQL instance: `mysql -u root -p`
2. Execute the provided Data Definition Language (DDL) script to build the schema:
```sql
CREATE DATABASE hrm_db;
USE hrm_db;
SOURCE /path/to/your/schema.sql;
```

### 5. Application Configuration
Locate the database configuration string in `app.py`. Update the connection URI with your secure database credentials:
```python
# app.py
app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql+pymysql://<username>:<secure_password>@localhost/hrm_db'
```

---

## Running the Application

Execute the following command to start the WSGI server:
```bash
python app.py
```
The application will boot and bind to `http://127.0.0.1:5000`.

### Navigation
* **HR Dashboard:** `http://127.0.0.1:5000/` (Admin view of employees and attendance).
* **Employee Onboarding:** `http://127.0.0.1:5000/login` (Self-service registration portal).

---

## Project Structure
```text
hrm_app/
├── app.py                  # Main application factory and route definitions
├── templates/              # Jinja2 HTML templates
│   ├── dashboard.html      # HR Admin dashboard UI
│   └── login.html          # Employee registration interface
├── schema.sql              # MySQL DDL for database provisioning
└── README.md               # Application documentation
```

## Security & Compliance Notes
* **Password Policies:** The database relies on MySQL's `validate_password` component. Service account passwords must meet enterprise complexity requirements (mixed case, numbers, special characters, length >= 8).
* **Cryptography:** The `cryptography` Python package is mandatory for secure handshake operations with MySQL 8.0's default SHA256 caching.
* **Data Integrity:** Do not bypass foreign key checks (`SET FOREIGN_KEY_CHECKS = 0;`) outside of initial schema generation. The application logic relies on these constraints to prevent orphaned records.