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

-- Create semantic view delivering cost, performance, and efficiency analytics
USE ROLE AI_DEVELOPER;
USE WAREHOUSE AI_DEVELOPER_WH;
USE DATABASE SNOWFLAKE_INTELLIGENCE;
USE SCHEMA DATA_AGENTS;

CREATE OR REPLACE SEMANTIC VIEW SNOWFLAKE_USAGE_ASSISTANT
    COMMENT = 'Cost, performance, and efficiency model sourced from ACCOUNT_USAGE.'
    TABLES (
        query_history AS SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
            COMMENT = 'One row per executed query with core performance telemetry.'
            PRIMARY KEY (query_id),
        query_attribution_history AS SNOWFLAKE.ACCOUNT_USAGE.QUERY_ATTRIBUTION_HISTORY
            COMMENT = 'Per-query credit attribution across compute and cloud services.'
            PRIMARY KEY (query_id),
        query_acceleration_history AS SNOWFLAKE.ACCOUNT_USAGE.QUERY_ACCELERATION_HISTORY
            COMMENT = 'Query Acceleration Service activity for eligible statements.'
            PRIMARY KEY (query_id, acceleration_service_type),
        access_history AS SNOWFLAKE.ACCOUNT_USAGE.ACCESS_HISTORY
            COMMENT = 'Object and column access footprint captured for each query.'
            PRIMARY KEY (query_id)
    )
    RELATIONSHIPS (
        query_attribution_history (query_id) REFERENCES query_history,
        query_acceleration_history (query_id) REFERENCES query_history,
        access_history (query_id) REFERENCES query_history
    )
    FACTS (
        query_history.query_id AS query_id COMMENT 'Unique identifier for the executed query.',
        query_history.query_text AS query_text COMMENT 'SQL text submitted by the client (truncated when necessary).',
        query_history.query_type AS query_type COMMENT 'Snowflake classified statement type such as SELECT or COPY.',
        query_history.database_name AS database_name COMMENT 'Database referenced during execution.',
        query_history.schema_name AS schema_name COMMENT 'Schema referenced during execution.',
        query_history.user_name AS user_name COMMENT 'Snowflake user who submitted the query.',
        query_history.role_name AS role_name COMMENT 'Role that was active when the query ran.',
        query_history.session_id AS session_id COMMENT 'Session identifier associated with the query.',
        query_history.client_application AS client_application COMMENT 'Client application that issued the query.',
        query_history.warehouse_id AS warehouse_id COMMENT 'Identifier of the warehouse that executed the query.',
        query_history.warehouse_name AS warehouse_name COMMENT 'Warehouse name used to process the query.',
        query_history.warehouse_size AS warehouse_size COMMENT 'Size of the warehouse at execution time.',
        query_history.total_elapsed_time AS total_elapsed_time_ms COMMENT 'Total time in milliseconds from submission through completion.',
        query_history.execution_time AS execution_time_ms COMMENT 'Milliseconds spent executing the statement.',
        query_history.compilation_time AS compilation_time_ms COMMENT 'Milliseconds spent compiling the statement.',
        query_history.queued_provisioning_time AS queued_provisioning_time_ms COMMENT 'Milliseconds waiting for warehouse provisioning.',
        query_history.queued_overload_time AS queued_overload_time_ms COMMENT 'Milliseconds waiting due to warehouse overload.',
        query_history.queued_repair_time AS queued_repair_time_ms COMMENT 'Milliseconds waiting for cluster repair.',
        query_history.bytes_scanned AS bytes_scanned COMMENT 'Bytes scanned from storage during execution.',
        query_history.bytes_written AS bytes_written COMMENT 'Bytes written to storage during execution.',
        query_history.rows_produced AS rows_produced COMMENT 'Row count returned or produced by the query.',
        query_history.rows_inserted AS rows_inserted COMMENT 'Rows inserted by the statement.',
        query_history.rows_updated AS rows_updated COMMENT 'Rows updated by the statement.',
        query_history.rows_deleted AS rows_deleted COMMENT 'Rows deleted by the statement.',
        query_history.execution_status AS execution_status COMMENT 'Terminal execution state reported by Snowflake.',
        query_history.error_code AS error_code COMMENT 'Error code returned for failed queries.',
        query_history.error_message AS error_message COMMENT 'Error message returned for failed queries.',
        query_history.query_tag AS query_tag COMMENT 'User-specified tag applied to the query.',
        query_attribution_history.service_type AS service_type COMMENT 'Snowflake service type attributed for credit usage.',
        query_attribution_history.credits_used AS credits_used COMMENT 'Total credits billed to the query.',
        query_attribution_history.credits_used_compute AS credits_used_compute COMMENT 'Credits billed for virtual warehouse compute.',
        query_attribution_history.credits_used_cloud_services AS credits_used_cloud_services COMMENT 'Credits billed for cloud services.',
        query_acceleration_history.acceleration_status AS acceleration_status COMMENT 'Query Acceleration Service status for the query.',
        query_acceleration_history.acceleration_mode AS acceleration_mode COMMENT 'Query Acceleration mode applied during execution.',
        query_acceleration_history.acceleration_bytes_scanned AS acceleration_bytes_scanned COMMENT 'Bytes scanned through Query Acceleration Service.',
        query_acceleration_history.acceleration_error_code AS acceleration_error_code COMMENT 'Error code emitted by Query Acceleration Service.',
        query_acceleration_history.acceleration_error_message AS acceleration_error_message COMMENT 'Error message emitted by Query Acceleration Service.',
        query_acceleration_history.eligible AS acceleration_eligible COMMENT 'Indicates whether the query qualified for acceleration.',
        access_history.base_objects_accessed AS base_objects_accessed COMMENT 'JSON array describing base objects touched by the query.',
        access_history.direct_objects_accessed AS direct_objects_accessed COMMENT 'JSON array of directly referenced objects.',
        access_history.objects_accessed AS objects_accessed COMMENT 'JSON array of all objects accessed during execution.',
        access_history.columns_accessed AS columns_accessed COMMENT 'JSON array of columns accessed during execution.'
    )
    DIMENSIONS (
        query_history.start_time AS start_time COMMENT 'Timestamp when execution began.',
        query_history.end_time AS end_time COMMENT 'Timestamp when execution completed.',
        DATE_TRUNC('DAY', query_history.start_time) AS start_day COMMENT 'Calendar day the query started.',
        DATE_TRUNC('HOUR', query_history.start_time) AS start_hour COMMENT 'Hour the query started, useful for workload shape.',
        query_history.execution_status AS status COMMENT 'Execution status dimension for filtering and grouping.',
        query_history.query_type AS statement_category COMMENT 'Statement category for workload segmentation.',
        query_history.warehouse_name AS warehouse COMMENT 'Warehouse name dimension.',
        query_history.user_name AS submitted_by COMMENT 'User dimension for accountability.',
        query_history.role_name AS active_role COMMENT 'Role dimension for governance analysis.',
        query_attribution_history.service_type AS cost_service_type COMMENT 'Service type driving credit consumption.',
        query_acceleration_history.acceleration_status AS acceleration_status_dim COMMENT 'Acceleration status dimension.',
        query_acceleration_history.acceleration_service_type AS acceleration_service_type COMMENT 'Acceleration service type dimension.'
    )
    METRICS (
        query_count AS COUNT(query_history.query_id)
            COMMENT 'Total queries executed within the selected filters.',
        accelerated_query_count AS COUNT_IF(query_acceleration_history.acceleration_status = 'SUCCESS')
            COMMENT 'Number of queries successfully accelerated by Query Acceleration Service.',
        total_credits_used AS SUM(query_attribution_history.credits_used)
            COMMENT 'Aggregate credits consumed by the filtered queries.',
        total_compute_credits AS SUM(query_attribution_history.credits_used_compute)
            COMMENT 'Total compute credits consumed by the filtered queries.',
        total_cloud_services_credits AS SUM(query_attribution_history.credits_used_cloud_services)
            COMMENT 'Total cloud services credits consumed by the filtered queries.',
        total_bytes_scanned AS SUM(query_history.bytes_scanned)
            COMMENT 'Aggregate bytes scanned across the filtered queries.',
        total_rows_produced AS SUM(query_history.rows_produced)
            COMMENT 'Aggregate rows produced across the filtered queries.',
        avg_execution_time_ms AS AVG(query_history.execution_time)
            COMMENT 'Average execution duration in milliseconds.',
        p95_execution_time_ms AS APPROX_PERCENTILE(query_history.execution_time, 0.95)
            COMMENT '95th percentile execution duration in milliseconds.',
        avg_credits_per_query AS AVG(query_attribution_history.credits_used)
            COMMENT 'Average credits consumed per query.',
        bytes_per_credit AS SUM(query_history.bytes_scanned)
            / NULLIF(SUM(query_attribution_history.credits_used), 0)
            COMMENT 'Bytes scanned divided by credits consumed, a storage efficiency indicator.',
        rows_per_credit AS SUM(query_history.rows_produced)
            / NULLIF(SUM(query_attribution_history.credits_used), 0)
            COMMENT 'Rows produced per credit consumed, a workload efficiency indicator.',
        avg_compilation_time_ms AS AVG(query_history.compilation_time)
            COMMENT 'Average compilation duration in milliseconds.',
        avg_total_elapsed_time_ms AS AVG(query_history.total_elapsed_time)
            COMMENT 'Average total elapsed time in milliseconds including queueing.'
    );

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
