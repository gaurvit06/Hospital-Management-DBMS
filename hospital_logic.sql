CREATE OR REPLACE FUNCTION CHECK_DOCTOR_AVAILABILITY (
    p_doctor_id INT, 
    p_app_date TIMESTAMP
) 
RETURN BOOLEAN 
IS
    v_count INT;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM APPOINTMENT
    WHERE Doctor_ID = p_doctor_id 
      AND App_Date = p_app_date 
      AND Status != 'Cancelled';
      
    IF v_count > 0 THEN
        RETURN FALSE; -- Doctor is busy
    ELSE
        RETURN TRUE;  -- Doctor is available
    END IF;
END;
/

CREATE OR REPLACE TRIGGER TRG_PREVENT_DOUBLE_BOOKING
BEFORE INSERT ON APPOINTMENT
FOR EACH ROW
DECLARE
    v_is_available BOOLEAN;
BEGIN
    v_is_available := CHECK_DOCTOR_AVAILABILITY(:NEW.Doctor_ID, :NEW.App_Date);
    
    IF NOT v_is_available THEN
        RAISE_APPLICATION_ERROR(-20001, 'Appointment Conflict: Doctor is already booked at this time.');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER TRG_AUTO_GENERATE_BILL
AFTER INSERT ON TREATMENT
FOR EACH ROW
BEGIN
    INSERT INTO BILL (Bill_ID, Treatment_ID, Total_Amount, Status)
    VALUES (
        -- Assuming a sequence or simple concatenation for Bill ID generation in this example
        :NEW.Treatment_ID * 100, 
        :NEW.Treatment_ID, 
        :NEW.Cost, 
        'Unpaid'
    );
END;
/

CREATE OR REPLACE TRIGGER TRG_UPDATE_PAYMENT_STATUS
AFTER INSERT ON PAYMENT
FOR EACH ROW
DECLARE
    v_total_bill DECIMAL(10,2);
    v_total_paid DECIMAL(10,2);
BEGIN
       SELECT Total_Amount INTO v_total_bill FROM BILL WHERE Bill_ID = :NEW.Bill_ID;
    
       SELECT NVL(SUM(Amount_Paid), 0) INTO v_total_paid FROM PAYMENT WHERE Bill_ID = :NEW.Bill_ID;
    
    
    IF v_total_paid >= v_total_bill THEN
        UPDATE BILL SET Status = 'Paid' WHERE Bill_ID = :NEW.Bill_ID;
    ELSE
        UPDATE BILL SET Status = 'Partial' WHERE Bill_ID = :NEW.Bill_ID;
    END IF;
END;
/

CREATE OR REPLACE PROCEDURE PROCESS_PAYMENT (
    p_payment_id INT,
    p_bill_id INT,
    p_amount DECIMAL,
    p_mode VARCHAR2
)
IS
    v_bill_status VARCHAR2(20);
BEGIN
       SAVEPOINT start_payment;

       SELECT Status INTO v_bill_status FROM BILL WHERE Bill_ID = p_bill_id FOR UPDATE;
    
    IF v_bill_status = 'Paid' THEN
        RAISE_APPLICATION_ERROR(-20002, 'Invalid Payment: This bill is already fully paid.');
    END IF;

        INSERT INTO PAYMENT (Payment_ID, Bill_ID, Amount_Paid, Mode_Of_Payment)
    VALUES (p_payment_id, p_bill_id, p_amount, p_mode);

       COMMIT;
    DBMS_OUTPUT.PUT_LINE('Payment processed successfully.');

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK TO start_payment;
        DBMS_OUTPUT.PUT_LINE('Error: Bill ID does not exist.');
    WHEN OTHERS THEN
        ROLLBACK TO start_payment;
        DBMS_OUTPUT.PUT_LINE('Transaction Failed. Error: ' || SQLERRM);
END;
/

CREATE OR REPLACE PROCEDURE GENERATE_PATIENT_HISTORY(p_patient_id INT)
IS
    
    CURSOR history_cursor IS
        SELECT a.App_Date, d.Name AS Doctor_Name, t.Diagnosis, t.Treatment_Desc, b.Status AS Bill_Status
        FROM APPOINTMENT a
        JOIN DOCTOR d ON a.Doctor_ID = d.Doctor_ID
        LEFT JOIN TREATMENT t ON a.App_ID = t.App_ID
        LEFT JOIN BILL b ON t.Treatment_ID = b.Treatment_ID
        WHERE a.Patient_ID = p_patient_id
        ORDER BY a.App_Date DESC;
        
    v_patient_name PATIENT.Name%TYPE;
BEGIN
        SELECT Name INTO v_patient_name FROM PATIENT WHERE Patient_ID = p_patient_id;
    
    DBMS_OUTPUT.PUT_LINE('==================================================');
    DBMS_OUTPUT.PUT_LINE('MEDICAL HISTORY FOR: ' || v_patient_name);
    DBMS_OUTPUT.PUT_LINE('==================================================');
    
       FOR rec IN history_cursor LOOP
        DBMS_OUTPUT.PUT_LINE('Date: ' || TO_CHAR(rec.App_Date, 'YYYY-MM-DD HH24:MI'));
        DBMS_OUTPUT.PUT_LINE('Doctor: Dr. ' || rec.Doctor_Name);
        DBMS_OUTPUT.PUT_LINE('Diagnosis: ' || NVL(rec.Diagnosis, 'Pending'));
        DBMS_OUTPUT.PUT_LINE('Treatment: ' || NVL(rec.Treatment_Desc, 'Pending'));
        DBMS_OUTPUT.PUT_LINE('Bill Status: ' || NVL(rec.Bill_Status, 'N/A'));
        DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
    END LOOP;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Error: Patient ID not found.');
END;
/

SET SERVEROUTPUT ON;

INSERT INTO DEPARTMENT (Dept_ID, Dept_Name) 
VALUES (1, 'Cardiology');


INSERT INTO DOCTOR (Doctor_ID, Name, Specialization, Dept_ID) 
VALUES (101, 'Dr. Sarah Jenkins', 'Cardiologist', 1);

INSERT INTO PATIENT (Patient_ID, Name, DOB, Gender, Phone, Address) 
VALUES (501, 'Alex Carter', TO_DATE('1990-05-15', 'YYYY-MM-DD'), 'Male', '555-0198', '123 Maple Street');

COMMIT;
SET SERVEROUTPUT ON;

INSERT INTO APPOINTMENT (App_ID, Patient_ID, Doctor_ID, App_Date, Status) 
VALUES (1001, 501, 101, SYSTIMESTAMP + 1, 'Scheduled');

INSERT INTO TREATMENT (Treatment_ID, App_ID, Diagnosis, Treatment_Desc, Cost) 
VALUES (2001, 1001, 'Mild Hypertension', 'Prescribed blood pressure medication', 150.00);

SELECT * FROM BILL WHERE Treatment_ID = 2001;
SET SERVEROUTPUT ON;

EXEC PROCESS_PAYMENT(3001, 200100, 150.00, 'Credit Card');

SELECT Bill_ID, Total_Amount, Status FROM BILL WHERE Bill_ID = 200100;

EXEC GENERATE_PATIENT_HISTORY(501);