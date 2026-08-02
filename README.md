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
Workspace edit --> commit + push branch --> open PR
      --> GitHub Actions (on: pull_request)   test job only  -> PR status check (validate, no deploy)
   merge to main
      --> GitHub Actions (on: push main)      test job -> deploy job
            test job:   OIDC auth -> build tables + SV in CI_<run_id> schema -> checks -> drop schema
            deploy job: recreate tables + SV + agent in PUBLIC -> smoke tests
      --> agent + semantic view updated in Snowflake
```

- **OIDC**: `snowflakedb/snowflake-actions@v2` with `use-oidc: true` mints a short-lived token. Snowflake maps it to `SVC_GITHUB_ACTIONS` via `WORKLOAD_IDENTITY`. No password or key is stored in GitHub.
- **PR validation**: on `pull_request`, only the `test` job runs - it validates in a throwaway `CI_<run_id>` schema and reports a status check on the PR. Nothing is deployed until the PR is merged. The `deploy` job is gated with `if: github.event_name != 'pull_request'`.
- **Ephemeral testing**: the `test` job builds everything in a throwaway `CI_<run_id>` schema and runs `pre_deploy_checks.sql`. If the semantic view is broken, the build fails before `PUBLIC` is touched.
- **Deploy**: on push to `main` (merge) or manual dispatch, the `deploy` job runs only if `test` passes, recreates the objects in `PUBLIC`, and runs `post_deploy_smoke.sql`.

### Make the PR check required (branch protection)

To turn the PR status check into an enforced gate: GitHub repo **Settings > Branches > Add branch ruleset** (or classic branch protection) for `main` -> enable **Require status checks to pass before merging** -> select the **test** check. Merges are then blocked until validation is green.

## One-time setup (do this first, in order)

1. **Provision Snowflake** - run [`setup/00_snowflake_setup.sql`](setup/00_snowflake_setup.sql) as `ACCOUNTADMIN`. Creates the database, warehouse, deploy role, and the OIDC service user.
2. **Create the Git API integration** - run [`setup/01_git_api_integration.sql`](setup/01_git_api_integration.sql) as `ACCOUNTADMIN`.
3. **Seed this repo** - push these files to `main` (the repo must be non-empty before a Workspace can connect). Because the OIDC user already exists from step 1, this first push also serves as the first end-to-end pipeline run.
4. **Connect the Workspace** - in Snowsight: `Projects > Workspaces > From Git repository`, point at `https://github.com/sfc-gh-mmarzillo/cicd-demo`, choose the `CICD_DEMO_GIT_API` integration, and authorize the `snowflakedb` GitHub app with read + write access to code.

## Running the demo

1. In the Snowflake Workspace, make a small, visible change to the agent in [`sql/03_agent.sql`](sql/03_agent.sql). Edit the `response` instruction and add a sample question:

   ```yaml
   instructions:
     response: "You are a concise analytics assistant for a mortgage provider. Begin every answer with 'Mortgage Insights —'. Present all interest rates as percentages with two decimals (e.g. 6.49%). Answer with concrete numbers and a short explanation."
     orchestration: "Use the Mortgage_Analyst tool for any question about loans, borrowers, loan volume, interest rates, products, or loan status. Use data_to_chart to visualize results whenever the user asks for a trend, breakdown, or comparison."
     sample_questions:
       - question: "What is the total loan volume by state?"
       - question: "How many loans do we have by product type?"
       - question: "What is the average interest rate by product type?"
   ```

2. In the Workspace **Changes** tab: create a branch, write a commit message, and **Push**.
3. On GitHub, open a **Pull Request** from your branch into `main`. The **test** job runs automatically and posts a status check on the PR (validation only - nothing deployed yet).
4. Once the check is green, **merge** the PR. The merge triggers the full run: `test` then `deploy`.
5. In Snowsight (`AI & ML > Agents`), open **Mortgage Analytics Agent** and ask "What's the average interest rate by product type?". The answer now starts with **"Mortgage Insights —"** and formats rates as percentages (e.g. 6.49%) - a visible, agent-level change shipped entirely through the PR + CI/CD flow.

## Extending this for real use

Two natural next steps, left as exercises so the demo stays focused:

- **Test agent/answer quality in CI, not just object existence.** Add verified queries (`AI_VERIFIED_QUERIES`) to the semantic view and add a pipeline step that evaluates them (native semantic-view `sql_correctness` evaluation, or exercise the agent with `DATA_AGENT_RUN`). This gates deploys on AI accuracy, not just "the DDL compiled."
- **Environment promotion.** Deploy feature branches to a `DEV` schema and `main` to `PUBLIC` by parameterizing the target schema per branch - the same scripts, a different `--schema`.
