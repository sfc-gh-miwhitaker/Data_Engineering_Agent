# Pre-Deployment Checklist

**Version**: 2.3  
**Last Updated**: 2025-10-17

## Required Configuration Changes

Before running `Snowflake_Assistant_setup.sql`, verify these configurations:

### 1. Configuration Variables (Line 48)
- [ ] `SET role_name = 'SYSADMIN';` - Confirm target role (default: SYSADMIN)

**Note**: The agent uses the user's current warehouse context - no dedicated warehouse needed.

### 2. Email Configuration (Line 241)
- [ ] Replace `YOUR_EMAIL_ADDRESS@EMAILDOMAIN.COM` with valid email address
- [ ] Confirm email domain is allow-listed in Snowflake notification settings
- [ ] Test email delivery after deployment

### 3. Prerequisites Verification
- [ ] ACCOUNTADMIN role access confirmed
- [ ] Cortex features enabled in account
- [ ] Network access for Marketplace listings enabled
- [ ] Users have access to at least one warehouse

## Deployment Steps

1. [ ] Review and update configuration variables
2. [ ] Execute entire script in Snowsight as ACCOUNTADMIN
3. [ ] Verify test email received
4. [ ] Test agent with sample query
5. [ ] Review security grants align with organizational policies

## Post-Deployment Validation

Run these commands to verify successful deployment:

```sql
-- Verify database and schemas exist
SHOW DATABASES LIKE 'snowflake_intelligence';
SHOW SCHEMAS IN DATABASE snowflake_intelligence;

-- Verify semantic view
SHOW SEMANTIC VIEWS IN DATABASE snowflake_intelligence;

-- Verify agent
SHOW AGENTS IN DATABASE snowflake_intelligence;

-- Verify documentation database
SHOW CORTEX SEARCH SERVICES IN DATABASE snowflake_documentation;

-- Test the agent
-- Navigate to AI & ML > Agents in Snowsight
-- Select snowflake_assistant_v2
-- Ask: "What were my top 5 slowest queries today?"
```

## Security Review Checklist

- [x] Uses SYSADMIN role (not ACCOUNTADMIN) for object creation
- [x] PUBLIC granted USAGE only (no ownership rights)
- [x] SQL injection protection in Python procedure
- [x] All user inputs properly escaped
- [x] ACCOUNTADMIN used only where required:
  - Account-level settings (CORTEX_ENABLED_CROSS_REGION)
  - Database role grants (SNOWFLAKE.CORTEX_USER)
  - Marketplace operations (legal terms, database import)
- [x] Agent uses user's warehouse context (no dedicated warehouse = simpler permissions)
- [x] All sensitive values documented as configuration variables

## Code Quality Standards Met

- [x] Apache 2.0 LICENSE file created
- [x] Comprehensive file header with author, version, usage
- [x] All SQL keywords UPPERCASE
- [x] All identifiers lowercase_snake_case
- [x] Clear inline comments throughout
- [x] Security considerations documented in README
- [x] Idempotent script (safe to re-run)
- [x] All placeholders clearly marked and documented

## Support Information

**License:** Apache 2.0  
**Support:** Community-supported  
**Original Author:** Kaitlyn Wells (@snowflake)  
**Modified:** 2025-10-17  
**Version:** 2.3

## Additional Resources

- `help/TESTING.md` - Comprehensive testing procedures
- `help/TROUBLESHOOTING.md` - Common issues and solutions
- `help/ENHANCED_AGENT_README.md` - Enhanced agent deployment guide

