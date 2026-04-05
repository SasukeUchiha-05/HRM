-- This will only insert if 'Engineering' doesn't exist
INSERT IGNORE INTO departments (name, description) 
VALUES ('Engineering', 'Software Development Team');


-- This creates the 'Senior Developer' role inside 'Engineering'
INSERT INTO designations (title, department_id, level) 
SELECT 'Senior Developer', id, 3 
FROM departments 
WHERE name = 'Engineering' 
LIMIT 1;


-- This creates the 'Senior Developer' role inside 'Engineering'
INSERT INTO designations (title, department_id, level) 
SELECT 'Senior Developer', id, 3 
FROM departments 
WHERE name = 'Engineering' 
LIMIT 1;



INSERT INTO employees (
    employee_code, first_name, last_name, date_of_birth, 
    gender, aadhaar_number, pan_number, department_id, 
    designation_id, date_of_joining, status
)
SELECT 
    'EMP001', 'John', 'Doe', '1990-01-01', 
    'male', '123456789012', 'ABCDE1234F', 
    (SELECT id FROM departments WHERE name = 'Engineering' LIMIT 1), 
    (SELECT id FROM designations WHERE title = 'Senior Developer' LIMIT 1), 
    CURDATE(), 'active';

SELECT e.first_name, d.name as department, des.title as designation
FROM employees e
JOIN departments d ON e.department_id = d.id
JOIN designations des ON e.designation_id = des.id;