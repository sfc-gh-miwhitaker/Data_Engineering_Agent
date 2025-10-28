# Role-Based Access Control

**Snowflake Intelligence Agent - Restricting Access to Specific Teams**

This guide explains how to limit agent access to specific roles/teams instead of making it available to all users (PUBLIC).

---

## Table of Contents

1. [Overview](#overview)
2. [Default Behavior](#default-behavior)
3. [Restricting to a Specific Role](#restricting-to-a-specific-role)
4. [Step-by-Step Instructions](#step-by-step-instructions)
5. [Use Cases](#use-cases)
6. [Verification](#verification)
7. [Troubleshooting](#troubleshooting)

---

## Overview

By default, the Snowflake Intelligence Agent is deployed with **PUBLIC** role access, meaning all users in your Snowflake account can see and use the agent. However, you may want to restrict access to:

- A specific team (e.g., Data Engineering team only)
- A department (e.g., Analytics team only)
- A project group (e.g., Cost optimization team only)
- Users with specific privileges

This is accomplished by replacing `PUBLIC` with your custom role in the deployment grants.

---

## Default Behavior

**Default Deployment**: Agent accessible to all users

```sql
-- Default grants (PUBLIC = all users)
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE PUBLIC;
GRANT USAGE ON DATABASE snowflake_intelligence TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA snowflake_intelligence.agents TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA snowflake_intelligence.tools TO ROLE PUBLIC;
GRANT IMPORTED PRIVILEGES ON DATABASE snowflake_documentation TO ROLE PUBLIC;
```

**Who can use the agent**: All users in the Snowflake account

**Visibility**: Agent appears in Snowsight AI & ML > Agents for all users

---

## Restricting to a Specific Role

**Custom Deployment**: Agent accessible only to specific role members

```sql
-- Example: Restrict to DATA_ENGINEERING_TEAM role
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE DATA_ENGINEERING_TEAM;
GRANT USAGE ON DATABASE snowflake_intelligence TO ROLE DATA_ENGINEERING_TEAM;
GRANT USAGE ON SCHEMA snowflake_intelligence.agents TO ROLE DATA_ENGINEERING_TEAM;
GRANT USAGE ON SCHEMA snowflake_intelligence.tools TO ROLE DATA_ENGINEERING_TEAM;
GRANT IMPORTED PRIVILEGES ON DATABASE snowflake_documentation TO ROLE DATA_ENGINEERING_TEAM;
```

**Who can use the agent**: Only users with the `DATA_ENGINEERING_TEAM` role

**Visibility**: Agent only appears for users who have the custom role

---

## Step-by-Step Instructions

### Option 1: Modify Before Deployment (Recommended)

If you haven't deployed yet, modify the script before running:

1. **Open `sql/Snowflake_Assistant_setup.sql`**

2. **Find all PUBLIC grants** (search for "GRANT" and "PUBLIC"):
   - Line ~53: `GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE PUBLIC;`
   - Line ~73: `GRANT USAGE ON DATABASE snowflake_intelligence TO ROLE PUBLIC;`
   - Line ~74: `GRANT USAGE ON SCHEMA snowflake_intelligence.agents TO ROLE PUBLIC;`
   - Line ~75: `GRANT USAGE ON SCHEMA snowflake_intelligence.tools TO ROLE PUBLIC;`
   - Line ~272: `GRANT IMPORTED PRIVILEGES ON DATABASE snowflake_documentation TO ROLE PUBLIC;`

3. **Replace all PUBLIC with your custom role**:
   ```sql
   -- Before:
   GRANT USAGE ON DATABASE snowflake_intelligence TO ROLE PUBLIC;
   
   -- After:
   GRANT USAGE ON DATABASE snowflake_intelligence TO ROLE YOUR_CUSTOM_ROLE;
   ```

4. **Run the modified script** as ACCOUNTADMIN

5. **Verify** (see Verification section below)

### Option 2: Modify After Deployment

If you've already deployed with PUBLIC access:

1. **Revoke PUBLIC grants**:
   ```sql
   USE ROLE ACCOUNTADMIN;
   
   REVOKE DATABASE ROLE SNOWFLAKE.CORTEX_USER FROM ROLE PUBLIC;
   REVOKE USAGE ON DATABASE snowflake_intelligence FROM ROLE PUBLIC;
   REVOKE USAGE ON SCHEMA snowflake_intelligence.agents FROM ROLE PUBLIC;
   REVOKE USAGE ON SCHEMA snowflake_intelligence.tools FROM ROLE PUBLIC;
   REVOKE IMPORTED PRIVILEGES ON DATABASE snowflake_documentation FROM ROLE PUBLIC;
   ```

2. **Grant to your custom role**:
   ```sql
   GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE YOUR_CUSTOM_ROLE;
   GRANT USAGE ON DATABASE snowflake_intelligence TO ROLE YOUR_CUSTOM_ROLE;
   GRANT USAGE ON SCHEMA snowflake_intelligence.agents TO ROLE YOUR_CUSTOM_ROLE;
   GRANT USAGE ON SCHEMA snowflake_intelligence.tools TO ROLE YOUR_CUSTOM_ROLE;
   GRANT IMPORTED PRIVILEGES ON DATABASE snowflake_documentation TO ROLE YOUR_CUSTOM_ROLE;
   ```

3. **Verify** (see Verification section below)

### Enhanced Agent (Optional)

If using the enhanced agent (`sql/deploy_enhanced_agent.sql`), also update:

```sql
-- Find this line (around line 210):
GRANT USAGE ON AGENT snowflake_intelligence.agents.snowflake_assistant_enhanced TO ROLE PUBLIC;

-- Replace with:
GRANT USAGE ON AGENT snowflake_intelligence.agents.snowflake_assistant_enhanced TO ROLE YOUR_CUSTOM_ROLE;
```

---

## Use Cases

### Use Case 1: Data Engineering Team Only

**Scenario**: Only the Data Engineering team should access query optimization insights

**Role**: `DATA_ENGINEERING_TEAM`

**Implementation**:
```sql
-- Replace all PUBLIC grants with:
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE DATA_ENGINEERING_TEAM;
GRANT USAGE ON DATABASE snowflake_intelligence TO ROLE DATA_ENGINEERING_TEAM;
GRANT USAGE ON SCHEMA snowflake_intelligence.agents TO ROLE DATA_ENGINEERING_TEAM;
GRANT USAGE ON SCHEMA snowflake_intelligence.tools TO ROLE DATA_ENGINEERING_TEAM;
GRANT IMPORTED PRIVILEGES ON DATABASE snowflake_documentation TO ROLE DATA_ENGINEERING_TEAM;
```

**Result**: Only users who have been granted `DATA_ENGINEERING_TEAM` role can see and use the agent

---

### Use Case 2: Cost Optimization Project Team

**Scenario**: A specific project team working on cost reduction initiatives

**Role**: `COST_OPT_PROJECT_TEAM`

**Implementation**:
```sql
-- First, create the role if it doesn't exist
USE ROLE USERADMIN;
CREATE ROLE IF NOT EXISTS COST_OPT_PROJECT_TEAM;

-- Grant to specific users
GRANT ROLE COST_OPT_PROJECT_TEAM TO USER alice@company.com;
GRANT ROLE COST_OPT_PROJECT_TEAM TO USER bob@company.com;

-- Then deploy agent with this role instead of PUBLIC
USE ROLE ACCOUNTADMIN;
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE COST_OPT_PROJECT_TEAM;
-- ... (rest of grants)
```

---

### Use Case 3: Multiple Teams with Different Agents

**Scenario**: Deploy multiple agents for different teams

**Implementation**:

1. **Main agent for Data Engineering**:
   ```sql
   -- Deploy sql/Snowflake_Assistant_setup.sql with DATA_ENGINEERING role
   GRANT USAGE ON AGENT snowflake_intelligence.agents.snowflake_assistant_v2 
       TO ROLE DATA_ENGINEERING_TEAM;
   ```

2. **Enhanced agent for Analytics**:
   ```sql
   -- Deploy deploy_enhanced_agent.sql with ANALYTICS role
   GRANT USAGE ON AGENT snowflake_intelligence.agents.snowflake_assistant_enhanced 
       TO ROLE ANALYTICS_TEAM;
   ```

**Result**: Each team has their own agent instance

---

## Verification

### Check Grants

```sql
USE ROLE ACCOUNTADMIN;

-- Check database grants
SHOW GRANTS ON DATABASE snowflake_intelligence;

-- Check schema grants
SHOW GRANTS ON SCHEMA snowflake_intelligence.agents;
SHOW GRANTS ON SCHEMA snowflake_intelligence.tools;

-- Check agent grants
SHOW GRANTS ON AGENT snowflake_intelligence.agents.snowflake_assistant_v2;

-- Check Cortex role grants
SHOW GRANTS OF DATABASE ROLE SNOWFLAKE.CORTEX_USER;

-- Check documentation grants
SHOW GRANTS ON DATABASE snowflake_documentation;
```

### Test Access

**As a user WITH the custom role**:
1. Switch to the custom role: `USE ROLE YOUR_CUSTOM_ROLE;`
2. Navigate to Snowsight: AI & ML > Agents
3. You should see "Snowflake Assistant"
4. Test a question: "What are my slowest queries today?"

**As a user WITHOUT the custom role**:
1. Switch to a different role: `USE ROLE PUBLIC;`
2. Navigate to Snowsight: AI & ML > Agents
3. You should NOT see "Snowflake Assistant"
4. Attempting to use the agent should fail with permission error

---

## Troubleshooting

### Issue 1: "Agent not visible in Snowsight"

**Symptom**: User with custom role cannot see the agent

**Possible Causes**:
1. User doesn't actually have the custom role granted
2. Missing schema/database grants
3. User needs to refresh Snowsight or switch roles

**Solution**:
```sql
-- Verify user has the role
SHOW GRANTS TO USER username;

-- Grant the role if missing
USE ROLE USERADMIN;
GRANT ROLE YOUR_CUSTOM_ROLE TO USER username;

-- Verify all necessary grants are in place
USE ROLE ACCOUNTADMIN;
SHOW GRANTS ON DATABASE snowflake_intelligence;
SHOW GRANTS ON SCHEMA snowflake_intelligence.agents;
```

---

### Issue 2: "Insufficient privileges" when using agent

**Symptom**: Agent appears but fails when asking questions

**Possible Causes**:
1. Missing Cortex role grant
2. Missing warehouse access
3. Missing documentation database access

**Solution**:
```sql
USE ROLE ACCOUNTADMIN;

-- Ensure Cortex access
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE YOUR_CUSTOM_ROLE;

-- Ensure documentation access
GRANT IMPORTED PRIVILEGES ON DATABASE snowflake_documentation TO ROLE YOUR_CUSTOM_ROLE;

-- Verify user has warehouse access
SHOW GRANTS TO ROLE YOUR_CUSTOM_ROLE;
```

---

### Issue 3: "Need to grant to multiple roles"

**Scenario**: Want agent accessible to multiple teams (but not PUBLIC)

**Solution**:
```sql
-- Grant to multiple specific roles
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE DATA_ENGINEERING_TEAM;
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE ANALYTICS_TEAM;
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE FINANCE_TEAM;

GRANT USAGE ON DATABASE snowflake_intelligence TO ROLE DATA_ENGINEERING_TEAM;
GRANT USAGE ON DATABASE snowflake_intelligence TO ROLE ANALYTICS_TEAM;
GRANT USAGE ON DATABASE snowflake_intelligence TO ROLE FINANCE_TEAM;

-- Repeat for all necessary grants
```

**Alternative**: Create a parent role:
```sql
-- Create a parent role
CREATE ROLE IF NOT EXISTS INTELLIGENCE_AGENT_USERS;

-- Grant agent access to parent role
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE INTELLIGENCE_AGENT_USERS;
-- ... (rest of grants)

-- Grant parent role to team roles
GRANT ROLE INTELLIGENCE_AGENT_USERS TO ROLE DATA_ENGINEERING_TEAM;
GRANT ROLE INTELLIGENCE_AGENT_USERS TO ROLE ANALYTICS_TEAM;
GRANT ROLE INTELLIGENCE_AGENT_USERS TO ROLE FINANCE_TEAM;
```

---

## Security Best Practices

### Principle of Least Privilege

1. **Only grant to roles that need it**: Don't use PUBLIC unless everyone truly needs access
2. **Use role hierarchies**: Create parent roles for common access patterns
3. **Regular audits**: Review grants periodically

### Audit Logging

```sql
-- Track who's using the agent
SELECT 
    user_name,
    role_name,
    query_text,
    start_time
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE query_text ILIKE '%snowflake_assistant%'
ORDER BY start_time DESC
LIMIT 100;
```

### Separation of Duties

- **ACCOUNTADMIN**: Deploys the agent
- **SYSADMIN**: Manages agent (configured via $role_name)
- **Custom Role**: Uses the agent
- **USERADMIN**: Grants custom role to users

---

## Summary

**Default**: Agent accessible to all users (PUBLIC)

**Customized**: Agent accessible only to specific role members

**Steps**: Replace all PUBLIC grants with your custom role name

**Location**: Lines marked with "CUSTOMIZATION" or "NOTE" in deployment scripts

**Verification**: Use `SHOW GRANTS` commands and test with/without the role

---

**Need Help?** See `help/TROUBLESHOOTING.md` for additional support.

