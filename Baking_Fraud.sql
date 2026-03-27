CREATE DATABASE BankingDB;
GO

USE BankingDB;

CREATE TABLE Customers (
    customer_id INT PRIMARY KEY,
    name VARCHAR(100),
    city VARCHAR(50),
    account_type VARCHAR(20)
);

CREATE TABLE Transactions (
    transaction_id INT PRIMARY KEY,
    customer_id INT,
    amount DECIMAL(10,2),
    transaction_type VARCHAR(10),
    date_time DATETIME,
    location VARCHAR(50),

    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
);

CREATE TABLE FraudFlags (
    transaction_id INT,
    fraud_flag BIT,
    reason VARCHAR(255),

    FOREIGN KEY (transaction_id) REFERENCES Transactions(transaction_id)
);

INSERT INTO Customers VALUES
(1, 'Rahul', 'Mumbai', 'Savings'),
(2, 'Amit', 'Delhi', 'Current'),
(3, 'Priya', 'Pune', 'Savings');

INSERT INTO Transactions VALUES
(101, 1, 5000, 'debit', '2024-01-01 10:00:00', 'Mumbai'),
(102, 1, 70000, 'debit', '2024-01-01 10:05:00', 'Delhi'),
(103, 2, 2000, 'credit', '2024-01-02 12:00:00', 'Delhi'),
(104, 3, 90000, 'debit', '2024-01-03 14:00:00', 'Pune');

SELECT * FROM Transactions;

SELECT 
  customer_id,
  amount,
  LAG(amount) OVER (PARTITION BY customer_id ORDER BY date_time) AS prev_amount
FROM Transactions;

SELECT *,
CASE 
    WHEN amount > 50000 THEN 'High Risk'
    ELSE 'Normal'
END AS risk_level
FROM Transactions;

CREATE VIEW vw_TransactionSummary AS
SELECT 
    t.transaction_id,
    c.name,
    t.amount,
    t.transaction_type,
    t.date_time,
    t.location
FROM Transactions t
JOIN Customers c 
ON t.customer_id = c.customer_id;


CREATE PROCEDURE GetHighValueTransactions
AS
BEGIN
    SELECT *
    FROM Transactions
    WHERE amount > 50000;
END;

EXEC GetHighValueTransactions;


SELECT * FROM FraudFlags;


-- STEP 1: Date series (2024 to 2026 March 31)
WITH DateSeries AS (
    SELECT CAST('2024-01-01' AS DATETIME) AS date_time
    UNION ALL
    SELECT DATEADD(HOUR, 4, date_time)
    FROM DateSeries
    WHERE date_time < '2026-03-31 23:59:59'
)
SELECT * INTO TempDates
FROM DateSeries
OPTION (MAXRECURSION 0);


-- STEP 2: Insert ~20000 rows
INSERT INTO Transactions (transaction_id, customer_id, amount, transaction_type, date_time, location)
SELECT 
    ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) + 104 AS transaction_id,
    
    -- Random customer
    FLOOR(RAND(CHECKSUM(NEWID())) * 3) + 1,
    
    -- Random amount
    FLOOR(RAND(CHECKSUM(NEWID())) * 99000) + 1000,
    
    -- Random type
    CASE 
        WHEN RAND(CHECKSUM(NEWID())) > 0.5 THEN 'debit'
        ELSE 'credit'
    END,
    
    date_time,
    
    -- Random city
    CASE 
        WHEN RAND(CHECKSUM(NEWID())) < 0.33 THEN 'Mumbai'
        WHEN RAND(CHECKSUM(NEWID())) < 0.66 THEN 'Delhi'
        ELSE 'Pune'
    END

FROM TempDates;

DROP TABLE TempDates;

SELECT COUNT(*) FROM Transactions;

SELECT COUNT(*) FROM FraudFlags;


INSERT INTO Customers (customer_id, name, city, account_type)
SELECT 
    ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) + 3,
    
    CONCAT('Customer_', ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) + 3),
    
    CASE 
        WHEN RAND(CHECKSUM(NEWID())) < 0.33 THEN 'Mumbai'
        WHEN RAND(CHECKSUM(NEWID())) < 0.66 THEN 'Delhi'
        ELSE 'Pune'
    END,
    
    CASE 
        WHEN RAND(CHECKSUM(NEWID())) < 0.5 THEN 'Savings'
        ELSE 'Current'
    END
FROM sys.objects;