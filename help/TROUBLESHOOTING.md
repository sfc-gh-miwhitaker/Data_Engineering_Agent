# Troubleshooting Guide

**Snowflake Intelligence Agent - Common Issues and Solutions**

This guide helps you diagnose and resolve common issues when deploying and using the Snowflake Intelligence Agent. Each issue includes symptoms, root causes, solutions, and prevention tips.

---

## Table of Contents

1. [Pre-Deployment Issues](#pre-deployment-issues)
2. [Deployment Failures](#deployment-failures)
3. [Post-Deployment Problems](#post-deployment-problems)
4. [Common Questions](#common-questions)
5. [Diagnostic Queries](#diagnostic-queries)
6. [Getting Additional Help](#getting-additional-help)

---

## Pre-Deployment Issues

### Issue 1: "Insufficient privileges to operate on account"

**Symptom:**
```
SQL compilation error: Insufficient privileges to operate on account
```

**Cause:** You are not running the script with `ACCOUNTADMIN` privileges.

**Solution:**
```sql
-- Switch to ACCOUNTADMIN role
USE ROLE ACCOUNTADMIN;

-- Verify your current role
SELECT CURRENT_ROLE();
-- Expected output: ACCOUNTADMIN
```

**Prevention:** Always verify you're using `ACCOUNTADMIN` before running the setup script.

---

### Issue 2: "Warehouse 'COMPUTE_WH' does not exist"

**Symptom:**
```
SQL execution error: Warehouse 'COMPUTE_WH' does not exist or not authorized
```

**Cause:** The warehouse specified in the configuration variables (line 49) doesn't exist in your account.

**Solution:**
```sql
-- List all available warehouses
SHOW WAREHOUSES;

-- Update the configuration variable to an existing warehouse
SET warehouse_name = 'YOUR_EXISTING_WAREHOUSE_NAME';

-- Or create a new warehouse
CREATE WAREHOUSE IF NOT EXISTS COMPUTE_WH 
    WITH WAREHOUSE_SIZE = 'X-SMALL' 
    AUTO_SUSPEND = 60 
    AUTO_RESUME = TRUE;
```

**Prevention:** Before deployment, verify the warehouse exists or create it first.

---

### Issue 3: "Cortex features are not enabled in this account"

**Symptom:**
```
SQL execution error: CORTEX_ENABLED_CROSS_REGION is not a valid account parameter
```
or
```
Database role SNOWFLAKE.CORTEX_USER does not exist
```

**Cause:** Snowflake Cortex features are not enabled in your account region.

**Solution:**

1. Verify your Snowflake account region and plan:
   ```sql
   SELECT CURRENT_REGION(), CURRENT_ACCOUNT();
   ```

2. Check if Cortex is available in your region: [Snowflake Cortex Availability](https://docs.snowflake.com/en/user-guide/snowflake-cortex/overview)

3. If unavailable, contact your Snowflake account team to enable Cortex or migrate to a supported region.

**Prevention:** Confirm Cortex availability in your region before starting deployment.

---

### Issue 4: "Cannot access marketplace listings"

**Symptom:**
```
SQL execution error: Listing 'GZSTZ67BY9OQ4' does not exist or not authorized
```

**Cause:** Network restrictions prevent accessing Snowflake Marketplace, or the listing ID has changed.

**Solution:**

1. Verify marketplace access:
   ```sql
   -- Try to list available marketplace listings
   SHOW LISTINGS IN DATA EXCHANGE;
   ```

2. Check firewall/network settings allow access to `*.snowflakecomputing.com`

3. Search for "Snowflake Documentation" in Snowflake Marketplace UI and note the correct listing ID

4. Update line 252 with the correct listing ID if changed

**Prevention:** Ensure outbound network access to Snowflake Marketplace is allowed.

---

## Deployment Failures

### Issue 5: "Insufficient privileges to create notification integration"

**Symptom:**
```
SQL access control error: Insufficient privileges to operate on NOTIFICATION INTEGRATION
```

**Cause:** SYSADMIN role cannot create notification integrations - only ACCOUNTADMIN can.

**Solution:**

The script automatically handles this by switching to ACCOUNTADMIN for notification integration creation. If you encounter this error:

1. Verify the script is being executed as written (lines 191-203)
2. Ensure you have ACCOUNTADMIN privileges:
   ```sql
   -- Check your granted roles
   SHOW GRANTS TO USER CURRENT_USER();
   
   -- Verify ACCOUNTADMIN access
   USE ROLE ACCOUNTADMIN;
   SELECT CURRENT_ROLE();
   ```

3. If you don't have ACCOUNTADMIN:
   - Ask your account administrator to run the notification integration section (lines 191-203)
   - OR remove the email functionality (comment out lines 191-245) and proceed without email features

**Prevention:** The script now includes proper role switching. No action needed if running the latest version (v2.3.1+).

---

### Issue 6: "Email integration creation fails"

**Symptom:**
```
SQL execution error: Email domain not allowed for notification integration
```

**Cause:** The email domain you specified (line 242) is not allow-listed in your Snowflake account.

**Solution:**

1. Contact your Snowflake account administrator to allow-list your email domain

2. Alternatively, use an already allowed domain:
   ```sql
   -- Check allowed email integration domains with your admin
   SHOW NOTIFICATION INTEGRATIONS;
   ```

3. Update line 242 with an allowed email address

4. Re-run the email integration section:
   ```sql
   USE ROLE ACCOUNTADMIN;
   
   CREATE OR REPLACE NOTIFICATION INTEGRATION email_integration
       TYPE = EMAIL
       ENABLED = TRUE
       DEFAULT_SUBJECT = 'Snowflake Intelligence';
   ```

**Prevention:** Coordinate with your account administrator to pre-approve email domains.

---

### Issue 6: "Semantic view creation error"

**Symptom:**
```
SQL compilation error: Invalid semantic view definition
```
or
```
Error in semantic view JSON extension
```

**Cause:** The semantic view definition JSON is malformed or contains invalid metadata.

**Solution:**

1. Verify the `ACCOUNT_USAGE` schema is accessible:
   ```sql
   USE ROLE ACCOUNTADMIN;
   SELECT COUNT(*) FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY LIMIT 1;
   ```

2. Check for data latency (ACCOUNT_USAGE has up to 45-minute latency):
   ```sql
   SELECT MAX(START_TIME) FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY;
   -- Should show recent timestamps
   ```

3. Re-run just the semantic view creation (lines 76-180 of setup script)

**Prevention:** Ensure `ACCOUNT_USAGE` access before deployment. Test with simple queries first.

---

### Issue 7: "Agent creation fails"

**Symptom:**
```
SQL compilation error: Agent specification is invalid
```

**Cause:** Agent JSON specification has syntax errors or references non-existent resources.

**Solution:**

1. Verify all dependencies exist before creating agent:
   ```sql
   -- Check semantic view exists
   SHOW SEMANTIC VIEWS IN DATABASE snowflake_intelligence;
   
   -- Check search service exists
   SHOW CORTEX SEARCH SERVICES IN DATABASE snowflake_documentation;
   
   -- Check stored procedure exists
   SHOW PROCEDURES LIKE 'send_email' IN SCHEMA snowflake_intelligence.tools;
   ```

2. If any dependency is missing, recreate it from the setup script

3. Ensure the warehouse specified in agent config exists:
   ```sql
   SHOW WAREHOUSES LIKE 'COMPUTE_WH';
   ```

4. Re-run the agent creation (lines 262-351 of setup script)

**Prevention:** Deploy dependencies first, then create the agent last.

---

## Post-Deployment Problems

### Issue 8: "Agent requires warehouse specification" or "Please specify a warehouse"

**Symptom:** Agent returns error: "Please specify a warehouse to run the query" when using Cortex Analyst or custom tools.

**Cause:** The agent specification didn't properly substitute the warehouse variable from the configuration.

**Solution:**

This was a bug in earlier versions where `${warehouse_name}` in JSON strings didn't get substituted. Fixed in v2.1.1+.

**If you deployed before the fix:**
1. Re-run the setup script (it's idempotent)
2. The agent will be recreated with proper warehouse specification
3. Test with: "What are my slowest queries today?"

**To verify the fix worked:**
```sql
-- Check agent specification includes warehouse
DESC AGENT snowflake_intelligence.agents.snowflake_assistant_v2;
-- Look for "warehouse": "COMPUTE_WH" in the tool_resources section
```

**Prevention:** Always use the latest version of the setup script from the repository.

---

### Issue 9: "Insufficient privileges to operate on warehouse 'SNOWFLAKE_INTELLIGENCE_WH'" or users cannot run agent

**Symptom:** Users get warehouse access errors when trying to use the agent, even though the agent exists and they have USAGE on it.

**Cause:** Users need USAGE privilege on the warehouse to run agent queries. Initial v2.2 release only granted warehouse access to SYSADMIN.

**Solution:**

As ACCOUNTADMIN, grant USAGE to PUBLIC:
```sql
USE ROLE ACCOUNTADMIN;
GRANT USAGE ON WAREHOUSE snowflake_intelligence_wh TO ROLE PUBLIC;
```

**Understanding the privileges:**
- **USAGE** (granted to PUBLIC): Allows using the warehouse when it's running
- **OPERATE** (granted to SYSADMIN only): Allows starting/stopping/resizing the warehouse
- Users get USAGE only = they can run agent queries but cannot manage the warehouse

**Verification:**
```sql
-- Check warehouse grants
SHOW GRANTS ON WAREHOUSE snowflake_intelligence_wh;
-- Should see: PUBLIC has USAGE, SYSADMIN has USAGE + OPERATE

-- Test as a regular user
USE ROLE PUBLIC;
-- Try using the agent - should now work
```

**Prevention:** This fix is included in v2.2.1+. If upgrading from v2.2.0, run the grant command above.

---

### Issue 9: "Agent doesn't respond to questions"

**Symptom:** Agent returns no results or timeout errors when asked questions.

**Cause:** Multiple possible causes - warehouse suspended, permissions issue, or agent misconfiguration.

**Solution:**

1. Verify the agent exists and is accessible:
   ```sql
   USE ROLE SYSADMIN;
   SHOW AGENTS IN DATABASE snowflake_intelligence;
   ```

2. Check warehouse is running:
   ```sql
   SHOW WAREHOUSES LIKE 'COMPUTE_WH';
   -- Check STATUS column shows "STARTED" or will auto-resume
   ```

3. Test semantic view directly:
   ```sql
   SELECT COUNT(*) 
   FROM snowflake_intelligence.tools.snowflake_query_history
   LIMIT 10;
   ```

4. Verify your user has access:
   ```sql
   -- Check grants
   SHOW GRANTS ON DATABASE snowflake_intelligence;
   SHOW GRANTS ON SCHEMA snowflake_intelligence.agents;
   ```

5. In Snowsight UI, navigate to AI & ML > Agents, select agent, and test with a simple question: "What is my account name?"

**Prevention:** Test agent immediately after deployment using the sample questions.

---

### Issue 10: "Cannot modify agent in Snowsight"

**Symptom:** Unable to edit agent configuration in Snowsight UI, or changes don't save.

**Cause:** Agent was created with static JSON specification instead of dynamic construction.

**Solution:**

This was fixed in v2.1.1 by using `OBJECT_CONSTRUCT()` instead of static JSON.

**To enable editing:**
1. Re-run the setup script (uses `IDENTIFIER($agent_spec)` approach)
2. Agent can now be modified in Snowsight UI
3. Changes will persist properly

**Workaround (if you can't redeploy):**
- Modify agent by dropping and recreating with new specification
- Use `CREATE OR REPLACE AGENT` with updated JSON

**Prevention:** Use the latest setup script which supports dynamic agent configuration.

---

### Issue 11: "Email notifications not sending"

**Symptom:** Agent executes but emails are not received.

**Cause:** Email integration not working, wrong email address, or email blocked by spam filters.

**Solution:**

1. Test email integration directly:
   ```sql
   CALL snowflake_intelligence.tools.send_email(
       'your.email@domain.com',
       'Test Email',
       '<h1>Test</h1><p>If you receive this, email integration works.</p>'
   );
   ```

2. Check spam/junk folders for Snowflake emails

3. Verify notification integration is enabled:
   ```sql
   SHOW NOTIFICATION INTEGRATIONS LIKE 'email_integration';
   -- Check ENABLED column is TRUE
   ```

4. Check for error messages in procedure execution history:
   ```sql
   SELECT *
   FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY())
   WHERE QUERY_TEXT ILIKE '%send_email%'
   ORDER BY START_TIME DESC
   LIMIT 10;
   ```

**Prevention:** Test email integration immediately after setup before relying on it.

---

### Issue 12: "Agent responses are slow"

**Symptom:** Agent takes more than 30 seconds to respond to simple questions.

**Cause:** Warehouse too small, semantic view scanning too much data, or network latency.

**Solution:**

1. Check warehouse size:
   ```sql
   SHOW WAREHOUSES LIKE 'COMPUTE_WH';
   -- If X-SMALL, consider upgrading to SMALL
   ```

2. Increase warehouse size for better performance:
   ```sql
   ALTER WAREHOUSE COMPUTE_WH SET WAREHOUSE_SIZE = 'SMALL';
   ```

3. Check query history data volume:
   ```sql
   SELECT 
       COUNT(*) as total_rows,
       MIN(START_TIME) as oldest_query,
       MAX(START_TIME) as newest_query
   FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY;
   ```

4. If millions of rows, consider adding filters to the semantic view to limit date range

5. Monitor agent query execution:
   ```sql
   -- View agent-generated queries
   SELECT 
       QUERY_TEXT,
       TOTAL_ELAPSED_TIME / 1000 as seconds,
       WAREHOUSE_SIZE
   FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
   WHERE QUERY_TAG LIKE '%cortex-agent%'
   ORDER BY START_TIME DESC
   LIMIT 10;
   ```

**Prevention:** Start with SMALL warehouse, monitor performance, adjust as needed.

---

## Common Questions

### Q1: How do I update the agent's instructions?

**Answer:** You need to drop and recreate the agent with new instructions:

```sql
USE ROLE SYSADMIN;
USE SCHEMA snowflake_intelligence.agents;

-- Drop existing agent
DROP AGENT snowflake_intelligence.agents.snowflake_assistant_v2;

-- Recreate with updated instructions (modify lines 262-351 from setup script)
CREATE OR REPLACE AGENT snowflake_intelligence.agents.snowflake_assistant_v2
WITH PROFILE = '{ "display_name": "Snowflake Assistant" }'
COMMENT = 'Updated agent with new instructions'
FROM SPECIFICATION $$
{
    "models": { "orchestration": "auto" },
    "instructions": {
        "response": "YOUR UPDATED RESPONSE INSTRUCTIONS",
        "orchestration": "YOUR UPDATED ORCHESTRATION INSTRUCTIONS"
    },
    -- ... rest of specification
}
$$;
```

---

### Q2: How do I change the email address?

**Answer:** 

1. For test emails, update line 242 in the setup script and re-run that section

2. For agent email tool default, update the `recipient_email` description in the agent specification (line 292-295)

3. For runtime changes, specify the email when asking the agent: "Send email to newaddress@domain.com"

---

### Q3: How do I grant access to other users?

**Answer:**

```sql
USE ROLE ACCOUNTADMIN;

-- Grant database and schema access
GRANT USAGE ON DATABASE snowflake_intelligence TO ROLE <target_role>;
GRANT USAGE ON SCHEMA snowflake_intelligence.agents TO ROLE <target_role>;

-- Grant access to use the agent (but not modify it)
GRANT USAGE ON AGENT snowflake_intelligence.agents.snowflake_assistant_v2 TO ROLE <target_role>;

-- Grant warehouse access for query execution
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE <target_role>;
```

---

### Q4: How do I completely remove the agent?

**Answer:** Use the provided `teardown_script.sql` for safe removal:

**The script implements a SAFE teardown that**:
- ✓ Removes ONLY project-specific objects (agents, semantic views, procedures)
- ✓ Preserves shared infrastructure (`snowflake_intelligence` database/schemas)
- ✓ Checks for other objects before removal
- ✓ Shows what remains after cleanup

```bash
# Review the teardown script first
cat teardown_script.sql

# Execute in Snowsight as SYSADMIN
# The script will check for other objects and preserve them
```

**For complete database removal** (if no other tools use it):
- See the commented section in the teardown script
- Only execute if checks confirm no other objects exist

---

### Q5: Can I have multiple agents?

**Answer:** Yes! Create additional agents with different names:

```sql
CREATE AGENT snowflake_intelligence.agents.custom_agent_name
WITH PROFILE = '{ "display_name": "Custom Agent" }'
FROM SPECIFICATION $$
{
    -- Your custom agent specification
}
$$;
```

Each agent can have different instructions, tools, and configurations.

---

## Diagnostic Queries

### Check Agent Health

```sql
-- View all agents in your account
SHOW AGENTS IN ACCOUNT;

-- Get agent details
DESC AGENT snowflake_intelligence.agents.snowflake_assistant_v2;

-- Check recent agent queries
SELECT 
    START_TIME,
    QUERY_TEXT,
    EXECUTION_STATUS,
    TOTAL_ELAPSED_TIME / 1000 as seconds,
    ERROR_MESSAGE
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE QUERY_TAG LIKE '%cortex-agent%'
ORDER BY START_TIME DESC
LIMIT 20;
```

### Check Resource Access

```sql
-- Verify semantic view access
SELECT COUNT(*) FROM snowflake_intelligence.tools.snowflake_query_history;

-- Verify documentation search service
SHOW CORTEX SEARCH SERVICES IN DATABASE snowflake_documentation;

-- Check email integration
SHOW NOTIFICATION INTEGRATIONS LIKE 'email%';
```

### Check Permissions

```sql
-- Check your current grants
SHOW GRANTS TO ROLE CURRENT_ROLE();

-- Check what roles can access the agent
SHOW GRANTS ON AGENT snowflake_intelligence.agents.snowflake_assistant_v2;

-- Check PUBLIC role grants (all users)
SHOW GRANTS TO ROLE PUBLIC;
```

### Performance Analysis

```sql
-- Analyze agent query performance
SELECT 
    DATE_TRUNC('hour', START_TIME) as hour,
    COUNT(*) as query_count,
    AVG(TOTAL_ELAPSED_TIME) / 1000 as avg_seconds,
    MAX(TOTAL_ELAPSED_TIME) / 1000 as max_seconds,
    SUM(CREDITS_USED_CLOUD_SERVICES) as total_credits
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE QUERY_TAG LIKE '%cortex-agent%'
    AND START_TIME >= DATEADD(day, -7, CURRENT_TIMESTAMP())
GROUP BY 1
ORDER BY 1 DESC;
```

---

## Getting Additional Help

### Snowflake Documentation

- **Cortex AI & ML**: https://docs.snowflake.com/en/user-guide/snowflake-cortex
- **Agents**: https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agent
- **Semantic Views**: https://docs.snowflake.com/en/user-guide/cortex-analyst
- **ACCOUNT_USAGE**: https://docs.snowflake.com/en/sql-reference/account-usage

### Community Support

- **Snowflake Community**: https://community.snowflake.com
- **Stack Overflow**: Tag questions with `snowflake-cloud-data-platform`

### Professional Support

- Contact your Snowflake account team
- Open a support case in the Snowflake Support Portal

---

## Reporting Issues

If you discover issues not covered in this guide:

1. Document the exact error message
2. Note the step in deployment where it occurred
3. Capture relevant diagnostic query results
4. Share in the project issues or Snowflake Community

**Note:** This is community-supported software. Use at your own risk.

