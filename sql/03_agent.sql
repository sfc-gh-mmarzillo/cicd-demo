-- =====================================================================
-- 03_agent.sql  |  Mortgage analytics Cortex Agent
-- ---------------------------------------------------------------------
-- Two skills / tools:
--   1. Mortgage_Analyst  (cortex_analyst_text_to_sql) over the semantic view
--   2. data_to_chart     (built-in visualization tool)
-- The semantic view is fully qualified because the agent is only ever
-- created in the deploy target (CICD_DEMO_DB.PUBLIC).
-- =====================================================================

CREATE OR REPLACE AGENT MORTGAGE_AGENT
  COMMENT = 'Mortgage provider analytics agent (Snowflake <-> GitHub CI/CD demo)'
  PROFILE = '{"display_name": "Mortgage Analytics Agent", "color": "blue"}'
  FROM SPECIFICATION
  $$
  models:
    orchestration: auto

  instructions:
    response: "You are a concise analytics assistant for a mortgage provider. Begin every answer with 'Mortgage Insights —'. Present all interest rates as percentages with two decimals (e.g. 6.49%). Answer with concrete numbers and a short explanation."
    orchestration: "Use the Mortgage_Analyst tool for any question about loans, borrowers, loan volume, interest rates, products, or loan status. Use data_to_chart to visualize results whenever the user asks for a trend, breakdown, or comparison."
    sample_questions:
      - question: "What is the total loan volume by state?"
      - question: "How many loans do we have by product type?"
      - question: "What is the average interest rate by product type?"

  tools:
    - tool_spec:
        type: "cortex_analyst_text_to_sql"
        name: "Mortgage_Analyst"
        description: "Answers questions about mortgage loans, borrowers, loan amounts, interest rates, products, and loan status."
    - tool_spec:
        type: "data_to_chart"
        name: "data_to_chart"
        description: "Generates visualizations from query results."

  tool_resources:
    Mortgage_Analyst:
      semantic_view: "CICD_DEMO_DB.PUBLIC.MORTGAGE_ANALYSIS"
      execution_environment:
        type: warehouse
        warehouse: "CICD_DEMO_WH"
  $$;
