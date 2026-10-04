CREATE TABLE Departments (
    department  VARCHAR(50) PRIMARY KEY,
    manager     INT NULL
);

CREATE TABLE Employees (
    emp_id      INT PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    Department  VARCHAR(50),
    Salary      DECIMAL(10,2) CHECK (Salary >= 0),
    FOREIGN KEY (Department) REFERENCES Departments(department)
);

CREATE TABLE Projects (
    project_id    INT PRIMARY KEY,
    project_name  VARCHAR(100) NOT NULL,
    start_date    DATE,
    end_date      DATE,
    CHECK (end_date IS NULL OR end_date >= start_date)
);

CREATE TABLE Assignments (
    empid         INT,
    projectid     INT,
    roles         VARCHAR(50),
    hours_worked  INT DEFAULT 0 CHECK (hours_worked >= 0),
    PRIMARY KEY (empid, projectid),
    FOREIGN KEY (empid)     REFERENCES Employees(emp_id),
    FOREIGN KEY (projectid) REFERENCES Projects(project_id)
);

-- Add the circular foreign key after both tables exist
ALTER TABLE Departments
ADD CONSTRAINT fk_dept_manager
FOREIGN KEY (manager) REFERENCES Employees(emp_id);

---------------------------------------------------------------------------------------------------------------------------------------------


1. Employees with their project names and roles

sql
SELECT e.emp_id, e.name, p.project_name, a.roles
FROM Employees e
JOIN Assignments a ON e.emp_id = a.empid
JOIN Projects p ON a.projectid = p.project_id;
---------------------------------------------------------------------------------------------------------------------------------------------

2. View: department-wise total hours worked

sql
CREATE VIEW dept_total_hours AS
SELECT e.Department, SUM(a.hours_worked) AS total_hours
FROM Employees e
JOIN Assignments a ON e.emp_id = a.empid
GROUP BY e.Department;
---------------------------------------------------------------------------------------------------------------------------------------------

3. Employees working on more than 2 projects

sql
SELECT e.emp_id, e.name, COUNT(DISTINCT a.projectid) AS project_count
FROM Employees e
JOIN Assignments a ON e.emp_id = a.empid
GROUP BY e.emp_id, e.name
HAVING COUNT(DISTINCT a.projectid) > 2;
---------------------------------------------------------------------------------------------------------------------------------------------

4. Projects not assigned to any employee

sql
SELECT p.project_id, p.project_name
FROM Projects p
LEFT JOIN Assignments a ON p.project_id = a.projectid
WHERE a.projectid IS NULL;
---------------------------------------------------------------------------------------------------------------------------------------------

5. Average hours worked by employees per department
Total hours per employee first, then averaged across the department:

sql
SELECT Department, AVG(emp_hours) AS avg_hours_per_employee
FROM (
    SELECT e.emp_id, e.Department, SUM(a.hours_worked) AS emp_hours
    FROM Employees e
    JOIN Assignments a ON e.emp_id = a.empid
    GROUP BY e.emp_id, e.Department
) t
GROUP BY Department;
---------------------------------------------------------------------------------------------------------------------------------------------

6. Departments whose employees work on projects that started in 2023

sql
SELECT DISTINCT e.Department
FROM Employees e
JOIN Assignments a ON e.emp_id = a.empid
JOIN Projects p ON a.projectid = p.project_id
WHERE p.start_date >= '2023-01-01' AND p.start_date < '2024-01-01';
---------------------------------------------------------------------------------------------------------------------------------------------

7. Employee(s) with the most hours on a single project

sql
SELECT e.emp_id, e.name, a.projectid, a.hours_worked
FROM Employees e
JOIN Assignments a ON e.emp_id = a.empid
WHERE a.hours_worked = (SELECT MAX(hours_worked) FROM Assignments);
---------------------------------------------------------------------------------------------------------------------------------------------

8. View: each employee's total hours and salary

sql
CREATE VIEW emp_hours_salary AS
SELECT e.emp_id, e.name, e.Salary,
       COALESCE(SUM(a.hours_worked), 0) AS total_hours
FROM Employees e
LEFT JOIN Assignments a ON e.emp_id = a.empid
GROUP BY e.emp_id, e.name, e.Salary;
---------------------------------------------------------------------------------------------------------------------------------------------

9. Employees earning above their department's average

sql
SELECT e.emp_id, e.name, e.Department, e.Salary
FROM Employees e
WHERE e.Salary > (
    SELECT AVG(Salary)
    FROM Employees
    WHERE Department = e.Department
);
---------------------------------------------------------------------------------------------------------------------------------------------

10. Projects handled by employees from more than one department

sql
SELECT p.project_id, p.project_name
FROM Projects p
JOIN Assignments a ON p.project_id = a.projectid
JOIN Employees e ON a.empid = e.emp_id
GROUP BY p.project_id, p.project_name
HAVING COUNT(DISTINCT e.Department) > 1;
---------------------------------------------------------------------------------------------------------------------------------------------

11. Employees not assigned to any project

sql
SELECT e.emp_id, e.name
FROM Employees e
LEFT JOIN Assignments a ON e.emp_id = a.empid
WHERE a.empid IS NULL;
---------------------------------------------------------------------------------------------------------------------------------------------

12. Projects involving employees from more than 3 departments

sql
SELECT p.project_id, p.project_name, COUNT(DISTINCT e.Department) AS dept_count
FROM Projects p
JOIN Assignments a ON p.project_id = a.projectid
JOIN Employees e ON a.empid = e.emp_id
GROUP BY p.project_id, p.project_name
HAVING COUNT(DISTINCT e.Department) > 3;
---------------------------------------------------------------------------------------------------------------------------------------------

13. Average salary of employees on each project

sql
SELECT p.project_id, p.project_name, AVG(e.Salary) AS avg_salary
FROM Projects p
JOIN Assignments a ON p.project_id = a.projectid
JOIN Employees e ON a.empid = e.emp_id
GROUP BY p.project_id, p.project_name;
---------------------------------------------------------------------------------------------------------------------------------------------

14. View: projects ending this quarter with assigned employee count

sql
CREATE VIEW projects_ending_this_quarter AS
SELECT p.project_id, p.project_name, p.end_date,
       COUNT(DISTINCT a.empid) AS employee_count
FROM Projects p
LEFT JOIN Assignments a ON p.project_id = a.projectid
WHERE YEAR(p.end_date) = YEAR(CURDATE())
  AND QUARTER(p.end_date) = QUARTER(CURDATE())
GROUP BY p.project_id, p.project_name, p.end_date;

For PostgreSQL, replace the WHERE clause with:
p.end_date >= DATE_TRUNC('quarter', CURRENT_DATE) AND p.end_date < DATE_TRUNC('quarter', CURRENT_DATE) + INTERVAL '3 months'
---------------------------------------------------------------------------------------------------------------------------------------------

15. Departments with no ongoing project involvement
"Ongoing" is taken as started on or before today and not yet ended (or no end date).

sql
SELECT d.department
FROM Departments d
WHERE NOT EXISTS (
    SELECT 1
    FROM Employees e
    JOIN Assignments a ON e.emp_id = a.empid
    JOIN Projects p ON a.projectid = p.project_id
    WHERE e.Department = d.department
      AND p.start_date <= CURDATE()
      AND (p.end_date IS NULL OR p.end_date >= CURDATE())
);


