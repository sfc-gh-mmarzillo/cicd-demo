-- =====================================================================
-- post_deploy_smoke.sql  |  Runs against CICD_DEMO_DB.PUBLIC (deploy job)
-- ---------------------------------------------------------------------
-- Confirms the real objects exist and are healthy after deployment.
-- =====================================================================

-- Seed data landed.
SELECT COUNT(*) AS customer_rows FROM CICD_DEMO_DB.PUBLIC.CUSTOMERS;
SELECT COUNT(*) AS loan_rows     FROM CICD_DEMO_DB.PUBLIC.LOANS;

-- Semantic view exists and is queryable.
SHOW SEMANTIC VIEWS LIKE 'MORTGAGE_ANALYSIS' IN SCHEMA CICD_DEMO_DB.PUBLIC;
SELECT *
FROM SEMANTIC_VIEW(
  CICD_DEMO_DB.PUBLIC.MORTGAGE_ANALYSIS
  METRICS total_loan_volume, loan_count
  DIMENSIONS product_type
)
ORDER BY product_type;

-- Agent exists with its two tools.
DESCRIBE AGENT CICD_DEMO_DB.PUBLIC.MORTGAGE_AGENT;
