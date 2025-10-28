/*******************************************************************************
 * File: sql/teardown_script.sql
 * 
 * Synopsis:
 *   Complete teardown script for removing all Snowflake Intelligence Agent
 *   resources from your Snowflake account. This script performs an aggressive
 *   cleanup, including marketplace listings.
 * 
 * Description:
 *   This script safely removes all objects created by Snowflake_Assistant_setup.sql
 *   including the agent, semantic views, stored procedures, notification
 *   integrations, and databases. Execute this script to completely uninstall
 *   the Snowflake Intelligence Agent from your account.
 * 
 * ⚠️  WARNING: THIS SCRIPT IS DESTRUCTIVE ⚠️
 *   - All agent data and configurations will be permanently deleted
 *   - The marketplace documentation database will be removed
 *   - Email notification integration will be dropped
 *   - This action CANNOT be undone
 * 
 * Prerequisites:
 *   - ACCOUNTADMIN role privileges
 *   - Confirmation that you want to remove all components
 * 
 * Safety Notes:
 *   - Review each section carefully before execution
 *   - Consider running sections individually if you want to keep specific components
 *   - The script uses IF EXISTS to prevent errors if objects are already removed
 * 
 * Author: Snowflake Community
 * Version: 1.0
 * License: Apache 2.0
 * 
 * Usage:
 *   1. Review this entire script
 *   2. Ensure you have backups of any custom agent configurations
 *   3. Execute as ACCOUNTADMIN
 *   4. Verify removal with the validation queries at the end
 ******************************************************************************/

-- =============================================================================
-- SECTION 1: INITIAL SAFETY CHECK
-- =============================================================================
-- Uncomment the line below ONLY when you are certain you want to proceed
-- SET proceed_with_teardown = TRUE;

-- =============================================================================
-- SECTION 2: SET EXECUTION CONTEXT
-- =============================================================================

USE ROLE ACCOUNTADMIN;

-- Display current context for verification
SELECT 
    CURRENT_ROLE() as current_role,
    CURRENT_WAREHOUSE() as current_warehouse,
    CURRENT_TIMESTAMP() as teardown_timestamp;

-- =============================================================================
-- SECTION 3: DROP AGENT
-- =============================================================================
-- Remove the Snowflake Assistant agent

USE ROLE SYSADMIN;
USE SCHEMA snowflake_intelligence.agents;

DROP AGENT IF EXISTS snowflake_intelligence.agents.snowflake_assistant_v2;

-- Verify agent removal
SHOW AGENTS IN SCHEMA snowflake_intelligence.agents;
-- Expected: No agents should be listed

-- =============================================================================
-- SECTION 4: DROP TOOLS AND PROCEDURES
-- =============================================================================
-- Remove semantic views, stored procedures, and supporting objects

USE SCHEMA snowflake_intelligence.tools;

-- Drop the semantic view used by the agent
DROP SEMANTIC VIEW IF EXISTS snowflake_intelligence.tools.snowflake_query_history;

-- Drop the email notification stored procedure
DROP PROCEDURE IF EXISTS snowflake_intelligence.tools.send_email(VARCHAR, VARCHAR, VARCHAR);

-- Verify removal
SHOW SEMANTIC VIEWS IN SCHEMA snowflake_intelligence.tools;
-- Expected: No semantic views should be listed

SHOW PROCEDURES IN SCHEMA snowflake_intelligence.tools;
-- Expected: send_email procedure should not be listed

-- =============================================================================
-- SECTION 5: DROP NOTIFICATION INTEGRATION
-- =============================================================================
-- Remove email notification integration (requires ACCOUNTADMIN)

USE ROLE ACCOUNTADMIN;

DROP NOTIFICATION INTEGRATION IF EXISTS email_integration;

-- Verify removal
SHOW NOTIFICATION INTEGRATIONS LIKE 'email_integration';
-- Expected: No results

-- =============================================================================
-- SECTION 6: VERIFY DATABASE SAFETY
-- =============================================================================
-- Check if database contains other objects before considering removal
-- ⚠️  WARNING: snowflake_intelligence database may be shared with other tools

USE ROLE SYSADMIN;

-- List all objects in the database

