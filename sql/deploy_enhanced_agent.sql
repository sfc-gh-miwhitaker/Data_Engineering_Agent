/*******************************************************************************
 * File: sql/deploy_enhanced_agent.sql
 * 
 * Synopsis:
 *   Complete deployment script for enhanced Snowflake Intelligence Agent
 *   with domain-specific semantic views.
 * 
 * Description:
 *   This script deploys the enhanced agent configuration as an upgrade to
 *   the existing Snowflake Assistant. It creates three specialized semantic
 *   views (query_performance, cost_analysis, warehouse_operations) and a
 *   new agent that leverages them for improved natural language understanding.
 * 
 * Prerequisites:
 *   - Base Snowflake Intelligence Agent already deployed (Snowflake_Assistant_setup.sql)
 *   - SYSADMIN role privileges
 *   - Existing snowflake_intelligence database and schemas
 *   - User must have an active warehouse (agent uses user's warehouse context)
 * 
 * What This Script Does:
 *   1. Creates three domain-specific semantic views
 *   2. Creates enhanced agent with specialized tools
 *   3. Grants access to PUBLIC role
 *   4. Validates deployment
 *   5. Keeps original agent for comparison
 * 
 * Configuration:
 *   Line 47: SET role_name (default: SYSADMIN)
 *   Note: Agent uses user's warehouse context automatically
 * 
 * Author: Snowflake Community
 * Modified: 2025-10-17
 * Version: 2.3
 * License: Apache 2.0
 * 
 * Usage:
 *   Execute this entire script as ACCOUNTADMIN or SYSADMIN
 ******************************************************************************/

-- =============================================================================
-- SECTION 1: CONFIGURATION
-- =============================================================================

USE ROLE ACCOUNTADMIN;

-- Configuration variables
SET role_name = 'SYSADMIN';

-- Switch to execution role
USE ROLE identifier($role_name);
USE SCHEMA snowflake_intelligence.tools;

-- Display configuration
SELECT 
    CURRENT_ROLE() as role,
    CURRENT_WAREHOUSE() as warehouse,
    CURRENT_DATABASE() as database,
    CURRENT_SCHEMA() as schema,
    CURRENT_TIMESTAMP() as deployment_time;

-- =============================================================================
-- SECTION 2: CREATE ENHANCED SEMANTIC VIEWS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- SEMANTIC VIEW 1: query_performance
-- -----------------------------------------------------------------------------

