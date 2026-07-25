-- =====================================================================
-- 01_tables.sql  |  Mortgage provider seed data
-- ---------------------------------------------------------------------
-- Schema-agnostic on purpose: object names are unqualified so the same
-- file runs against the ephemeral CI schema (test job) and PUBLIC
-- (deploy job). The GitHub Actions workflow points the connection at
-- the right schema with `snow sql --schema <name>`.
-- =====================================================================

CREATE OR REPLACE TABLE CUSTOMERS (
  customer_id   INT PRIMARY KEY,
  full_name     STRING,
  state         STRING,
  credit_score  INT,
  annual_income NUMBER(12,2)
);

CREATE OR REPLACE TABLE LOAN_PRODUCTS (
  product_id    INT PRIMARY KEY,
  product_name  STRING,
  product_type  STRING,        -- Fixed / ARM
  base_rate     NUMBER(5,3)
);

CREATE OR REPLACE TABLE LOANS (
  loan_id          INT PRIMARY KEY,
  customer_id      INT,
  product_id       INT,
  loan_amount      NUMBER(12,2),
  interest_rate    NUMBER(5,3),
  origination_date DATE,
  term_months      INT,
  status           STRING       -- Active / Paid Off / Delinquent / In Review
);

INSERT INTO CUSTOMERS (customer_id, full_name, state, credit_score, annual_income) VALUES
  (1, 'Alice Nguyen',    'CA', 780, 145000.00),
  (2, 'Brian Carter',    'TX', 705, 98000.00),
  (3, 'Carmen Diaz',     'FL', 660, 72000.00),
  (4, 'David Okafor',    'NY', 745, 132000.00),
  (5, 'Emily Zhang',     'CA', 810, 210000.00),
  (6, 'Frank Rossi',     'IL', 690, 88000.00),
  (7, 'Grace Kim',       'WA', 758, 121000.00),
  (8, 'Hector Alvarez',  'TX', 640, 65000.00);

INSERT INTO LOAN_PRODUCTS (product_id, product_name, product_type, base_rate) VALUES
  (10, '30-Year Fixed',      'Fixed', 6.750),
  (11, '15-Year Fixed',      'Fixed', 6.000),
  (12, '5/1 ARM',            'ARM',   6.250),
  (13, '7/1 ARM',            'ARM',   6.400);

INSERT INTO LOANS (loan_id, customer_id, product_id, loan_amount, interest_rate, origination_date, term_months, status) VALUES
  (1001, 1, 10, 620000.00, 6.875, '2024-01-15', 360, 'Active'),
  (1002, 2, 12, 340000.00, 6.500, '2024-02-03', 360, 'Active'),
  (1003, 3, 10, 250000.00, 7.125, '2024-02-20', 360, 'Delinquent'),
  (1004, 4, 11, 480000.00, 6.125, '2024-03-11', 180, 'Active'),
  (1005, 5, 13, 910000.00, 6.500, '2024-03-28', 360, 'Active'),
  (1006, 6, 10, 300000.00, 6.990, '2024-04-09', 360, 'In Review'),
  (1007, 7, 11, 410000.00, 6.250, '2024-05-02', 180, 'Active'),
  (1008, 8, 12, 220000.00, 6.750, '2024-05-19', 360, 'Delinquent'),
  (1009, 1, 11, 150000.00, 6.000, '2024-06-07', 180, 'Paid Off'),
  (1010, 2, 10, 355000.00, 6.875, '2024-06-25', 360, 'Active'),
  (1011, 5, 10, 725000.00, 6.750, '2024-07-14', 360, 'Active'),
  (1012, 4, 13, 500000.00, 6.400, '2024-08-01', 360, 'Active'),
  (1013, 6, 12, 275000.00, 6.300, '2024-08-22', 360, 'Active'),
  (1014, 3, 11, 195000.00, 6.125, '2024-09-05', 180, 'Paid Off'),
  (1015, 7, 10, 465000.00, 7.000, '2024-09-30', 360, 'In Review');
