-- EXPERIMENT – 7
-- AIM: To identify functional dependencies and normalize a Sales relation from UNF
-- to 1NF, 2NF, 3NF and BCNF, and verify lossless join and dependency preservation.

-- SOURCE CODE

-- 1. CREATE DATABASE
CREATE DATABASE RetailNormalization;
USE RetailNormalization;


-- 2. CREATE THE DENORMALIZED SALES TABLE (UNF)
CREATE TABLE Purchase_UNF (
    Order_ID INT,
    Order_Date DATE,
    Customer_ID VARCHAR(10),
    Customer_Name VARCHAR(50),
    Product_ID VARCHAR(10),
    Product_Name VARCHAR(50),
    Quantity INT,
    Unit_Price DECIMAL(10,2),
    Salesperson_ID VARCHAR(10),
    Salesperson_Name VARCHAR(50)
);

INSERT INTO Purchase_UNF VALUES
(2001, '2026-02-05', 'C11', 'Kabir', 'P11', 'Tablet', 2, 32000, 'S11', 'Ananya'),
(2001, '2026-02-05', 'C11', 'Kabir', 'P12', 'Headphones', 3, 1800, 'S11', 'Ananya'),
(2002, '2026-02-08', 'C12', 'Ishita', 'P11', 'Tablet', 1, 32000, 'S12', 'Vikram'),
(2003, '2026-02-12', 'C13', 'Dev', 'P13', 'Printer', 2, 12500, 'S11', 'Ananya'),
(2004, '2026-02-16', 'C11', 'Kabir', 'P13', 'Printer', 1, 12500, 'S12', 'Vikram'),
(2005, '2026-02-20', 'C14', 'Naina', 'P12', 'Headphones', 4, 1800, 'S13', 'Arjun');

SELECT * FROM Purchase_UNF;


-- 3. FUNCTIONAL DEPENDENCIES
-- Order_ID -> Order_Date, Customer_ID, Salesperson_ID
-- Customer_ID -> Customer_Name
-- Product_ID -> Product_Name, Unit_Price
-- Salesperson_ID -> Salesperson_Name
-- (Order_ID, Product_ID) -> Quantity
-- Candidate Key: (Order_ID, Product_ID)


-- 4. FIRST NORMAL FORM (1NF)
CREATE TABLE Purchase_1NF (
    Order_ID INT,
    Order_Date DATE,
    Customer_ID VARCHAR(10),
    Customer_Name VARCHAR(50),
    Product_ID VARCHAR(10),
    Product_Name VARCHAR(50),
    Quantity INT,
    Unit_Price DECIMAL(10,2),
    Salesperson_ID VARCHAR(10),
    Salesperson_Name VARCHAR(50),
    PRIMARY KEY (Order_ID, Product_ID)
);

INSERT INTO Purchase_1NF
SELECT * FROM Purchase_UNF;

SELECT * FROM Purchase_1NF;


-- 5. SECOND NORMAL FORM (2NF)
-- Partial dependencies:
-- Order_ID -> Order_Date, Customer_ID, Customer_Name, Salesperson_ID, Salesperson_Name
-- Product_ID -> Product_Name, Unit_Price

-- Table 1: Orders
CREATE TABLE Orders (
    Order_ID INT PRIMARY KEY,
    Order_Date DATE,
    Customer_ID VARCHAR(10),
    Customer_Name VARCHAR(50),
    Salesperson_ID VARCHAR(10),
    Salesperson_Name VARCHAR(50)
);

INSERT INTO Orders
SELECT DISTINCT
    Order_ID, Order_Date, Customer_ID, Customer_Name,
    Salesperson_ID, Salesperson_Name
FROM Purchase_1NF;


-- Table 2: Products
CREATE TABLE Products (
    Product_ID VARCHAR(10) PRIMARY KEY,
    Product_Name VARCHAR(50),
    Unit_Price DECIMAL(10,2)
);

INSERT INTO Products
SELECT DISTINCT Product_ID, Product_Name, Unit_Price
FROM Purchase_1NF;


-- Table 3: Order_Details
CREATE TABLE Order_Details (
    Order_ID INT,
    Product_ID VARCHAR(10),
    Quantity INT,
    PRIMARY KEY (Order_ID, Product_ID),
    FOREIGN KEY (Order_ID) REFERENCES Orders(Order_ID),
    FOREIGN KEY (Product_ID) REFERENCES Products(Product_ID)
);

INSERT INTO Order_Details
SELECT Order_ID, Product_ID, Quantity
FROM Purchase_1NF;

SELECT * FROM Orders;
SELECT * FROM Products;
SELECT * FROM Order_Details;


-- 6. THIRD NORMAL FORM (3NF)
-- Customer_ID -> Customer_Name
-- Salesperson_ID -> Salesperson_Name

-- Table 1: Customers
CREATE TABLE Customers (
    Customer_ID VARCHAR(10) PRIMARY KEY,
    Customer_Name VARCHAR(50)
);

INSERT INTO Customers
SELECT DISTINCT Customer_ID, Customer_Name
FROM Purchase_1NF;