-- Note: System-managed warehouses (SYSTEM$STREAMLIT_NOTEBOOK_WH) are filtered in agent instructions
CREATE OR REPLACE SEMANTIC VIEW snowflake_intelligence.tools.query_performance
TABLES (
    SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY,
    SNOWFLAKE.ACCOUNT_USAGE.QUERY_ATTRIBUTION_HISTORY
)
FACTS (
  QUERY_HISTORY.BYTES_SCANNED as BYTES_SCANNED comment='The total number of bytes scanned by the query.',
  QUERY_HISTORY.BYTES_SPILLED_TO_LOCAL_STORAGE as BYTES_SPILLED_TO_LOCAL_STORAGE comment='Memory spillage to local storage indicating memory pressure. Synonyms: local spill, disk spill.',
  QUERY_HISTORY.BYTES_SPILLED_TO_REMOTE_STORAGE as BYTES_SPILLED_TO_REMOTE_STORAGE comment='Memory spillage to remote storage indicating severe memory pressure. Synonyms: remote spill, S3 spill.',
  QUERY_HISTORY.COMPILATION_TIME as COMPILATION_TIME comment='Query compilation time in milliseconds. Synonyms: parse time, planning time.',
  QUERY_HISTORY.EXECUTION_TIME as EXECUTION_TIME comment='Query execution time in milliseconds. Synonyms: runtime, run time, processing time.',
  QUERY_HISTORY.TOTAL_ELAPSED_TIME as TOTAL_ELAPSED_TIME comment='Total query duration in milliseconds. Synonyms: duration, total time, wall time.',
  QUERY_HISTORY.QUEUED_OVERLOAD_TIME as QUEUED_OVERLOAD_TIME comment='Queue wait time due to load in milliseconds. Synonyms: wait time, queue time.',
  QUERY_HISTORY.QUEUED_PROVISIONING_TIME as QUEUED_PROVISIONING_TIME comment='Queue wait time for provisioning in milliseconds. Synonyms: startup wait, cold start time.',
  QUERY_HISTORY.ROWS_PRODUCED as ROWS_PRODUCED comment='Number of rows returned. Synonyms: result rows, output rows, rows returned.',
  QUERY_HISTORY.PARTITIONS_SCANNED as PARTITIONS_SCANNED comment='Number of micro-partitions scanned. Synonyms: partitions read, micro-partitions.',
  QUERY_HISTORY.PARTITIONS_TOTAL as PARTITIONS_TOTAL comment='Total partitions in queried tables.',
  QUERY_HISTORY.PERCENTAGE_SCANNED_FROM_CACHE as PERCENTAGE_SCANNED_FROM_CACHE comment='Cache hit rate percentage. Synonyms: cache hit, cache efficiency.',
  QUERY_ATTRIBUTION_HISTORY.CREDITS_ATTRIBUTED_COMPUTE as CREDITS_ATTRIBUTED_COMPUTE comment='Compute credits for this query. Synonyms: query cost, compute cost.'
)
DIMENSIONS (
  QUERY_HISTORY.QUERY_ID as QUERY_ID comment='Unique query identifier. Synonyms: query UUID.',
  QUERY_HISTORY.QUERY_TEXT as QUERY_TEXT comment='SQL statement text. Synonyms: SQL, query statement.',
  QUERY_HISTORY.QUERY_TYPE as QUERY_TYPE comment='Query type (SELECT, INSERT, UPDATE, DDL, etc.).',
  QUERY_HISTORY.EXECUTION_STATUS as EXECUTION_STATUS comment='Query status: SUCCESS, FAILED, RUNNING. Synonyms: query status.',
  QUERY_HISTORY.ERROR_CODE as ERROR_CODE comment='Error code for failed queries.',
  QUERY_HISTORY.ERROR_MESSAGE as ERROR_MESSAGE comment='Error description. Synonyms: failure reason.',
  QUERY_HISTORY.START_TIME as START_TIME comment='Query start timestamp. Synonyms: begin time, execution start.',
  QUERY_HISTORY.END_TIME as END_TIME comment='Query end timestamp. Synonyms: completion time, finish time.',
  QUERY_HISTORY.USER_NAME as USER_NAME comment='Executing user. Synonyms: username, query user.',
  QUERY_HISTORY.ROLE_NAME as ROLE_NAME comment='Execution role. Synonyms: query role.',
  QUERY_HISTORY.WAREHOUSE_NAME as WAREHOUSE_NAME comment='Warehouse used (system-managed warehouses excluded). Synonyms: compute cluster, virtual warehouse.',
  QUERY_HISTORY.WAREHOUSE_SIZE as WAREHOUSE_SIZE comment='Warehouse size (X-Small to 6X-Large).',
  QUERY_HISTORY.DATABASE_NAME as DATABASE_NAME comment='Database name. Synonyms: database, db.',
  QUERY_HISTORY.SCHEMA_NAME as SCHEMA_NAME comment='Schema name.'
)
COMMENT = 'Query performance metrics, errors, and optimization insights. Ask about slow queries, errors, and optimization opportunities. Excludes system-managed warehouses for clarity.'
WITH EXTENSION (CA = '{"verified_queries":[{"name":"Slowest queries today","question":"What were my slowest queries today?","sql":"SELECT query_id, query_text, total_elapsed_time, warehouse_name FROM query_performance WHERE start_time >= CURRENT_DATE() ORDER BY total_elapsed_time DESC LIMIT 10"}]}');


-- -----------------------------------------------------------------------------
-- SEMANTIC VIEW 2: cost_analysis
-- -----------------------------------------------------------------------------

-- Note: System-managed warehouses (SYSTEM$STREAMLIT_NOTEBOOK_WH) are filtered in agent instructions
CREATE OR REPLACE SEMANTIC VIEW snowflake_intelligence.tools.cost_analysis
TABLES (
    SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
)
FACTS (
  WAREHOUSE_METERING_HISTORY.CREDITS_USED as CREDITS_USED comment='Total credits consumed. Synonyms: cost, spend, warehouse cost.',
  WAREHOUSE_METERING_HISTORY.CREDITS_USED_COMPUTE as CREDITS_USED_COMPUTE comment='Compute credits. Synonyms: compute cost.',
  WAREHOUSE_METERING_HISTORY.CREDITS_USED_CLOUD_SERVICES as CREDITS_USED_CLOUD_SERVICES comment='Cloud services credits. Synonyms: services cost.'
)
DIMENSIONS (
  WAREHOUSE_METERING_HISTORY.WAREHOUSE_NAME as WAREHOUSE_NAME comment='Warehouse name (system-managed warehouses excluded). Synonyms: compute cluster.',
  WAREHOUSE_METERING_HISTORY.WAREHOUSE_ID as WAREHOUSE_ID comment='Warehouse identifier.',
  WAREHOUSE_METERING_HISTORY.START_TIME as START_TIME comment='Billing period start. Synonyms: period start, metering start.',
  WAREHOUSE_METERING_HISTORY.END_TIME as END_TIME comment='Billing period end. Synonyms: period end, metering end.'
)
COMMENT = 'Warehouse cost analysis and credit consumption tracking. Ask about costs, spend trends, and expensive warehouses. Excludes system-managed warehouses for clarity.'
WITH EXTENSION (CA = '{"verified_queries":[{"name":"Most expensive warehouses last month","question":"What were my most expensive warehouses last month?","sql":"SELECT warehouse_name, SUM(credits_used) as total_credits FROM cost_analysis WHERE start_time >= DATE_TRUNC(MONTH, DATEADD(MONTH, -1, CURRENT_DATE())) AND start_time < DATE_TRUNC(MONTH, CURRENT_DATE()) GROUP BY warehouse_name ORDER BY total_credits DESC"}]}');


