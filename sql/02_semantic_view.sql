-- =====================================================================
-- 02_semantic_view.sql  |  Mortgage analysis semantic view
-- ---------------------------------------------------------------------
-- Backs the "Mortgage Analyst" (Cortex Analyst) tool on the agent.
-- Table references are unqualified so this compiles in whichever schema
-- the workflow targets (ephemeral CI schema or PUBLIC).
-- =====================================================================

CREATE OR REPLACE SEMANTIC VIEW MORTGAGE_ANALYSIS

  TABLES (
    loans AS LOANS
      PRIMARY KEY (loan_id)
      WITH SYNONYMS = ('mortgages')
      COMMENT = 'Mortgage loans originated by the provider',
    customers AS CUSTOMERS
      PRIMARY KEY (customer_id)
      COMMENT = 'Borrowers',
    products AS LOAN_PRODUCTS
      PRIMARY KEY (product_id)
      COMMENT = 'Mortgage products offered'
  )

  RELATIONSHIPS (
    loans_to_customers AS
      loans (customer_id) REFERENCES customers,
    loans_to_products AS
      loans (product_id) REFERENCES products
  )

  FACTS (
    loans.loan_amount AS loan_amount
      COMMENT = 'Principal amount of the loan',
    loans.interest_rate AS interest_rate
      COMMENT = 'Annual interest rate on the loan'
  )

  DIMENSIONS (
    customers.state AS customers.state
      WITH SYNONYMS = ('borrower state')
      COMMENT = 'US state of the borrower',
    products.product_type AS products.product_type
      WITH SYNONYMS = ('loan type')
      COMMENT = 'Fixed or ARM',
    products.product_name AS products.product_name
      COMMENT = 'Name of the mortgage product',
    loans.status AS loans.status
      COMMENT = 'Current loan status',
    loans.origination_month AS DATE_TRUNC('month', loans.origination_date)
      COMMENT = 'Month the loan was originated'
  )

  METRICS (
    loans.total_loan_volume AS SUM(loans.loan_amount)
      COMMENT = 'Total dollar volume of loans',
    loans.avg_loan_amount AS AVG(loans.loan_amount)
      COMMENT = 'Average loan amount',
    loans.loan_count AS COUNT(loans.loan_id)
      COMMENT = 'Number of loans'
  )

  COMMENT = 'Mortgage provider analysis: loans, borrowers, and products';
