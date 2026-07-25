-- =====================================================================
-- setup/00_snowflake_setup.sql  |  ONE-TIME setup (run as ACCOUNTADMIN)
-- ---------------------------------------------------------------------
-- Creates the deploy target and the OIDC service identity that GitHub
-- Actions uses to authenticate. NOT run by the CI pipeline.
--
-- Review before running: this creates a real Snowflake user (service
-- type) and transfers ownership of a demo database to a deploy role.
-- =====================================================================

USE ROLE ACCOUNTADMIN;

-- ---- Compute ----------------------------------------------------------
CREATE WAREHOUSE IF NOT EXISTS CICD_DEMO_WH
  WAREHOUSE_SIZE = XSMALL
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE
  COMMENT = 'Warehouse for the Snowflake <-> GitHub CI/CD demo';

-- ---- Deploy target ----------------------------------------------------
CREATE DATABASE IF NOT EXISTS CICD_DEMO_DB
  COMMENT = 'Deploy target for the Snowflake <-> GitHub CI/CD demo';

-- ---- Deploy role ------------------------------------------------------
CREATE ROLE IF NOT EXISTS CICD_DEPLOYER
  COMMENT = 'Role used by GitHub Actions to deploy the mortgage agent';

-- Compute + Cortex privileges.
GRANT USAGE, OPERATE ON WAREHOUSE CICD_DEMO_WH TO ROLE CICD_DEPLOYER;
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE CICD_DEPLOYER;

-- Give the deploy role full control of the demo database so it can
-- create/replace tables, the semantic view, the agent, and the
-- ephemeral CI schemas used for pre-deploy validation.
GRANT OWNERSHIP ON DATABASE CICD_DEMO_DB TO ROLE CICD_DEPLOYER COPY CURRENT GRANTS;
GRANT OWNERSHIP ON SCHEMA CICD_DEMO_DB.PUBLIC TO ROLE CICD_DEPLOYER COPY CURRENT GRANTS;

-- Keep admin visibility of anything the deploy role creates.
GRANT ROLE CICD_DEPLOYER TO ROLE ACCOUNTADMIN;

-- ---- OIDC service user ------------------------------------------------
-- Subject is exact and case-sensitive: repo + branch that is allowed to
-- authenticate. This account/repo emits GitHub's IMMUTABLE-ID subject
-- format (owner@<user_id>/repo@<repo_id>) rather than the classic
-- repo:owner/repo form. The numeric IDs are immutable, so this is stable.
-- If the token is ever rejected with "subject ... not recognized", read
-- the exact subject from the failed run log and match it here.
CREATE USER IF NOT EXISTS SVC_GITHUB_ACTIONS
  TYPE = SERVICE
  DEFAULT_ROLE = CICD_DEPLOYER
  DEFAULT_WAREHOUSE = CICD_DEMO_WH
  COMMENT = 'GitHub Actions CI/CD service user (OIDC / workload identity federation)'
  WORKLOAD_IDENTITY = (
    TYPE = OIDC
    ISSUER = 'https://token.actions.githubusercontent.com'
    SUBJECT = 'repo:sfc-gh-mmarzillo@110615653/cicd-demo@1311441425:ref:refs/heads/main'
  );

GRANT ROLE CICD_DEPLOYER TO USER SVC_GITHUB_ACTIONS;

-- ---- Verify -----------------------------------------------------------
SHOW USERS LIKE 'SVC_GITHUB_ACTIONS';
DESC USER SVC_GITHUB_ACTIONS;
