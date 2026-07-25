-- =====================================================================
-- pre_deploy_checks.sql  |  Runs in the ephemeral CI schema (test job)
-- ---------------------------------------------------------------------
-- Tables + semantic view are created in a throwaway schema first, then
-- these checks run. If anything here errors, the pipeline fails BEFORE
-- the deploy job touches PUBLIC.
-- =====================================================================

-- 1. Assertion: fail the build if the seed data did not load.
--    IFF(count>0,1,0) -> divide-by-zero error when a table is empty.
SELECT 1 / IFF((SELECT COUNT(*) FROM CUSTOMERS)     > 0, 1, 0) AS customers_loaded;
SELECT 1 / IFF((SELECT COUNT(*) FROM LOAN_PRODUCTS) > 0, 1, 0) AS products_loaded;
SELECT 1 / IFF((SELECT COUNT(*) FROM LOANS)         > 0, 1, 0) AS loans_loaded;

-- 2. Prove the semantic view compiles and is queryable end to end.
--    A broken relationship, dimension, or metric fails this query.
SELECT *
FROM SEMANTIC_VIEW(
  MORTGAGE_ANALYSIS
  METRICS total_loan_volume, loan_count
  DIMENSIONS state
)
ORDER BY state;

-- 3. Exercise a second dimension path (loans -> products).
SELECT *
FROM SEMANTIC_VIEW(
  MORTGAGE_ANALYSIS
  METRICS total_loan_volume, avg_loan_amount
  DIMENSIONS product_type
)
ORDER BY product_type;
