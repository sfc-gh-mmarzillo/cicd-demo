# Snowflake &lt;-&gt; GitHub CI/CD Demo

A small, end-to-end demo that shows how Snowflake and GitHub work together:

- **Author** a Cortex Agent (+ its semantic view and seed data) inside a **Git-connected Snowflake Workspace**.
- **Commit + push** a branch straight from Snowsight, then open and merge a **Pull Request** on GitHub.
- **GitHub Actions** authenticates to Snowflake with **OIDC** (no stored secret), runs lightweight tests, then **deploys** the objects back to Snowflake.

## The agent

`MORTGAGE_AGENT` is a mortgage-provider analytics agent with two skills/tools:

1. **Mortgage_Analyst** - Cortex Analyst over the `MORTGAGE_ANALYSIS` semantic view (loans, borrowers, products).
2. **data_to_chart** - the built-in visualization tool.

## Repository layout

```
.
├── .github/workflows/deploy.yml   # CI/CD pipeline (test + deploy, OIDC auth)
├── sql/
│   ├── 01_tables.sql              # mortgage seed data (customers, products, loans)
│   ├── 02_semantic_view.sql       # MORTGAGE_ANALYSIS semantic view
│   └── 03_agent.sql               # MORTGAGE_AGENT (Analyst + data_to_chart)
├── tests/
│   ├── pre_deploy_checks.sql      # validate in an ephemeral CI schema
│   └── post_deploy_smoke.sql      # verify objects after deploy to PUBLIC
└── setup/                         # one-time, run manually (NOT run by CI)
    ├── 00_snowflake_setup.sql     # DB + warehouse + deploy role + OIDC service user
    └── 01_git_api_integration.sql # API integration for the Git Workspace
```

## Deploy target

| Object      | Name                              |
| ----------- | --------------------------------- |
| Account     | `SFSENORTHAMERICA-HOL_MATTMARZILLO` |
| Database    | `CICD_DEMO_DB`                    |
| Schema      | `PUBLIC`                          |
| Warehouse   | `CICD_DEMO_WH`                    |
| Deploy role | `CICD_DEPLOYER`                   |
| CI identity | `SVC_GITHUB_ACTIONS` (OIDC)       |

## How the pipeline works

```
Workspace edit --> commit + push branch --> open PR --> merge to main
      --> GitHub Actions (on: push main)
            test job:   OIDC auth -> build tables + SV in CI_<run_id> schema -> checks -> drop schema
            deploy job: recreate tables + SV + agent in PUBLIC -> smoke tests
      --> agent + semantic view updated in Snowflake
```

- **OIDC**: `snowflakedb/snowflake-actions@v2` with `use-oidc: true` mints a short-lived token. Snowflake maps it to `SVC_GITHUB_ACTIONS` via `WORKLOAD_IDENTITY`. No password or key is stored in GitHub.
- **Ephemeral testing**: the `test` job builds everything in a throwaway `CI_<run_id>` schema and runs `pre_deploy_checks.sql`. If the semantic view is broken, the build fails before `PUBLIC` is touched.
- **Deploy**: the `deploy` job runs only if `test` passes, recreates the objects in `PUBLIC`, and runs `post_deploy_smoke.sql`.

## One-time setup (do this first, in order)

1. **Provision Snowflake** - run [`setup/00_snowflake_setup.sql`](setup/00_snowflake_setup.sql) as `ACCOUNTADMIN`. Creates the database, warehouse, deploy role, and the OIDC service user.
2. **Create the Git API integration** - run [`setup/01_git_api_integration.sql`](setup/01_git_api_integration.sql) as `ACCOUNTADMIN`.
3. **Seed this repo** - push these files to `main` (the repo must be non-empty before a Workspace can connect). Because the OIDC user already exists from step 1, this first push also serves as the first end-to-end pipeline run.
4. **Connect the Workspace** - in Snowsight: `Projects > Workspaces > From Git repository`, point at `https://github.com/sfc-gh-mmarzillo/cicd-demo`, choose the `CICD_DEMO_GIT_API` integration, and authorize the `snowflakedb` GitHub app with read + write access to code.

## Running the demo

1. In the Snowflake Workspace, make a small change - e.g. add a metric to [`sql/02_semantic_view.sql`](sql/02_semantic_view.sql):

   ```sql
   loans.avg_interest_rate AS AVG(loans.interest_rate)
     COMMENT = 'Average interest rate across loans',
   ```

2. In the Workspace **Changes** tab: create a branch, write a commit message, and **Push**.
3. On GitHub, open a **Pull Request** from your branch into `main`, then **merge** it.
4. The merge triggers **Actions**. Watch the `test` then `deploy` jobs run.
5. In Snowsight (`AI & ML > Agents`), open **Mortgage Analytics Agent** and confirm the change is live (e.g. ask "What is the average interest rate by product type?").