-- -----------------------------------------------------------------------------
-- SEMANTIC VIEW 3: warehouse_operations
-- -----------------------------------------------------------------------------

-- Note: System-managed warehouses (SYSTEM$STREAMLIT_NOTEBOOK_WH) are filtered in agent instructions
CREATE OR REPLACE SEMANTIC VIEW snowflake_intelligence.tools.warehouse_operations
TABLES (
    SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY
)
FACTS (
  WAREHOUSE_LOAD_HISTORY.AVG_RUNNING as AVG_RUNNING comment='Average concurrent queries. Synonyms: concurrency, active queries.',
  WAREHOUSE_LOAD_HISTORY.AVG_QUEUED_LOAD as AVG_QUEUED_LOAD comment='Average queued queries. Synonyms: queue depth, waiting queries.',
  WAREHOUSE_LOAD_HISTORY.AVG_QUEUED_PROVISIONING as AVG_QUEUED_PROVISIONING comment='Average provisioning queue. Synonyms: startup queue.',
  WAREHOUSE_LOAD_HISTORY.AVG_BLOCKED as AVG_BLOCKED comment='Average blocked queries. Synonyms: contentions.'
)
DIMENSIONS (
  WAREHOUSE_LOAD_HISTORY.WAREHOUSE_NAME as WAREHOUSE_NAME comment='Warehouse name (system-managed warehouses excluded). Synonyms: compute cluster.',
  WAREHOUSE_LOAD_HISTORY.WAREHOUSE_ID as WAREHOUSE_ID comment='Warehouse identifier.',
  WAREHOUSE_LOAD_HISTORY.START_TIME as START_TIME comment='Measurement period start. Synonyms: load start time.',
  WAREHOUSE_LOAD_HISTORY.END_TIME as END_TIME comment='Measurement period end. Synonyms: load end time.'
)
COMMENT = 'Warehouse utilization and capacity planning metrics. Ask about warehouse sizing, queue times, and utilization patterns. Excludes system-managed warehouses for clarity.'
WITH EXTENSION (CA = '{"verified_queries":[{"name":"Warehouses with high queues","question":"Which warehouses have the most queued queries?","sql":"SELECT warehouse_name, AVG(avg_queued_load) as avg_queue_depth FROM warehouse_operations WHERE start_time >= DATEADD(DAY, -7, CURRENT_TIMESTAMP()) GROUP BY warehouse_name HAVING avg_queue_depth > 0 ORDER BY avg_queue_depth DESC"}]}');


-- =============================================================================
-- SECTION 3: CREATE ENHANCED AGENT
-- =============================================================================


USE SCHEMA snowflake_intelligence.agents;