-- Check for other schemas (beyond agents and tools)
SELECT 'Other schemas in database:' as check_type, COUNT(*) as count
FROM snowflake_intelligence.information_schema.schemata 
WHERE schema_name NOT IN ('AGENTS', 'TOOLS', 'INFORMATION_SCHEMA');

-- Check for other agents
-- Note: Must manually review SHOW AGENTS output
SHOW AGENTS IN DATABASE snowflake_intelligence;
-- Review the output above. If agents exist beyond SNOWFLAKE_ASSISTANT_V2 and SNOWFLAKE_ASSISTANT_ENHANCED, 
-- DO NOT drop the agents schema.

-- Check for other semantic views in tools schema
-- Note: Must manually review SHOW SEMANTIC VIEWS output
SHOW SEMANTIC VIEWS IN SCHEMA snowflake_intelligence.tools;
-- Review the output above. If semantic views exist beyond SNOWFLAKE_QUERY_HISTORY, QUERY_PERFORMANCE, 
-- COST_ANALYSIS, and WAREHOUSE_OPERATIONS, DO NOT drop the tools schema.

-- =============================================================================
-- ⚠️  IMPORTANT DECISION POINT ⚠️
-- =============================================================================
-- Based on the counts above:
-- - If OTHER schemas exist: DO NOT drop database, only drop our specific objects
-- - If OTHER agents exist: DO NOT drop agents schema
-- - If OTHER semantic views exist: DO NOT drop tools schema
--
-- This script will ONLY remove objects created by this project.
-- It will NOT remove the database or schemas if they contain other objects.
-- =============================================================================

-- =============================================================================
-- SAFE TEARDOWN: Removing only project-specific objects
-- =============================================================================

-- Remove only our semantic views (not the schema)
USE SCHEMA snowflake_intelligence.tools;

DROP SEMANTIC VIEW IF EXISTS snowflake_intelligence.tools.snowflake_query_history;
DROP SEMANTIC VIEW IF EXISTS snowflake_intelligence.tools.query_performance;
DROP SEMANTIC VIEW IF EXISTS snowflake_intelligence.tools.cost_analysis;
DROP SEMANTIC VIEW IF EXISTS snowflake_intelligence.tools.warehouse_operations;

-- Remove only our stored procedure
DROP PROCEDURE IF EXISTS snowflake_intelligence.tools.send_email(VARCHAR, VARCHAR, VARCHAR);

-- Remove only our agents (not the schema)
USE SCHEMA snowflake_intelligence.agents;

DROP AGENT IF EXISTS snowflake_intelligence.agents.snowflake_assistant_v2;
DROP AGENT IF EXISTS snowflake_intelligence.agents.snowflake_assistant_enhanced;

-- =============================================================================
-- OPTIONAL: COMPLETE DATABASE REMOVAL
-- =============================================================================
-- ⚠️  ONLY execute the following section IF:
-- 1. The checks above showed NO other objects in the database
-- 2. You are CERTAIN no other tools are using snowflake_intelligence database
-- 3. You want to completely remove the database
--
-- To execute this section, uncomment the lines below:
-- =============================================================================

-- USE ROLE SYSADMIN;
-- 
-- DROP SCHEMA IF EXISTS snowflake_intelligence.tools CASCADE;
-- DROP SCHEMA IF EXISTS snowflake_intelligence.agents CASCADE;
-- DROP DATABASE IF EXISTS snowflake_intelligence CASCADE;
-- 
-- SELECT 'Complete database removal executed' as status;

-- =============================================================================
-- SECTION 8: DROP MARKETPLACE DOCUMENTATION DATABASE
-- =============================================================================
-- Remove the Snowflake Documentation database imported from marketplace
-- ⚠️  WARNING: This removes access to the Snowflake documentation corpus

USE ROLE ACCOUNTADMIN;

DROP DATABASE IF EXISTS snowflake_documentation;

-- Verify removal
SHOW DATABASES LIKE 'snowflake_documentation';
-- Expected: No results

-- =============================================================================
-- SECTION 9: REVOKE GRANTS (CLEANUP)
-- =============================================================================
-- Clean up any remaining grants to PUBLIC role
-- Note: These commands may fail if objects are already removed - this is expected

USE ROLE ACCOUNTADMIN;

