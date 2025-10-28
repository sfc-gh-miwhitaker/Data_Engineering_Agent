# Testing and Validation Guide

**Snowflake Intelligence Agent - Deployment Validation Procedures**

This guide provides comprehensive testing procedures to validate your Snowflake Intelligence Agent deployment. Follow these steps to ensure all components are working correctly before production use.

---

## Table of Contents

1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [Deployment Validation](#deployment-validation)
3. [Functional Testing](#functional-testing)
4. [Performance Benchmarks](#performance-benchmarks)
5. [Email Integration Testing](#email-integration-testing)
6. [User Access Testing](#user-access-testing)
7. [Rollback Procedures](#rollback-procedures)
8. [Success Criteria](#success-criteria)

---

## Pre-Deployment Checklist

Before executing the `sql/01_Snowflake_Assistant_setup.sql` script, verify all prerequisites are met:

### ✓ Account Prerequisites

- [ ] `ACCOUNTADMIN` role access confirmed
- [ ] Snowflake Cortex features available in your region
- [ ] Network access to Snowflake Marketplace enabled
- [ ] Email domain allow-listed for notification integrations

**Validation Queries:**

```sql
-- 1. Verify you have ACCOUNTADMIN access
USE ROLE ACCOUNTADMIN;
SELECT CURRENT_ROLE() as role;
-- Expected: ACCOUNTADMIN

-- 2. Verify Cortex features are available
SHOW DATABASE ROLES IN DATABASE SNOWFLAKE LIKE 'CORTEX%';
-- Expected: CORTEX_USER role visible

-- 3. Check account region
SELECT CURRENT_REGION(), CURRENT_ACCOUNT();
-- Verify region supports Cortex: https://docs.snowflake.com/en/user-guide/snowflake-cortex/overview
```

### ✓ Configuration Review

- [ ] Reviewed setup script configuration variables (line 48)
- [ ] Warehouse name updated (or confirmed `COMPUTE_WH` exists)
- [ ] Email address updated in test call (line 259)
- [ ] Understood all objects that will be created

**Validation Queries:**

```sql
-- Verify target warehouse exists
SHOW WAREHOUSES LIKE 'COMPUTE_WH';
-- Expected: At least one warehouse visible

-- Check if warehouse is accessible
USE WAREHOUSE COMPUTE_WH;
SELECT CURRENT_WAREHOUSE();
-- Expected: COMPUTE_WH
```

### ✓ Environment Readiness

- [ ] Sufficient credits available in account
- [ ] No conflicting `snowflake_intelligence` database exists
- [ ] Backup of any existing configurations completed

**Validation Queries:**

```sql
-- Check for existing conflicting databases
SHOW DATABASES LIKE 'snowflake_intelligence';
-- Expected: No results (if deploying fresh)

SHOW DATABASES LIKE 'snowflake_documentation';
-- Expected: No results (if deploying fresh)
```

---

## Deployment Validation

After executing the setup script, validate that all components were created successfully.

### Step 1: Verify Databases Created

```sql
USE ROLE SYSADMIN;

-- Check snowflake_intelligence database
SHOW DATABASES LIKE 'snowflake_intelligence';
-- ✓ PASS: Database exists, owned by SYSADMIN

-- Check snowflake_documentation database
SHOW DATABASES LIKE 'snowflake_documentation';
-- ✓ PASS: Database exists (marketplace import)
```

**Success Criteria:** Both databases visible with proper ownership.

---

### Step 2: Verify Schemas Created

```sql
USE ROLE SYSADMIN;

-- Check schemas in snowflake_intelligence
SHOW SCHEMAS IN DATABASE snowflake_intelligence;
-- ✓ PASS: Should see 'AGENTS' and 'TOOLS' schemas
```

**Expected Output:**
| name | database_name | owner |
|------|---------------|-------|
| AGENTS | SNOWFLAKE_INTELLIGENCE | SYSADMIN |
| TOOLS | SNOWFLAKE_INTELLIGENCE | SYSADMIN |

---

### Step 3: Verify Semantic View

```sql
USE ROLE SYSADMIN;

-- Check semantic view exists
SHOW SEMANTIC VIEWS IN DATABASE snowflake_intelligence;
-- ✓ PASS: snowflake_query_history visible

-- Test semantic view data access
SELECT COUNT(*) as row_count
FROM snowflake_intelligence.tools.snowflake_query_history
LIMIT 10;
-- ✓ PASS: Query executes without error (count may vary)

-- Verify semantic view has recent data
SELECT 
    MAX(START_TIME) as most_recent_query,
    COUNT(*) as total_queries
FROM snowflake_intelligence.tools.snowflake_query_history;
-- ✓ PASS: most_recent_query shows recent timestamp
```

**Success Criteria:** Semantic view exists, accessible, and returns query history data.

---

### Step 4: Verify Notification Integration

```sql
USE ROLE ACCOUNTADMIN;

-- Check email integration exists
SHOW NOTIFICATION INTEGRATIONS LIKE 'email_integration';
-- ✓ PASS: email_integration visible with ENABLED = TRUE
```

**Expected Output:**
| name | type | enabled |
|------|------|---------|
| EMAIL_INTEGRATION | EMAIL | true |

---

### Step 5: Verify Stored Procedure

```sql
USE ROLE SYSADMIN;

-- Check send_email procedure exists
SHOW PROCEDURES LIKE 'send_email' IN SCHEMA snowflake_intelligence.tools;
-- ✓ PASS: send_email(VARCHAR, VARCHAR, VARCHAR) visible

-- Describe the procedure
DESC PROCEDURE snowflake_intelligence.tools.send_email(VARCHAR, VARCHAR, VARCHAR);
-- ✓ PASS: Procedure details returned
```

**Success Criteria:** Stored procedure exists and is callable.

---

### Step 6: Verify Cortex Search Service

```sql
USE ROLE ACCOUNTADMIN;

-- Check documentation search service exists
SHOW CORTEX SEARCH SERVICES IN DATABASE snowflake_documentation;
-- ✓ PASS: CKE_SNOWFLAKE_DOCS_SERVICE visible

-- Note: Search service is provided by marketplace, not directly queryable
```

**Success Criteria:** Cortex Search service visible in documentation database.

---

### Step 7: Verify Agent Created

```sql
USE ROLE SYSADMIN;

-- Check agent exists
SHOW AGENTS IN DATABASE snowflake_intelligence;
-- ✓ PASS: snowflake_assistant_v2 visible

-- Get agent details
DESC AGENT snowflake_intelligence.agents.snowflake_assistant_v2;
-- ✓ PASS: Agent specification returned
```

**Expected Output:**
| name | display_name | comment |
|------|--------------|---------|
| SNOWFLAKE_ASSISTANT_V2 | Snowflake Assistant | AI-powered Snowflake Cost and Performance Assistant... |

---

### Step 8: Verify Grants

```sql
USE ROLE ACCOUNTADMIN;

-- Check PUBLIC role has access
SHOW GRANTS TO ROLE PUBLIC;
-- ✓ PASS: Should see USAGE grants on snowflake_intelligence and snowflake_documentation

-- Specifically check database grants
SHOW GRANTS ON DATABASE snowflake_intelligence;
-- ✓ PASS: PUBLIC has USAGE

SHOW GRANTS ON DATABASE snowflake_documentation;
-- ✓ PASS: PUBLIC has IMPORTED PRIVILEGES
```

**Success Criteria:** PUBLIC role can access (but not modify) all deployed resources.

---

## Functional Testing

Test the agent's core functionality with progressively complex queries.

### Test 1: Basic Agent Response

**Test Query:** "What is my account name?"

**How to Test:**
1. Navigate to Snowsight UI
2. Go to AI & ML > Agents
3. Select `snowflake_assistant_v2`
4. Enter test query in chat interface

**Expected Behavior:**
- Agent responds within 5-10 seconds
- Agent returns your Snowflake account name
- No error messages

**✓ PASS Criteria:** Agent responds correctly with account information.

---

### Test 2: Query History Analysis

**Test Query:** "What were my top 5 slowest queries today?"

**Expected Behavior:**
- Agent queries the semantic view
- Returns list of queries with execution times
- Provides query IDs and elapsed time metrics

**Validation Query:**
```sql
-- Manually verify agent's response
SELECT 
    QUERY_ID,
    TOTAL_ELAPSED_TIME / 1000 as seconds,
    QUERY_TEXT
FROM snowflake_intelligence.tools.snowflake_query_history
WHERE START_TIME >= CURRENT_DATE()
ORDER BY TOTAL_ELAPSED_TIME DESC
LIMIT 5;
```

**✓ PASS Criteria:** Agent response matches manual query results.

---

### Test 3: Warehouse Analysis

**Test Query:** "Which warehouses should be upgraded to Gen 2?"

**Expected Behavior:**
- Agent analyzes warehouse configurations
- References Snowflake documentation for Gen 2 features
- Provides specific warehouse recommendations

**✓ PASS Criteria:** Agent provides actionable recommendations with reasoning.

---

### Test 4: Error Troubleshooting

**Test Query:** "Show me queries with compilation errors and how to fix them"

**Expected Behavior:**
- Agent identifies queries with error codes
- Provides error messages
- Searches documentation for solutions

**Validation Query:**
```sql
-- Verify error queries exist
SELECT 
    QUERY_ID,
    ERROR_CODE,
    ERROR_MESSAGE
FROM snowflake_intelligence.tools.snowflake_query_history
WHERE ERROR_CODE IS NOT NULL
    AND START_TIME >= DATEADD(day, -7, CURRENT_DATE())
LIMIT 10;
```

**✓ PASS Criteria:** Agent identifies errors and provides relevant guidance.

---

### Test 5: Documentation Search

**Test Query:** "How do I configure Query Acceleration Service?"

**Expected Behavior:**
- Agent searches Snowflake documentation corpus
- Returns relevant documentation snippets
- Provides links to official documentation

**✓ PASS Criteria:** Agent returns accurate documentation references.

---

### Test 6: Complex Analysis

**Test Query:** "Based on my top 10 slowest queries, can you provide ways to optimize them?"

**Expected Behavior:**
- Agent identifies slowest queries from semantic view
- Analyzes query patterns (bytes scanned, partitions, etc.)
- Searches documentation for optimization techniques
- Provides specific recommendations

**Expected Response Time:** 15-30 seconds (complex multi-tool query)

**✓ PASS Criteria:** Agent provides comprehensive optimization recommendations.

---

## Performance Benchmarks

Measure agent performance against expected baselines.

### Benchmark 1: Simple Query Response Time

**Test:** "What is my account name?"

| Metric | Target | Acceptable | Needs Investigation |
|--------|--------|------------|---------------------|
| Response Time | < 5 sec | 5-10 sec | > 10 sec |
| Tokens Generated | 50-100 | 100-200 | > 200 |

**Measurement:**
```sql
-- Check recent agent query times
SELECT 
    QUERY_TEXT,
    TOTAL_ELAPSED_TIME / 1000 as seconds
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE QUERY_TAG LIKE '%cortex-agent%'
    AND START_TIME >= DATEADD(minute, -10, CURRENT_TIMESTAMP())
ORDER BY START_TIME DESC;
```

---

### Benchmark 2: Semantic View Query Response Time

**Test:** "Show me my slowest queries today"

| Metric | Target | Acceptable | Needs Investigation |
|--------|--------|------------|---------------------|
| Response Time | < 10 sec | 10-20 sec | > 20 sec |
| Data Scanned | < 100MB | 100-500MB | > 500MB |

---

### Benchmark 3: Documentation Search Response Time

**Test:** "How do I enable clustering?"

| Metric | Target | Acceptable | Needs Investigation |
|--------|--------|------------|---------------------|
| Response Time | < 8 sec | 8-15 sec | > 15 sec |
| Results Returned | 3-5 docs | 5-10 docs | > 10 docs |

---

### Benchmark 4: Complex Multi-Tool Query

**Test:** "Based on my top 10 slowest queries, can you provide ways to optimize them?"

| Metric | Target | Acceptable | Needs Investigation |
|--------|--------|------------|---------------------|
| Response Time | < 20 sec | 20-40 sec | > 40 sec |
| Tools Used | 2-3 | 3-4 | > 4 |

---

## Email Integration Testing

Validate email notification functionality.

### Test 1: Direct Stored Procedure Call

```sql
USE ROLE SYSADMIN;

-- Test email procedure directly
CALL snowflake_intelligence.tools.send_email(
    'your.email@domain.com',
    'Snowflake Intelligence - Direct Test',
    '<h1>Direct Test</h1><p>This email was sent directly via stored procedure.</p><p>Timestamp: ' || CURRENT_TIMESTAMP()::VARCHAR || '</p>'
);
```

**✓ PASS Criteria:**
- Procedure executes without error
- Email received within 2-5 minutes
- HTML formatting preserved

---

### Test 2: Agent-Triggered Email

**Test Query:** "Send email to me summarizing the top 3 slowest queries today"

**Expected Behavior:**
- Agent analyzes queries
- Formats results as HTML
- Calls email procedure
- Confirms email sent

**✓ PASS Criteria:**
- Agent confirms email sent
- Email received with query summary
- Email content is well-formatted and accurate

---

### Test 3: Email Error Handling

```sql
-- Test with invalid email format
CALL snowflake_intelligence.tools.send_email(
    'invalid-email-format',
    'Test Subject',
    '<p>Test body</p>'
);
```

**Expected Behavior:**
- Procedure returns error message
- Error is handled gracefully
- No system crash

**✓ PASS Criteria:** Error handled with clear message.

---

## User Access Testing

Verify different roles can access the agent appropriately.

### Test 1: PUBLIC Role Access

```sql
-- Switch to PUBLIC role (or create test user)
USE ROLE PUBLIC;

-- Verify can see agent
SHOW AGENTS IN DATABASE snowflake_intelligence;
-- ✓ PASS: Agent visible

-- Test agent usage (in Snowsight UI as PUBLIC-level user)
-- Query: "What is my account name?"
-- ✓ PASS: Agent responds
```

---

### Test 2: Non-Admin Role Cannot Modify

```sql
USE ROLE PUBLIC;

-- Attempt to drop agent (should fail)
DROP AGENT snowflake_intelligence.agents.snowflake_assistant_v2;
-- ✓ PASS: Error - insufficient privileges
```

**Expected Error:**
```
SQL access control error: Insufficient privileges to operate on agent
```

---

### Test 3: Custom Role Access

```sql
USE ROLE ACCOUNTADMIN;

-- Create test role
CREATE ROLE IF NOT EXISTS test_agent_user;

-- Grant necessary access
GRANT USAGE ON DATABASE snowflake_intelligence TO ROLE test_agent_user;
GRANT USAGE ON SCHEMA snowflake_intelligence.agents TO ROLE test_agent_user;
GRANT USAGE ON AGENT snowflake_intelligence.agents.snowflake_assistant_v2 TO ROLE test_agent_user;
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE test_agent_user;

-- Test as new role
USE ROLE test_agent_user;
SHOW AGENTS IN SCHEMA snowflake_intelligence.agents;
-- ✓ PASS: Agent accessible
```

---

## Rollback Procedures

If deployment fails or issues are detected, follow these rollback steps.

### Scenario 1: Partial Deployment Failure

**If deployment fails mid-script:**

1. Identify where failure occurred (check error message)
2. Use diagnostic queries to see what was created:
   ```sql
   SHOW DATABASES LIKE 'snowflake%';
   SHOW AGENTS IN ACCOUNT;
   SHOW NOTIFICATION INTEGRATIONS;
   ```
3. Execute relevant sections of `sql/03_teardown_script.sql` to remove partial deployment
4. Fix configuration issue
5. Re-run complete `sql/01_Snowflake_Assistant_setup.sql`

---

### Scenario 2: Agent Not Working Properly

**If agent is deployed but not functioning:**

1. Do NOT immediately tear down
2. Use troubleshooting guide to diagnose issue
3. Check logs:
   ```sql
   SELECT *
   FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY())
   WHERE QUERY_TAG LIKE '%cortex-agent%'
   ORDER BY START_TIME DESC;
   ```
4. If configuration error, drop and recreate agent only:
   ```sql
   DROP AGENT snowflake_intelligence.agents.snowflake_assistant_v2;
   -- Then recreate with corrected specification
   ```

---

### Scenario 3: Complete Rollback Required

**If deployment must be completely removed:**

1. Review `sql/03_teardown_script.sql` thoroughly
2. Execute teardown script as ACCOUNTADMIN
3. Verify complete removal with validation queries in teardown script
4. Document lessons learned
5. When ready, re-deploy with corrections

---

## Success Criteria

Use this checklist to confirm successful deployment:

### ✅ Deployment Success Checklist

- [ ] All databases created (snowflake_intelligence, snowflake_documentation)
- [ ] All schemas created (agents, tools)
- [ ] Semantic view accessible and returning data
- [ ] Stored procedure executable
- [ ] Notification integration enabled
- [ ] Agent created and visible
- [ ] PUBLIC role can access agent
- [ ] Agent responds to basic queries < 10 seconds
- [ ] Agent can analyze query history
- [ ] Agent can search documentation
- [ ] Email integration sends test email successfully
- [ ] Agent can trigger email notifications
- [ ] Performance benchmarks meet acceptable thresholds
- [ ] No errors in recent query history

### ✅ Production Readiness Checklist

- [ ] All functional tests pass
- [ ] Performance benchmarks acceptable
- [ ] User access tested and working
- [ ] Email notifications reliable
- [ ] Troubleshooting guide reviewed
- [ ] Rollback procedures documented and tested
- [ ] Monitoring queries documented
- [ ] Team trained on agent usage
- [ ] Escalation procedures established
- [ ] Cost monitoring in place

---

## Continuous Testing

After successful deployment, implement ongoing testing:

### Daily Health Check

```sql
-- Run daily to verify agent health
SELECT 
    'Agent Query Count' as metric,
    COUNT(*) as value,
    CASE WHEN COUNT(*) > 0 THEN 'HEALTHY' ELSE 'CHECK REQUIRED' END as status
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE QUERY_TAG LIKE '%cortex-agent%'
    AND START_TIME >= DATEADD(day, -1, CURRENT_TIMESTAMP());
```

### Weekly Performance Review

```sql
-- Review weekly performance trends
SELECT 
    DATE_TRUNC('day', START_TIME) as day,
    COUNT(*) as queries,
    AVG(TOTAL_ELAPSED_TIME) / 1000 as avg_seconds,
    SUM(CREDITS_USED_CLOUD_SERVICES) as credits
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE QUERY_TAG LIKE '%cortex-agent%'
    AND START_TIME >= DATEADD(week, -1, CURRENT_TIMESTAMP())
GROUP BY 1
ORDER BY 1;
```

---

## Support and Feedback

If you encounter issues during testing:

1. Consult the `TROUBLESHOOTING.md` guide
2. Review Snowflake documentation
3. Share findings in project issues or Snowflake Community

**Remember:** This is community-supported software. Thorough testing in your environment is critical before production use.