-- Create enhanced agent with dedicated warehouse
CREATE OR REPLACE AGENT snowflake_intelligence.agents.snowflake_assistant_enhanced
WITH PROFILE = '{ "display_name": "Snowflake Assistant (Enhanced)" }'
COMMENT = 'Enhanced AI-powered agent with domain-specific semantic views for performance, cost, and capacity analysis'
FROM SPECIFICATION $$
{
    "models": { "orchestration": "auto" },
    "instructions": {
        "response": "You are a Snowflake Data Engineer Assistant. Provide specific recommendations with clear next steps, actual metrics, prioritized solutions, and Snowflake best practices.",
        "orchestration": "TOOL SELECTION:\n- query_performance: slow queries, errors, optimization, performance issues, execution metrics\n- cost_analysis: costs, spend, credits, budget, expensive queries, FinOps\n- warehouse_operations: sizing, queues, utilization, capacity, concurrency\n- snowflake_knowledge_ext_documentation: features, best practices, how-to guides\n- cortex_email_tool: send reports via email\n\nFILTERING RULES:\n- ALWAYS filter out system-managed warehouses: WAREHOUSE_NAME != 'SYSTEM$STREAMLIT_NOTEBOOK_WH'\n- NEVER include SYSTEM$STREAMLIT_NOTEBOOK_WH in analysis or recommendations\n- Users cannot control system-managed warehouses\n\nAlways cite specific metrics. Prioritize by business impact.",
        "sample_questions": [
            { "question": "What are my top 10 slowest queries and how can I optimize them?" },
            { "question": "Which warehouses are costing me the most money?" },
            { "question": "Are my warehouses properly sized based on queue times?" },
            { "question": "Show me queries with errors and how to fix them" }
        ]
    },
    "tools": [
        { "tool_spec": { "name": "query_performance", "type": "cortex_analyst_text_to_sql", "description": "Analyze query performance, errors, and optimization. Use for: slow queries, errors, execution times, cache efficiency, spilling, partitions." } },
        { "tool_spec": { "name": "cost_analysis", "type": "cortex_analyst_text_to_sql", "description": "Track warehouse costs and credit consumption. Use for: costs, spend, credits, budget, expensive queries, trends." } },
        { "tool_spec": { "name": "warehouse_operations", "type": "cortex_analyst_text_to_sql", "description": "Monitor warehouse utilization and capacity. Use for: sizing, queues, utilization, over/under-provisioning, capacity planning." } },
        { "tool_spec": { "name": "snowflake_knowledge_ext_documentation", "type": "cortex_search", "description": "Search Snowflake documentation for best practices and features." } },
        { "tool_spec": { "name": "cortex_email_tool", "type": "generic", "description": "Send analysis reports via email.", "input_schema": { "type": "object", "properties": { "body": { "type": "string", "description": "HTML email body" }, "recipient_email": { "type": "string", "description": "Recipient email address" }, "subject": { "type": "string", "description": "Email subject" } }, "required": ["body", "recipient_email", "subject"] } } }
    ],
    "tool_resources": {
        "query_performance": { "semantic_view": "snowflake_intelligence.tools.query_performance" },
        "cost_analysis": { "semantic_view": "snowflake_intelligence.tools.cost_analysis" },
        "warehouse_operations": { "semantic_view": "snowflake_intelligence.tools.warehouse_operations" },
        "snowflake_knowledge_ext_documentation": { "id_column": "SOURCE_URL", "title_column": "DOCUMENT_TITLE", "max_results": 10, "name": "SNOWFLAKE_DOCUMENTATION.SHARED.CKE_SNOWFLAKE_DOCS_SERVICE" },
        "cortex_email_tool": { "identifier": "snowflake_intelligence.tools.send_email", "name": "SEND_EMAIL(VARCHAR, VARCHAR, VARCHAR)", "type": "procedure", "execution_environment": { "type": "warehouse" } }
    }
}
$$;

-- =============================================================================
-- SECTION 4: GRANT ACCESS
-- =============================================================================

-- Grant agent access to PUBLIC role (allows all users to use the enhanced agent)
-- 
-- CUSTOMIZATION: To restrict access to a specific team:
--   Replace PUBLIC with your custom role name
--   Example: GRANT USAGE ON AGENT ... TO ROLE DATA_ENGINEERING_TEAM;
--   This limits enhanced agent access to only members of that role
GRANT USAGE ON AGENT snowflake_intelligence.agents.snowflake_assistant_enhanced TO ROLE PUBLIC;

-- =============================================================================
-- SECTION 5: VERIFICATION
-- =============================================================================


-- Check semantic views (should show 4 total: original + 3 enhanced)
SHOW SEMANTIC VIEWS IN SCHEMA snowflake_intelligence.tools;

-- Check agents (should see both original and enhanced)
SHOW AGENTS IN DATABASE snowflake_intelligence;

-- Note: Semantic views cannot be queried directly with SQL
-- They are designed to be used by Cortex Analyst (the agent's text-to-SQL tool)
-- Test them by asking the agent questions like:
--   "What are my slowest queries today?"
--   "Which warehouses are costing the most?"
--   "Show me warehouses with high queue times"

-- =============================================================================
-- DEPLOYMENT COMPLETE
-- =============================================================================
--
-- Next Steps:
-- 1. Navigate to Snowsight: AI & ML > Agents
-- 2. Select "Snowflake Assistant (Enhanced)"
-- 3. Test with sample questions (see below)
--
-- You now have TWO agents for comparison:
-- - snowflake_assistant_v2 (original, single semantic view)
-- - snowflake_assistant_enhanced (new, three domain-specific views)
-- =============================================================================

/*
SAMPLE QUESTIONS TO TEST:

Performance Analysis:
- "What are my slowest queries today?"
- "Show me queries that spilled to disk"
- "Which queries have low cache hit rates?"

Cost Analysis:
- "What's my total spend this month?"
- "Which warehouse costs the most?"
- "Show me cost trends by warehouse"

Capacity Planning:
- "Which warehouses have high queue times?"
- "Is COMPUTE_WH over-provisioned?"
- "Show me warehouse utilization patterns"

Cross-Domain:
- "Analyze my most expensive queries and recommend optimizations"
- "Which over-provisioned warehouses can save me money?"
*/

