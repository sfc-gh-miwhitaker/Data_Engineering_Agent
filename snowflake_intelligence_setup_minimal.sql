/*
================================================================================
🚀 SNOWFLAKE INTELLIGENCE: MINIMAL SETUP SCRIPT
================================================================================

• Creates AI_DEVELOPER role and warehouse
• Creates SNOWFLAKE_INTELLIGENCE database with AGENTS and DATA_AGENTS schemas
• Grants necessary privileges for AI assistant development
• Grants access to SNOWFLAKE.ACCOUNT_USAGE for semantic views
• Configures Snowflake Documentation Knowledge Base (CKE) access

PREREQUISITES:
• Snowflake Documentation Knowledge Extension must be installed from Marketplace
• Run as ACCOUNTADMIN role

EXECUTION:
1. Install Snowflake Documentation extension from Marketplace (if not already installed)
2. Replace <YOUR_USERNAME> with your actual username
3. Run entire script as ACCOUNTADMIN

================================================================================
*/

-- Set role and create foundation objects
USE ROLE ACCOUNTADMIN;

-- Create AI development role and warehouse
CREATE ROLE IF NOT EXISTS AI_DEVELOPER;
CREATE WAREHOUSE IF NOT EXISTS AI_DEVELOPER_WH 
    WITH WAREHOUSE_SIZE = 'XSMALL' 
         AUTO_SUSPEND = 60 
         AUTO_RESUME = TRUE;
GRANT USAGE, OPERATE, MONITOR ON WAREHOUSE AI_DEVELOPER_WH TO ROLE AI_DEVELOPER;

-- Grant role to user (REPLACE <YOUR_USERNAME> WITH YOUR ACTUAL USERNAME)
-- GRANT ROLE AI_DEVELOPER TO USER <YOUR_USERNAME>;
GRANT ROLE AI_DEVELOPER TO USER <YOUR_USERNAME>;

-- Switch to role that will the Cortex Configuration Database
USE ROLE SYSADMIN;

-- Create database and schemas
CREATE DATABASE IF NOT EXISTS SNOWFLAKE_INTELLIGENCE;
USE DATABASE SNOWFLAKE_INTELLIGENCE;
CREATE SCHEMA IF NOT EXISTS AGENTS;
CREATE SCHEMA IF NOT EXISTS DATA_AGENTS;

-- Grant privileges
GRANT USAGE ON DATABASE SNOWFLAKE_INTELLIGENCE TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA SNOWFLAKE_INTELLIGENCE.DATA_AGENTS TO ROLE PUBLIC;

GRANT USAGE, CREATE SCHEMA ON DATABASE SNOWFLAKE_INTELLIGENCE TO ROLE AI_DEVELOPER;
GRANT USAGE, CREATE TABLE, CREATE VIEW, CREATE STAGE, CREATE FILE FORMAT, CREATE SEQUENCE, CREATE FUNCTION, CREATE PROCEDURE ON SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS TO ROLE AI_DEVELOPER;
GRANT USAGE, CREATE TABLE, CREATE VIEW, CREATE STAGE, CREATE FILE FORMAT, CREATE SEQUENCE, CREATE FUNCTION, CREATE PROCEDURE, CREATE SEMANTIC VIEW ON SCHEMA SNOWFLAKE_INTELLIGENCE.DATA_AGENTS TO ROLE AI_DEVELOPER;
GRANT CREATE AGENT ON SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS TO ROLE AI_DEVELOPER;

-- Grant access to ACCOUNT_USAGE for semantic views
GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE TO ROLE AI_DEVELOPER;

-- OPTIONAL: Set as default role and warehouse
-- ALTER USER <YOUR_USERNAME> SET DEFAULT_ROLE = AI_DEVELOPER, DEFAULT_WAREHOUSE = AI_DEVELOPER_WH;

