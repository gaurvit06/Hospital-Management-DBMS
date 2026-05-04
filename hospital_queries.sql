CREATE OR REPLACE VIEW VW_PATIENT_MEDICAL_HISTORY AS
SELECT 
    p.Patient_ID, 
    p.Name AS Patient_Name, 
    a.App_Date, 
    d.Name AS Doctor_Name, 
    t.Diagnosis, 
    t.Treatment_Desc, 
    b.Total_Amount, 
    b.Status AS Bill_Status
FROM PATIENT p
JOIN APPOINTMENT a ON p.Patient_ID = a.Patient_ID
JOIN DOCTOR d ON a.Doctor_ID = d.Doctor_ID
LEFT JOIN TREATMENT t ON a.App_ID = t.App_ID
LEFT JOIN BILL b ON t.Treatment_ID = b.Treatment_ID;

SELECT * FROM VW_PATIENT_MEDICAL_HISTORY;

SELECT 
    p.Name AS Patient, 
    d.Name AS Doctor, 
    a.App_Date, 
    a.Status
FROM PATIENT p
JOIN APPOINTMENT a ON p.Patient_ID = a.Patient_ID
JOIN DOCTOR d ON a.Doctor_ID = d.Doctor_ID;


SELECT 
    d.Name, 
    d.Specialization, 
    COUNT(a.App_ID) AS Total_Appointments
FROM DOCTOR d
JOIN APPOINTMENT a ON d.Doctor_ID = a.Doctor_ID
GROUP BY d.Name, d.Specialization
HAVING COUNT(a.App_ID) = (
    SELECT MAX(app_count) 
    FROM (SELECT COUNT(App_ID) AS app_count FROM APPOINTMENT GROUP BY Doctor_ID)
);


SELECT 
    TO_CHAR(Payment_Date, 'YYYY-MM') AS Month, 
    SUM(Amount_Paid) AS Total_Monthly_Revenue
FROM PAYMENT
GROUP BY TO_CHAR(Payment_Date, 'YYYY-MM');