-- Revoke the Cortex user role grant from PUBLIC
-- (This is a database role, so we need to check if we should revoke it)
-- Commenting out by default as this affects all users in the account
-- REVOKE DATABASE ROLE SNOWFLAKE.CORTEX_USER FROM ROLE PUBLIC;

-- Note: Since we're dropping the databases, the grants are automatically revoked

-- =============================================================================
-- SECTION 10: FINAL VALIDATION
-- =============================================================================
-- Verify removal of project-specific components


-- Check that our semantic views are removed
SHOW SEMANTIC VIEWS IN SCHEMA snowflake_intelligence.tools;
-- ✓ PASS if no results show: SNOWFLAKE_QUERY_HISTORY, QUERY_PERFORMANCE, COST_ANALYSIS, WAREHOUSE_OPERATIONS

-- Check that our agents are removed
SHOW AGENTS IN DATABASE snowflake_intelligence;
-- ✓ PASS if no results show: SNOWFLAKE_ASSISTANT_V2, SNOWFLAKE_ASSISTANT_ENHANCED

-- Check that our stored procedure is removed
SHOW PROCEDURES IN SCHEMA snowflake_intelligence.tools;
-- ✓ PASS if SEND_EMAIL is not in the results

-- Check for any remaining notification integrations
SHOW NOTIFICATION INTEGRATIONS LIKE 'email_integration';
-- ✓ PASS if no results

-- Check for any remaining documentation databases
SHOW DATABASES LIKE 'snowflake_documentation';
-- INFO: If this still exists, it may be used by other tools

-- Show remaining objects in snowflake_intelligence (if any)

SHOW SCHEMAS IN DATABASE snowflake_intelligence;
SHOW AGENTS IN DATABASE snowflake_intelligence;
SHOW SEMANTIC VIEWS IN SCHEMA snowflake_intelligence.tools;
SHOW PROCEDURES IN SCHEMA snowflake_intelligence.tools;

-- =============================================================================
-- SECTION 11: ROLLBACK INFORMATION
-- =============================================================================
-- If you need to restore the agent after teardown:
-- 
-- BASIC AGENT (snowflake_assistant_v2):
-- 1. Re-run the original Snowflake_Assistant_setup.sql script
-- 2. This will recreate all components from scratch
-- 3. You will need to:
--    - Re-configure the email address
--    - Re-accept marketplace legal terms (if documentation database was removed)
--    - Re-import the documentation database (if removed)
--    - Verify all grants are properly applied
-- 
-- ENHANCED AGENT (snowflake_assistant_enhanced):
-- 1. Re-run sql/deploy_enhanced_agent.sql
-- 2. This will recreate the enhanced agent with domain-specific semantic views
-- 
-- Note: There is no automated rollback. You must re-deploy from the setup scripts.

-- =============================================================================
-- TEARDOWN COMPLETE
-- =============================================================================

SELECT 
    '=== TEARDOWN COMPLETE ===' as status,
    CURRENT_TIMESTAMP() as completed_at,
    'All Snowflake Intelligence Agent components have been removed' as message;

/*******************************************************************************
 * SAFE TEARDOWN SUMMARY
 * 
 * This script implements a SAFE teardown approach that:
 * 
 * ✓ REMOVES ONLY project-specific objects:
 *   - Our semantic views (snowflake_query_history, query_performance, cost_analysis, warehouse_operations)
 *   - Our agents (snowflake_assistant_v2, snowflake_assistant_enhanced)
 *   - Our stored procedure (send_email)
 *   - Our notification integration (email_integration)
 *   - Marketplace documentation database (snowflake_documentation)
 * 
 * ✓ PRESERVES shared infrastructure:
 *   - snowflake_intelligence database (if other tools use it)
 *   - agents schema (if other agents exist)
 *   - tools schema (if other semantic views exist)
 * 
 * ⚠️  COMPLETE REMOVAL (Optional):
 *   - See commented section in SECTION 6 if you want to remove database entirely
 *   - Only execute if checks confirm no other objects exist
 * 
 * PARTIAL TEARDOWN OPTIONS:
 * - Keep marketplace documentation: Comment out SECTION 8
 * - Keep email integration: Comment out SECTION 5
 * - Keep database/schemas: Already implemented as default behavior
 * 
 * Always review and test teardowns in a non-production environment first.
 ******************************************************************************/

