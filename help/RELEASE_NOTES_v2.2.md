# Snowflake Intelligence Agent - Version 2.2 Release Notes

**Release Date**: October 17, 2025  
**Version**: 2.2

## What's New

### 🎯 Dedicated Warehouse - Simplified Configuration

**Major Improvement**: Eliminated warehouse configuration complexity by creating a dedicated warehouse automatically.

**What Changed**:
- ✅ **Auto-created warehouse**: `snowflake_intelligence_wh` (X-SMALL, 60s auto-suspend)
- ✅ **No variable substitution**: Removes complex `EXECUTE IMMEDIATE` workarounds
- ✅ **Simpler deployment**: One less configuration variable to set
- ✅ **Cost-optimized**: X-Small size with aggressive 60s suspend for minimal cost
- ✅ **Workload isolation**: Agent queries don't compete with other workloads
- ✅ **Editable in Snowsight**: Agent configuration now fully modifiable in UI

**Benefits**:
1. **Cleaner code**: Direct JSON specification (no string concatenation)
2. **Better UX**: Users don't need to specify warehouse name
3. **Predictable costs**: Known warehouse size and auto-suspend behavior
4. **Easier troubleshooting**: Consistent execution environment
5. **Best practice alignment**: Workload isolation for agent operations

### 📝 Updated Files

#### Main Setup Script
- **Snowflake_Assistant_setup.sql**
  - Removed `SET warehouse_name = 'COMPUTE_WH';` configuration variable
  - Added warehouse creation block (lines 53-65)
  - Simplified agent creation using direct JSON (no EXECUTE IMMEDIATE)
  - Updated header documentation

#### Enhanced Agent Deployment
- **sql/deploy_enhanced_agent.sql**
  - Removed warehouse_name variable
  - Simplified agent creation
  - Uses dedicated warehouse

#### Teardown Script
- **teardown_script.sql**
  - Added `DROP WAREHOUSE IF EXISTS snowflake_intelligence_wh;`

#### Documentation
- **README.md**
  - Updated prerequisites to mention auto-created warehouse
- **deployment_checklist.md**
  - Removed warehouse configuration requirement
  - Added warehouse verification step
  - Updated security checklist

## Migration Guide

### For New Deployments
Simply run the updated script - warehouse will be created automatically. No additional configuration needed.

### For Existing Deployments

#### Option 1: Use Dedicated Warehouse (Recommended)
```sql
-- Create the dedicated warehouse
CREATE WAREHOUSE IF NOT EXISTS snowflake_intelligence_wh
WITH
    WAREHOUSE_SIZE = 'X-SMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;

-- Grant access
GRANT USAGE, OPERATE ON WAREHOUSE snowflake_intelligence_wh TO ROLE SYSADMIN;

-- Re-run agent creation (lines 266-353 from updated script)
-- This will update the agent to use the new warehouse
```

#### Option 2: Keep Current Configuration
Your existing agent will continue to work with your current warehouse. The dedicated warehouse approach is optional but recommended for the benefits listed above.

## Technical Details

### Warehouse Specification
```sql
CREATE WAREHOUSE IF NOT EXISTS snowflake_intelligence_wh
WITH
    WAREHOUSE_SIZE = 'X-SMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
COMMENT = 'Dedicated warehouse for Snowflake Intelligence Agent operations';
```

**Cost Estimate**: Approximately $0.0016 per credit-second × actual usage. With 60s auto-suspend, typical cost is negligible for agent workloads (a few cents per day for normal usage).

### Why X-SMALL?
- Agent queries are typically lightweight analytical queries
- 60s auto-suspend ensures warehouse is rarely idle
- Can be manually upgraded if performance needs increase
- Follows Snowflake's "start small, scale as needed" principle

## Compatibility

- ✅ **Backwards Compatible**: Existing deployments continue to work
- ✅ **No Breaking Changes**: Just removes configuration requirement
- ✅ **Idempotent**: Can re-run script safely

## Bug Fixes from v2.1

- 🐛 Fixed variable size limit error with `OBJECT_CONSTRUCT()` approach
- 🐛 Fixed agent not editable in Snowsight interface
- 🐛 Fixed "agent requires warehouse specification" error for tools
- 🐛 Fixed users unable to access warehouse (added PUBLIC USAGE grant)
- 🐛 Fixed `QUERY_BYTES_SCANNED` invalid identifier error in cost_analysis semantic view

## What's Next

- Consider deploying the **Enhanced Agent** (optional) for better performance
  - See `sql/` directory for domain-specific semantic views
  - Improved natural language understanding with synonyms
  - Faster queries with focused semantic models

---

**Questions or Issues?**
- Review `TROUBLESHOOTING.md` for common problems
- Check `deployment_checklist.md` for prerequisites
- Review security considerations in `README.md`

**License**: Apache 2.0  
**Support**: Community-supported