/*
================================================================================
✅ FOUNDATION SETUP COMPLETE!
================================================================================

NEXT STEPS - WALKTHROUGH GUIDE:

STEP 0: INSTALL SNOWFLAKE DOCUMENTATION KNOWLEDGE EXTENSION
────────────────────────────────────────────────────────────────────────────────
⚠️  CRITICAL: Complete this step before proceeding with the agent setup!

1. Navigate to: Data Products > Marketplace
2. Search for "Snowflake Documentation"
3. "Get" the "Snowflake Documentation" extension - granting access to the PUBLIC role

STEP 1: CREATE SEMANTIC VIEW
────────────────────────────────────────────────────────────────────────────────
1. Navigate to: AI & ML > Cortex Analyst
2. Create new semantic view:
   • Name: SNOWFLAKE_USAGE_ASSISTANT
   • Location: SNOWFLAKE_INTELLIGENCE.DATA_AGENTS
   • Source: SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY, SNOWFLAKE.ACCOUNT_USAGE.QUERY_ATTRIBUTION_HISTORY
   - Select all columns (approximately 85 columns total)
 
 If prompted in wizard, complete the following:
   - Create a Cortex Search Service on columns DATABASE_NAME, USER_NAME, WAREHOUSE_NAME, WAREHOUSE_SIZE, WAREHOUSE_TYPE
   - Keep the default options for:
     - Location (SNOWFLAKE_INTELLIGENCE.DATA_AGENTS)
     - Role (AI_DEVELOPER)
     - Warehouse (AI_DEVELOPER_WH)
     - Embedding model (snowflake-arctic-embed-m-v1.5)
     - Target Lag (1 day)

If not prompted in wizard, these may be completed manually as additional steps to make agent more robust.

STEP 2: CREATE AI AGENT
────────────────────────────────────────────────────────────────────────────────
1. Navigate to: AI & ML > Agents
2. Select "Create agent" with pre-configured optimization intelligence
   • Schema: SNOWFLAKE_INTELLIGENCE.AGENTS

STEP 3: CONFIGURE AGENT BASICS
────────────────────────────────────────────────────────────────────────────────
1. Provide Agent Details:
   • Object Name: DATA_ENGINEER_ASSISTANT
   • Display Name: Data Engineer Assistant

2. Select the created agent and click "Edit"

3. On the "About" tab, provide Description:
   
I'm your Snowflake Data Engineer Assistant, designed to help you optimize query 
performance and resolve data engineering challenges. I analyze your actual query 
history to provide personalized, actionable recommendations for your Snowflake 
environment.

4. Click "Save"

STEP 4: CONFIGURE AGENT INSTRUCTIONS
────────────────────────────────────────────────────────────────────────────────
1. On the "Instructions" tab, provide Response Instructions:

   You are a Snowflake Data Engineer Assistant. Always provide:
   • Specific recommendations** with clear next steps
   • Actual metrics from query history data
   • Prioritized solutions (high-impact first)
   • Snowflake best practices (Gen 2 warehouses, clustering, modern SQL)

2. Add Sample Questions (one by one using "Add a question"):

   • Based on my top 10 slowest queries, can you provide ways to optimize them?
   • What was the query that's causing performance issues?
   • How can I optimize this specific query?
   • Which warehouses should be upgraded to Gen 2?
   • Show me queries with compilation errors and how to fix them
   • What queries are scanning the most data and how can I reduce that?
   • Which time series SQL functions should I use for temporal analysis?
   • What are the most common query patterns causing issues?
   • How can I improve query compilation times?
   • What Snowflake features am I not using that could help performance?
   • Would my query benefit from Query Acceleration or Search Optimization Service?

3. Click "Save"

STEP 5: CONFIGURE AGENT TOOLS
────────────────────────────────────────────────────────────────────────────────
1. On the "Tools" tab, add Cortex Analyst:

   • Click "+ Add" for Cortex Analyst option
   • Select "Semantic View" and navigate to SNOWFLAKE_INTELLIGENCE.DATA_AGENTS
   • Link to your "SNOWFLAKE_USAGE_ASSISTANT"
   • Name: 
      Data_Engineer_Assistant_Semantic_View
   • Description:
      Use this tool to analyze Snowflake query performance and identify optimization 
         opportunities. This semantic view provides access to query history data, including 
         execution times, compilation times, bytes scanned, warehouse usage, and error 
         information.

         Use this tool when users ask about:
         - Slowest running queries and performance bottlenecks
         - Query optimization recommendations
         - Warehouse utilization and sizing recommendations
         - Compilation errors and troubleshooting
         - Data scanning patterns and efficiency analysis
         - Historical query trends and usage patterns

         The tool returns structured data about query performance metrics that can be used 
         to provide specific, actionable optimization recommendations.
   • Warehouse: 
      User's default
   • Query timeout: 
      100
   • Click "Add"

2. Add Cortex Search Service:
   • Click "+ Add" for Cortex Search Services option
   • Name: 
      Cortex_Knowledge_Extension_Snowflake_Documentation
   • Description:
      Search Snowflake Documentation via Snowflake Marketplace Knowledge Extension.
   • Database/Schema: 
      SNOWFLAKE_DOCUMENTATION.SHARED
   • Link to search service: 
      CKE_SNOWFLAKE_DOCS_SERVICE
   • ID column: 
      SOURCE_URL
   • Title column: 
      DOCUMENT_TITLE
   • Click "Add"

3. Click "Save"

STEP 6: CONFIGURE ORCHESTRATION
────────────────────────────────────────────────────────────────────────────────
1. On the "Orchestration" tab:
   • Keep Orchestration model as "auto"
   • Provide Planning Instructions:
      For query performance analysis requests:
      1. First, query the semantic view to identify relevant queries, performance metrics, and patterns
      2. Analyze execution times, compilation times, bytes scanned, and warehouse usage
      3. Prioritize findings by impact (slowest queries, highest resource usage, most frequent errors)
      4. Use Snowflake documentation search to reference best practices and specific features
      5. Provide specific, actionable recommendations with clear next steps

      For optimization questions:
      1. Start with the query history data to understand current performance
      2. Identify bottlenecks and inefficiencies in the data
      3. Reference Snowflake documentation for feature recommendations (Gen 2 warehouses, clustering, etc.)
      4. Provide concrete optimization steps with expected improvements

      For troubleshooting:
      1. Analyze error patterns and compilation issues from query history
      2. Search documentation for specific error resolution guidance
      3. Provide step-by-step fixes and prevention strategies

      Always ground recommendations in actual data from the user's query history.

2. Click "Save"

STEP 7: CONFIGURE ACCESS
────────────────────────────────────────────────────────────────────────────────
1. On the "Access" tab, add roles:
   • AI_DEVELOPER: Ownership
   • <custom_role>: Usage (replace <custom_role> with the role you want to grant usage to)

STEP 8: TEST YOUR ASSISTANT
────────────────────────────────────────────────────────────────────────────────
1. Navigate to "Snowflake Intelligence" (recommend opening in new tab)
2. Use AI_DEVELOPER role
3. Select the "Data Engineer Assistant"
4. Keep Sources: "Auto"
5. Test some of the sample questions

🎉 Your Snowflake Data Engineer Assistant is ready to optimize your performance!
================================================================================
*/
