from flask import Flask, render_template, request, redirect, url_for
from flask_sqlalchemy import SQLAlchemy
from datetime import date
import uuid
import random
import string

app = Flask(__name__)

# --- CONFIGURATION ---
app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql+pymysql://root:Karthik_05_69_420_!!@localhost/dev_db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

# --- MODELS ---
class Employee(db.Model):
    __tablename__ = 'employees'
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    employee_code = db.Column(db.String(20), unique=True, nullable=False)
    first_name = db.Column(db.String(60), nullable=False)
    last_name = db.Column(db.String(60), nullable=False)
    status = db.Column(db.String(20), default='active')

class Attendance(db.Model):
    __tablename__ = 'attendance'
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    employee_id = db.Column(db.String(36), db.ForeignKey('employees.id'), nullable=False)
    attendance_date = db.Column(db.Date, nullable=False)
    punch_in_time = db.Column(db.Time)
    status = db.Column(db.String(20))
    employee = db.relationship('Employee', backref='attendances')

# --- ROUTES ---

@app.route('/')
def hr_dashboard():
    try:
        employees = Employee.query.order_by(Employee.employee_code.desc()).limit(10).all()
        attendance_logs = Attendance.query.order_by(Attendance.attendance_date.desc()).limit(10).all()
        
        return render_template('dashboard.html', 
                               employees=employees, 
                               attendance=attendance_logs, 
                               today=date.today())
    except Exception as e:
        return f"<h1>Connection Error</h1><p>{str(e)}</p>"

# ---> NEW ROUTE FOR EMPLOYEE LOGIN / ONBOARDING <---
@app.route('/login', methods=['GET', 'POST']) # register path
def employee_login():
    if request.method == 'POST':
        # 1. Grab the text data from the frontend form
        emp_code = request.form.get('employee_code')
        fname = request.form.get('first_name')
        lname = request.form.get('last_name')

        # 2. Fetch the first available department and designation to satisfy Foreign Keys
        dept_id = db.session.execute(db.text("SELECT id FROM departments LIMIT 1")).scalar()
        desig_id = db.session.execute(db.text("SELECT id FROM designations LIMIT 1")).scalar()

        # 3. Generate random fake Aadhaar and PAN so MySQL UNIQUE constraints don't block us
        fake_aadhaar = str(random.randint(100000000000, 999999999999))
        fake_pan = ''.join(random.choices(string.ascii_uppercase, k=5)) + str(random.randint(1000, 9999)) + random.choice(string.ascii_uppercase)

        # 4. Insert into the DB using raw SQL to handle all the strict NOT NULL fields easily
        insert_query = db.text("""
            INSERT INTO employees 
            (id, employee_code, first_name, last_name, date_of_birth, gender, 
             aadhaar_number, pan_number, department_id, designation_id, date_of_joining, status) 
            VALUES 
            (UUID(), :code, :fname, :lname, '1990-01-01', 'other', 
             :aadhaar, :pan, :dept, :desig, CURDATE(), 'active')
        """)
        
        try:
            db.session.execute(insert_query, {
                'code': emp_code, 'fname': fname, 'lname': lname, 
                'aadhaar': fake_aadhaar, 'pan': fake_pan, 
                'dept': dept_id, 'desig': desig_id
            })
            db.session.commit()
            
            # Redirect the user to the HR dashboard so you can immediately see the new entry
            return redirect(url_for('hr_dashboard'))
        except Exception as e:
            db.session.rollback()
            return f"Error adding employee: {str(e)}"

    # If it's a GET request, just show the form
    return render_template('login.html')


# login
# credentials: user:abcd, pass defg.
# sql Query: select emp_id from employees where username = abcd.
# true -> user exists! password check. -> true, login allow.

# check if user exists, then check pass, then allow login. face, biometric.
if __name__ == '__main__':
    print("🚀 HRM System starting on http://127.0.0.1:5000")
    app.run(debug=True)