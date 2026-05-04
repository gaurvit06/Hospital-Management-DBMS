# Hospital Management & Medical Record System

## 🏥 Project Overview
This is a database-driven application designed to manage hospital operations such as patient registration, doctor management, appointment scheduling, treatment records, and automated billing. It is normalized up to 3NF/BCNF.

## 💻 Tech Stack
* **Database:** Oracle Database (Oracle Live SQL)
* **Language:** SQL, PL/SQL

## ✨ Key Features
* **Automated Billing:** PL/SQL triggers automatically generate a bill when a treatment is logged.
* **Payment Processing:** Secure procedures ensure transactions maintain ACID properties.
* **Concurrency Control:** Functions check doctor availability to prevent double-booking appointments.
* **Reporting:** Uses Cursors to generate complete patient medical histories.

## 📂 Project Structure
* `hospital_schema.sql`: Contains DDL commands to create tables and constraints.
* `hospital_logic.sql`: Contains PL/SQL triggers, functions, and procedures.
* `hospital_queries.sql`: Contains advanced SELECT queries, Views, and joins.

## 📊 Entity-Relationship Diagram
<img width="745" height="1651" alt="DBMS_PROJECT_ER_DIAGRAM" src="https://github.com/user-attachments/assets/98ee9119-989c-44a5-8775-4970d9dc7856" />
