# Enhancement Recommendations

**Snowflake Intelligence Agent - Potential Improvements**

This document provides recommendations for enhancing the Snowflake Intelligence Agent based on Snowflake best practices and additional context available in `ACCOUNT_USAGE` views. These recommendations are optional and can be implemented based on your specific use cases.

---

## Table of Contents

1. [Overview](#overview)
2. [Additional ACCOUNT_USAGE Tables](#additional-account_usage-tables)
3. [Enhanced Semantic View](#enhanced-semantic-view)
4. [Join Strategy Recommendations](#join-strategy-recommendations)
5. [Implementation Examples](#implementation-examples)
6. [Performance Considerations](#performance-considerations)
7. [Use Case Scenarios](#use-case-scenarios)

---

## Overview

The current Snowflake Intelligence Agent uses two primary `ACCOUNT_USAGE` tables:
- `QUERY_HISTORY` - Query execution metrics
- `QUERY_ATTRIBUTION_HISTORY` - Credit attribution details

This provides excellent query performance analysis, but additional tables can enrich the agent's context for more comprehensive insights.

---

## Additional ACCOUNT_USAGE Tables

### 1. WAREHOUSE_METERING_HISTORY

**Purpose:** Track credit consumption by warehouse over time

**Key Columns:**
- `WAREHOUSE_ID` - Links to queries
- `WAREHOUSE_NAME` - Warehouse identifier
- `START_TIME` / `END_TIME` - Metering period
- `CREDITS_USED` - Total credits consumed
- `CREDITS_USED_COMPUTE` - Compute credits
- `CREDITS_USED_CLOUD_SERVICES` - Cloud services credits

**Benefits:**
- Identify expensive warehouses
- Track cost trends over time
- Correlate query performance with warehouse costs
- Support warehouse right-sizing recommendations

**Join Pattern:**
```sql
LEFT JOIN SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY wm
  ON qh.WAREHOUSE_ID = wm.WAREHOUSE_ID
  AND wm.START_TIME <= qh.START_TIME
  AND wm.END_TIME >= qh.END_TIME
```

**Agent Questions Enabled:**
- "What is the total cost of queries on COMPUTE_WH this month?"
- "Which warehouse consumed the most credits last week?"
- "Show me credit trends for all warehouses over the last 30 days"

---

### 2. WAREHOUSE_LOAD_HISTORY

**Purpose:** Monitor warehouse queue and load metrics

**Key Columns:**
- `WAREHOUSE_ID` - Links to queries
- `WAREHOUSE_NAME` - Warehouse identifier
- `START_TIME` / `END_TIME` - Measurement period
- `AVG_RUNNING` - Average running queries
- `AVG_QUEUED_LOAD` - Average queued queries
- `AVG_QUEUED_PROVISIONING` - Average provisioning queue
- `AVG_BLOCKED` - Average blocked queries

**Benefits:**
- Identify over-provisioned warehouses (low utilization)
- Identify under-provisioned warehouses (high queuing)
- Support warehouse sizing recommendations
- Detect contention patterns

**Join Pattern:**
```sql
LEFT JOIN SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY wl
  ON qh.WAREHOUSE_ID = wl.WAREHOUSE_ID
  AND wl.START_TIME <= qh.START_TIME
  AND wl.END_TIME >= qh.END_TIME
```

**Agent Questions Enabled:**
- "Which warehouses have the most queued queries?"
- "Is COMPUTE_WH under-provisioned based on queue times?"
- "Show me warehouse utilization patterns by hour of day"

---

### 3. TABLE_STORAGE_METRICS

**Purpose:** Track storage consumption by table

**Key Columns:**
- `TABLE_NAME` - Table identifier
- `TABLE_SCHEMA` - Schema name
- `TABLE_CATALOG` - Database name
- `ACTIVE_BYTES` - Current storage size
- `TIME_TRAVEL_BYTES` - Time travel storage
- `FAILSAFE_BYTES` - Failsafe storage
- `CLONE_GROUP_BYTES` - Clone storage

**Benefits:**
- Correlate large scans with table sizes
- Identify storage optimization opportunities
- Support clustering and partitioning recommendations
- Track storage costs

**Join Pattern:**
```sql
-- Note: No direct join to queries, use as supplementary context
-- Join through table names extracted from query text (complex)
```

**Agent Questions Enabled:**
- "What are the largest tables in my account?"
- "Show me storage costs by database"
- "Which tables have excessive time travel storage?"

**Implementation Note:** This table doesn't directly join to query history. Consider creating a separate semantic view or using it for context-only queries.

---

### 4. AUTOMATIC_CLUSTERING_HISTORY

**Purpose:** Track automatic clustering maintenance and costs

**Key Columns:**
- `TABLE_ID` - Table identifier
- `TABLE_NAME` - Table name
- `SCHEMA_NAME` - Schema name
- `DATABASE_NAME` - Database name
- `START_TIME` / `END_TIME` - Clustering period
- `CREDITS_USED` - Clustering credits consumed
- `NUM_BYTES_RECLUSTERED` - Bytes reorganized
- `NUM_ROWS_RECLUSTERED` - Rows reorganized

**Benefits:**
- Identify tables with expensive clustering
- Evaluate clustering ROI
- Support clustering strategy recommendations
- Track clustering efficiency

**Join Pattern:**
```sql
LEFT JOIN SNOWFLAKE.ACCOUNT_USAGE.AUTOMATIC_CLUSTERING_HISTORY ach
  ON qh.DATABASE_ID = ach.DATABASE_ID
  AND qh.SCHEMA_ID = ach.SCHEMA_ID
  -- Additional join logic needed to match table names
  AND ach.START_TIME <= qh.START_TIME
  AND ach.END_TIME >= qh.END_TIME
```

**Agent Questions Enabled:**
- "Which tables have the highest clustering costs?"
- "Is clustering effective for TABLE_NAME?"
- "Show me clustering activity for the last 7 days"

**Implementation Note:** Requires table name parsing from query text for accurate joins.

---

### 5. QUERY_ACCELERATION_HISTORY

**Purpose:** Track Query Acceleration Service usage and effectiveness

**Key Columns:**
- `QUERY_ID` - Links directly to queries
- `START_TIME` / `END_TIME` - Acceleration period
- `CREDITS_USED` - Acceleration credits
- `BYTES_SCANNED` - Data scanned by acceleration
- `UPPER_LIMIT_SCALE_FACTOR` - Scale factor applied
- `NUM_FILES_SCANNED` - Files processed

**Benefits:**
- Track acceleration effectiveness
- Evaluate acceleration costs vs. benefits
- Support acceleration recommendations
- Identify queries that benefit most

**Join Pattern:**
```sql
LEFT JOIN SNOWFLAKE.ACCOUNT_USAGE.QUERY_ACCELERATION_HISTORY qah
  ON qh.QUERY_ID = qah.QUERY_ID
```

**Agent Questions Enabled:**
- "Which queries used Query Acceleration this week?"
- "What is my total Query Acceleration cost?"
- "Should I enable Query Acceleration for this warehouse?"

---

## Enhanced Semantic View

### Recommended Enhanced Semantic View Structure

Below is a sample structure for an enhanced semantic view that includes the additional tables:

```sql
CREATE OR REPLACE SEMANTIC VIEW snowflake_intelligence.tools.snowflake_query_history_enhanced
TABLES (
    SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY,
    SNOWFLAKE.ACCOUNT_USAGE.QUERY_ATTRIBUTION_HISTORY,
    SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY,
    SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY,
    SNOWFLAKE.ACCOUNT_USAGE.QUERY_ACCELERATION_HISTORY
)
FACTS (
  -- All existing QUERY_HISTORY facts (lines 82-132 from setup script)
  -- All existing QUERY_ATTRIBUTION_HISTORY facts (lines 133-135 from setup script)
  
  -- NEW: Warehouse metering facts
  WAREHOUSE_METERING_HISTORY.CREDITS_USED as WH_CREDITS_USED 
    comment='Credits consumed by warehouse during query execution period',
  WAREHOUSE_METERING_HISTORY.CREDITS_USED_COMPUTE as WH_CREDITS_COMPUTE 
    comment='Compute credits consumed by warehouse',
  WAREHOUSE_METERING_HISTORY.CREDITS_USED_CLOUD_SERVICES as WH_CREDITS_CLOUD_SERVICES 
    comment='Cloud services credits consumed by warehouse',
  
  -- NEW: Warehouse load facts
  WAREHOUSE_LOAD_HISTORY.AVG_RUNNING as WH_AVG_RUNNING 
    comment='Average number of queries running on warehouse',
  WAREHOUSE_LOAD_HISTORY.AVG_QUEUED_LOAD as WH_AVG_QUEUED 
    comment='Average number of queries queued due to warehouse load',
  WAREHOUSE_LOAD_HISTORY.AVG_QUEUED_PROVISIONING as WH_AVG_QUEUED_PROVISIONING 
    comment='Average number of queries queued for warehouse provisioning',
  WAREHOUSE_LOAD_HISTORY.AVG_BLOCKED as WH_AVG_BLOCKED 
    comment='Average number of queries blocked on warehouse',
  
  -- NEW: Query acceleration facts
  QUERY_ACCELERATION_HISTORY.CREDITS_USED as QA_CREDITS_USED 
    comment='Credits used for query acceleration service',
  QUERY_ACCELERATION_HISTORY.BYTES_SCANNED as QA_BYTES_SCANNED 
    comment='Bytes scanned by query acceleration service',
  QUERY_ACCELERATION_HISTORY.NUM_FILES_SCANNED as QA_FILES_SCANNED 
    comment='Number of files scanned by query acceleration'
)
DIMENSIONS (
  -- All existing dimensions from original semantic view
  -- No additional dimensions needed (using existing warehouse IDs and query IDs)
)
COMMENT = 'Enhanced query history with warehouse metrics, load data, and acceleration details'
WITH EXTENSION (CA = '{ ... }');  -- Update JSON metadata accordingly
```

---

## Join Strategy Recommendations

### When to Use LEFT JOIN

Use `LEFT JOIN` for optional metadata that may not exist for all queries:

**Examples:**
- Warehouse metering (might not have exact time match)
- Warehouse load (metrics are periodic, not per-query)
- Query acceleration (only exists if acceleration was used)
- Clustering history (only for clustered tables)

**Pattern:**
```sql
FROM QUERY_HISTORY qh
LEFT JOIN WAREHOUSE_METERING_HISTORY wm
  ON qh.WAREHOUSE_ID = wm.WAREHOUSE_ID
  AND wm.START_TIME <= qh.START_TIME
  AND wm.END_TIME >= qh.END_TIME
```

---

### When to Use INNER JOIN

Use `INNER JOIN` only when data must exist:

**Examples:**
- Query attribution (every query should have attribution)
- Essential query metadata

**Current Implementation:**
The existing semantic view uses an implicit join between `QUERY_HISTORY` and `QUERY_ATTRIBUTION_HISTORY`, which effectively acts as an INNER JOIN.

---

### When to Consider LATERAL JOIN

Use `LATERAL JOIN` for complex time-based correlations:

**Example Use Case:** Finding the most recent warehouse metric before each query

```sql
FROM QUERY_HISTORY qh
LEFT JOIN LATERAL (
    SELECT *
    FROM WAREHOUSE_METERING_HISTORY wm
    WHERE wm.WAREHOUSE_ID = qh.WAREHOUSE_ID
      AND wm.END_TIME <= qh.START_TIME
    ORDER BY wm.END_TIME DESC
    LIMIT 1
) wm ON TRUE
```

**Benefits:**
- More precise time matching
- Avoids duplicate rows from multiple time periods
- Better for point-in-time analysis

**Tradeoffs:**
- More complex query plans
- Potentially slower performance
- Requires careful testing

---

## Implementation Examples

### Example 1: Add Warehouse Metering Only

**Minimal Enhancement:** Add cost context to queries

```sql
-- Update existing semantic view to include warehouse metering
CREATE OR REPLACE SEMANTIC VIEW snowflake_intelligence.tools.snowflake_query_history
TABLES (
    SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY,
    SNOWFLAKE.ACCOUNT_USAGE.QUERY_ATTRIBUTION_HISTORY,
    SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY  -- NEW
)
FACTS (
  -- Keep all existing facts
  -- Add only warehouse metering facts
  WAREHOUSE_METERING_HISTORY.CREDITS_USED as WH_CREDITS_USED 
    comment='Credits consumed by warehouse during query period'
)
-- Update dimensions and JSON extension accordingly
```

**Impact:** Enables cost analysis questions without major complexity increase.

---

### Example 2: Full Enhancement with All Tables

**Comprehensive Enhancement:** Maximum context for agent

See [Enhanced Semantic View](#enhanced-semantic-view) section above.

**Impact:** Enables all advanced questions, but increases query complexity.

**Recommendation:** Test performance impact before deploying.

---

### Example 3: Separate Semantic Views by Domain

**Alternative Strategy:** Create multiple focused semantic views

```sql
-- View 1: Query performance (existing)
CREATE SEMANTIC VIEW snowflake_intelligence.tools.query_performance ...

-- View 2: Cost analysis (new)
CREATE SEMANTIC VIEW snowflake_intelligence.tools.cost_analysis
TABLES (
    SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY,
    SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
)
...

-- View 3: Warehouse operations (new)
CREATE SEMANTIC VIEW snowflake_intelligence.tools.warehouse_operations
TABLES (
    SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY,
    SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
)
...
```

**Benefits:**
- Simpler individual views
- Easier to maintain
- Can create specialized agents

**Tradeoffs:**
- More objects to manage
- Agent needs multiple tools configured
- Harder to answer cross-domain questions

---

## Performance Considerations

### Data Volume Impact

Adding more tables increases the data scanned per query:

| Tables | Typical Row Multiplier | Performance Impact |
|--------|------------------------|-------------------|
| Current (2 tables) | 1-2x | Baseline |
| +Warehouse Metering | 1.5-3x | Low-Medium |
| +Warehouse Load | 1.5-3x | Low-Medium |
| +Query Acceleration | 1.1-1.2x | Low |
| All 5 tables | 2-5x | Medium |

**Mitigation Strategies:**
1. Use LEFT JOINs (don't require matches)
2. Add time range filters in semantic view
3. Use larger warehouse for agent queries
4. Consider materialized views for heavy queries

---

### Query Complexity

More tables = more complex query plans:

**Simple Query Plan (2 tables):**
```
QUERY_HISTORY → JOIN → QUERY_ATTRIBUTION_HISTORY
```

**Complex Query Plan (5 tables):**
```
QUERY_HISTORY 
  → LEFT JOIN → WAREHOUSE_METERING_HISTORY
  → LEFT JOIN → WAREHOUSE_LOAD_HISTORY
  → JOIN → QUERY_ATTRIBUTION_HISTORY
  → LEFT JOIN → QUERY_ACCELERATION_HISTORY
```

**Snowflake Optimization:** Snowflake's query optimizer handles complex joins well, but test thoroughly.

---

### Semantic View Refresh Time

Adding tables may increase semantic view metadata refresh time:

- **Current:** ~5-10 seconds to refresh
- **Enhanced:** ~15-30 seconds to refresh
- **Impact:** Minor (refresh is infrequent)

---

## Use Case Scenarios

### Scenario 1: Cost Optimization Focus

**Goal:** Minimize Snowflake compute costs

**Recommended Tables:**
- WAREHOUSE_METERING_HISTORY (track costs)
- WAREHOUSE_LOAD_HISTORY (identify right-sizing)
- AUTOMATIC_CLUSTERING_HISTORY (clustering costs)

**Agent Questions:**
- "Which warehouses are most expensive this month?"
- "Can I reduce COMPUTE_WH size based on utilization?"
- "What is my clustering cost vs. query performance improvement?"

---

### Scenario 2: Performance Optimization Focus

**Goal:** Improve query performance

**Recommended Tables:**
- QUERY_ACCELERATION_HISTORY (acceleration effectiveness)
- WAREHOUSE_LOAD_HISTORY (queue analysis)
- AUTOMATIC_CLUSTERING_HISTORY (clustering efficiency)

**Agent Questions:**
- "Which queries would benefit from Query Acceleration?"
- "Are my slow queries due to warehouse queuing?"
- "Is clustering improving query performance for TABLE_X?"

---

### Scenario 3: Comprehensive Analysis

**Goal:** Full visibility into Snowflake operations

**Recommended Tables:**
- All 5 tables

**Agent Questions:**
- "Analyze the total cost and performance of my top 10 warehouses"
- "What optimization would have the highest ROI?"
- "Compare cost vs. performance tradeoffs for query patterns"

---

## Documentation References

### Snowflake Official Documentation

- **JOIN Constructs:** https://docs.snowflake.com/en/sql-reference/constructs/join
- **ACCOUNT_USAGE Schema:** https://docs.snowflake.com/en/sql-reference/account-usage
- **Semantic Views:** https://docs.snowflake.com/en/user-guide/cortex-analyst
- **Query Optimization:** https://docs.snowflake.com/en/user-guide/query-optimization

### Specific View Documentation

- **WAREHOUSE_METERING_HISTORY:** https://docs.snowflake.com/en/sql-reference/account-usage/warehouse_metering_history
- **WAREHOUSE_LOAD_HISTORY:** https://docs.snowflake.com/en/sql-reference/account-usage/warehouse_load_history
- **TABLE_STORAGE_METRICS:** https://docs.snowflake.com/en/sql-reference/account-usage/table_storage_metrics
- **AUTOMATIC_CLUSTERING_HISTORY:** https://docs.snowflake.com/en/sql-reference/account-usage/automatic_clustering_history
- **QUERY_ACCELERATION_HISTORY:** https://docs.snowflake.com/en/sql-reference/account-usage/query_acceleration_history

---

## Implementation Checklist

If you decide to implement these enhancements:

- [ ] Review performance impact in test environment
- [ ] Choose specific tables based on use cases
- [ ] Update semantic view with new tables and facts
- [ ] Update JSON extension metadata for Cortex Analyst
- [ ] Test join patterns for accuracy
- [ ] Update agent instructions to reference new capabilities
- [ ] Validate with test queries
- [ ] Document custom enhancements for your team
- [ ] Monitor query performance after deployment
- [ ] Adjust warehouse size if needed

---

## Conclusion

These enhancements are **optional** and should be implemented based on your specific needs:

- **Start Simple:** Current 2-table implementation is solid for query performance analysis
- **Add Incrementally:** Test each table addition for performance impact
- **Focus on Use Cases:** Implement only tables that support your specific questions
- **Monitor Performance:** Watch semantic view query times and adjust accordingly

The Snowflake Intelligence Agent is designed to be extensible. These recommendations provide a roadmap for enhancement as your needs grow.

---

**Document Version:** 1.0  
**Last Updated:** 2025-10-17  
**Feedback:** Share your enhancement experiences with the community

