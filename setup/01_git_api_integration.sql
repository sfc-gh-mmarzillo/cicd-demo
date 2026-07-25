-- =====================================================================
-- setup/01_git_api_integration.sql  |  ONE-TIME (run as ACCOUNTADMIN)
-- ---------------------------------------------------------------------
-- Lets a Snowflake Workspace connect to the GitHub repo so you can
-- branch / commit / push from Snowsight. Uses the pre-built Snowflake
-- GitHub App (OAuth) -- no client ID/secret to manage.
--
-- After running this, connect the Workspace in Snowsight:
--   Projects > Workspaces > From Git repository
--     Repository URL : https://github.com/sfc-gh-mmarzillo/cicd-demo
--     API integration: CICD_DEMO_GIT_API
--     Authentication : OAuth2  ->  Sign in and authorize the
--                       "snowflakedb" GitHub app with
--                       "Read and write access to code".
-- (The repo must already contain a branch; see README step order.)
-- =====================================================================

USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE API INTEGRATION CICD_DEMO_GIT_API
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/sfc-gh-mmarzillo')
  API_USER_AUTHENTICATION = (TYPE = SNOWFLAKE_GITHUB_APP)
  ENABLED = TRUE
  COMMENT = 'Git integration for the CI/CD demo Workspace';

GRANT USAGE ON INTEGRATION CICD_DEMO_GIT_API TO ROLE ACCOUNTADMIN;

SHOW API INTEGRATIONS LIKE 'CICD_DEMO_GIT_API';