-- Table 2: Salespersons
CREATE TABLE Salespersons (
    Salesperson_ID VARCHAR(10) PRIMARY KEY,
    Salesperson_Name VARCHAR(50)
);

INSERT INTO Salespersons
SELECT DISTINCT Salesperson_ID, Salesperson_Name
FROM Purchase_1NF;


-- Table 3: Orders_3NF
CREATE TABLE Orders_3NF (
    Order_ID INT PRIMARY KEY,
    Order_Date DATE,
    Customer_ID VARCHAR(10),
    Salesperson_ID VARCHAR(10),
    FOREIGN KEY (Customer_ID) REFERENCES Customers(Customer_ID),
    FOREIGN KEY (Salesperson_ID) REFERENCES Salespersons(Salesperson_ID)
);

INSERT INTO Orders_3NF
SELECT DISTINCT Order_ID, Order_Date, Customer_ID, Salesperson_ID
FROM Purchase_1NF;

SELECT * FROM Customers;
SELECT * FROM Salespersons;
SELECT * FROM Orders_3NF;


-- 7. BOYCE-CODD NORMAL FORM (BCNF)
-- (Consultant_ID, Project_ID) -> Coordinator_ID
-- Coordinator_ID -> Project_ID

CREATE TABLE Consultant_Assignment (
    Consultant_ID VARCHAR(10),
    Project_ID VARCHAR(10),
    Coordinator_ID VARCHAR(10),
    PRIMARY KEY (Consultant_ID, Project_ID)
);

INSERT INTO Consultant_Assignment VALUES
('E11', 'P11', 'S11'),
('E12', 'P11', 'S11'),
('E13', 'P12', 'S12'),
('E14', 'P12', 'S12');


-- Table 1: Coordinator_Project
CREATE TABLE Coordinator_Project (
    Coordinator_ID VARCHAR(10) PRIMARY KEY,
    Project_ID VARCHAR(10)
);

INSERT INTO Coordinator_Project VALUES
('S11', 'P11'),
('S12', 'P12');


-- Table 2: Consultant_Coordinator
CREATE TABLE Consultant_Coordinator (
    Consultant_ID VARCHAR(10),
    Coordinator_ID VARCHAR(10),
    PRIMARY KEY (Consultant_ID, Coordinator_ID)
);

INSERT INTO Consultant_Coordinator VALUES
('E11', 'S11'),
('E12', 'S11'),
('E13', 'S12'),
('E14', 'S12');


-- VERIFY BCNF DECOMPOSITION
SELECT
    cc.Consultant_ID,
    cp.Project_ID,
    cc.Coordinator_ID
FROM Consultant_Coordinator cc
JOIN Coordinator_Project cp
    ON cc.Coordinator_ID = cp.Coordinator_ID;


-- 8. VERIFY LOSSLESS JOIN
SELECT
    o.Order_ID,
    o.Order_Date,
    c.Customer_ID,
    c.Customer_Name,
    od.Product_ID,
    p.Product_Name,
    od.Quantity,
    p.Unit_Price,
    s.Salesperson_ID,
    s.Salesperson_Name
FROM Orders_3NF o
JOIN Customers c
    ON o.Customer_ID = c.Customer_ID
JOIN Salespersons s
    ON o.Salesperson_ID = s.Salesperson_ID
JOIN Order_Details od
    ON o.Order_ID = od.Order_ID
JOIN Products p
    ON od.Product_ID = p.Product_ID
ORDER BY o.Order_ID, od.Product_ID;


-- VERIFY ROW COUNT
SELECT COUNT(*) AS reconstructed_rows
FROM Orders_3NF o
JOIN Customers c ON o.Customer_ID = c.Customer_ID
JOIN Salespersons s ON o.Salesperson_ID = s.Salesperson_ID
JOIN Order_Details od ON o.Order_ID = od.Order_ID
JOIN Products p ON od.Product_ID = p.Product_ID;


-- 9. VERIFY DEPENDENCY PRESERVATION
-- Customer_ID -> Customer_Name: Customers
-- Salesperson_ID -> Salesperson_Name: Salespersons
-- Order_ID -> Order_Date, Customer_ID, Salesperson_ID: Orders_3NF
-- Product_ID -> Product_Name, Unit_Price: Products
-- (Order_ID, Product_ID) -> Quantity: Order_Details

SHOW CREATE TABLE Customers;
SHOW CREATE TABLE Salespersons;
SHOW CREATE TABLE Orders_3NF;
SHOW CREATE TABLE Products;
SHOW CREATE TABLE Order_Details;


-- 10. COMPARISON OF NORMAL FORMS
-- UNF: May contain repeating groups or non-atomic values.
-- 1NF: Atomic values and no repeating groups.
-- 2NF: 1NF with no partial dependencies.
-- 3NF: 2NF with no prohibited transitive dependencies.
-- BCNF: Every determinant of a non-trivial dependency is a superkey.

-- RESULT:
-- The Sales relation was analyzed and normalized from UNF to 1NF, 2NF and 3NF.
-- A separate relation was decomposed into BCNF. Lossless join and dependency
-- preservation were checked using SQL queries.
