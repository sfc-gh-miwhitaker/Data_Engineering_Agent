# Snowflake Data Engineering Agent

**Version**: 2.3  
**License**: Apache 2.0  
**Status**: Community Ready

A comprehensive AI-powered assistant for Snowflake data engineering optimization and performance analysis.

## Overview

This project provides a complete setup for deploying a Snowflake Intelligence Agent that acts as your personal Data Engineer Assistant. The agent analyzes your actual query history to provide personalized, actionable recommendations for optimizing Snowflake performance.

**Based on the excellent work by Kaitlyn Wells (@snowflake) - sanitized and optimized for customer deployment.**

## Features

- **Query Performance Analysis**: Identifies your slowest-running queries and provides optimization recommendations
- **Warehouse Optimization**: Analyzes warehouse utilization and suggests sizing improvements
- **Error Resolution**: Helps troubleshoot compilation errors and query issues
- **Best Practices**: Recommends modern Snowflake features (Gen 2 warehouses, clustering, etc.)
- **Historical Insights**: Provides trends and patterns from your query history
- **Documentation Integration**: Seamlessly searches Snowflake documentation for relevant guidance
- **Email Delivery**: Optionally emails the assistant output to stakeholders through a Snowflake notification integration

## Prerequisites

- Snowflake account with `ACCOUNTADMIN` privileges
- Ability to install Marketplace listings (the script automates installation of the Snowflake Documentation Knowledge Extension)
- Outbound email domain allow-listed for Snowflake notification integrations
- Users must have an active warehouse to run agent queries (agent uses user's current warehouse context)

## Quick Start
 
1. **Review and Configure the Setup Script**
   - Open `Snowflake_Assistant_setup.sql`
   - **Line 49**: Update `SET role_name` if needed (default: SYSADMIN)
   - **Line 241**: Replace `YOUR_EMAIL_ADDRESS@EMAILDOMAIN.COM` with your email
   - **Important**: Ensure you have an active warehouse before running

2. **Execute the Script as ACCOUNTADMIN**
   - Sign in to Snowsight as a user with the `ACCOUNTADMIN` role
   - Run the entire `Snowflake_Assistant_setup.sql` in the Worksheets UI
   - Script is idempotent (safe to re-run)
   - Takes approximately 2-3 minutes to complete

3. **Verify the Deployment**
   - Confirm the `snowflake_intelligence` database and `snowflake_assistant_v2` agent exist
   - Check that the test email was received
   - Test the agent by asking: "What were my slowest queries this week?"

## What Gets Created

- **snowflake_intelligence** database with `agents` and `tools` schemas (managed by `SYSADMIN` role)
- Semantic view `snowflake_intelligence.tools.snowflake_query_history` combining query and attribution history
- Cortex Search service integration with Snowflake Documentation from Marketplace
- Email notification stored procedure (`send_email`)
- Agent `snowflake_assistant_v2` with integrated tools (Cortex Analyst, Cortex Search, Email)

## Project Structure

```
Data_Engineering_Agent/
├── .gitignore                       # Git ignore rules for sensitive files
├── LICENSE                          # Apache 2.0 license
├── README.md                        # This file
├── Snowflake_Assistant_setup.sql    # Full automation script for agent deployment
├── teardown_script.sql              # Complete removal of all deployed resources
├── sql/                             # Enhanced agent SQL scripts
│   └── deploy_enhanced_agent.sql    # Complete enhanced agent deployment
├── help/                            # Documentation and guides
│   ├── deployment_checklist.md      # Pre-deployment verification steps
│   ├── ENHANCEMENT_RECOMMENDATIONS.md  # Optional improvements
│   ├── ENHANCED_AGENT_README.md     # Enhanced agent documentation
│   ├── RELEASE_NOTES_v2.1.md        # v2.1 release notes
│   ├── RELEASE_NOTES_v2.2.md        # v2.2 release notes
│   ├── RELEASE_NOTES_v2.3.md        # v2.3 release notes
│   ├── ROLE_BASED_ACCESS.md         # Restrict access to specific teams/roles
│   ├── TESTING.md                   # Validation procedures and test scenarios
│   └── TROUBLESHOOTING.md           # Common issues and solutions
└── archive/                         # Previous versions
```

## Enhanced Agent (Optional)

For improved performance and natural language understanding, deploy the **Enhanced Agent** with domain-specific semantic views:

- **Three specialized tools**: Query Performance, Cost Analysis, Warehouse Operations
- **Synonym support**: Better understanding of different phrasings
- **Faster queries**: Smaller, focused semantic views
- **Clear tool selection**: Keyword-based routing for better accuracy

See `help/ENHANCED_AGENT_README.md` for details and deployment instructions.

## Usage

### Access the Agent

1. Navigate to Snowsight: **AI & ML > Agents**
2. Select **Snowflake Assistant**
3. Start asking questions in natural language

### Sample Questions

```
"What are my top 10 slowest queries today?"
"Which warehouses should be upgraded to Gen 2?"
"Show me queries that are scanning the most data"
"What queries are failing with compilation errors?"
"Send me an email summary of query performance"
```

### Understanding the Responses

The agent provides:
- **Data-driven insights**: Based on your actual query history
- **Specific recommendations**: Actionable next steps with clear instructions
- **Prioritized solutions**: High-impact optimizations first
- **Snowflake best practices**: Modern features and approaches
- **Documentation links**: References to official Snowflake docs

## Architecture

### Key Components

1. **Semantic Views**: Define queryable data models for Cortex Analyst
2. **Cortex Analyst**: Converts natural language to SQL queries
3. **Cortex Search**: Searches Snowflake documentation for best practices
4. **Custom Tools**: Email integration via stored procedure

### Data Flow

```
User Question → Agent → Tool Selection → Data Query → Analysis → Response
                  ↓
            Cortex Analyst (Text-to-SQL)
            Cortex Search (Documentation)
            Custom Procedure (Email)
```

### Warehouse Usage

The agent uses the user's current warehouse context. Users control compute costs through their own warehouse selection and sizing.

## Security Considerations

- **Principle of Least Privilege**: Uses SYSADMIN role for most operations, ACCOUNTADMIN only where required
- **No Hardcoded Credentials**: All authentication via Snowflake roles
- **SQL Injection Protection**: All inputs properly escaped in stored procedure
- **Read-Only Access**: Agent queries ACCOUNT_USAGE views (read-only)
- **User Isolation**: Each user's queries run under their own privileges

## Troubleshooting

See `help/TROUBLESHOOTING.md` for detailed troubleshooting guidance.

Common issues:
- **No warehouse specified**: Ensure you have an active warehouse before using the agent
- **Permission errors**: Verify ACCOUNTADMIN role for deployment, PUBLIC role for users
- **Marketplace access**: Requires network access and legal terms acceptance
- **Email not working**: Verify email domain is allow-listed in notification integration

## Testing

See `help/TESTING.md` for comprehensive testing procedures and validation steps.

## Cleanup

To remove all deployed resources:

```sql
-- Execute teardown_script.sql as ACCOUNTADMIN
-- This removes agents, semantic views, and other project objects
-- The script is safe by default - preserves shared databases/schemas
```

## Version History

- **v2.3** (2025-10-17): Simplified warehouse management - uses user's warehouse context
- **v2.2** (2025-10-17): Dedicated warehouse architecture (deprecated)
- **v2.1** (2025-10-14): Enhanced agent with domain-specific semantic views
- **v2.0** (2025-10-08): Initial production release

See `help/RELEASE_NOTES_v2.2.md` for detailed change history.

## Contributing

This is a community project. Contributions welcome!

1. Follow existing code style (see project rules)
2. Test changes thoroughly
3. Update documentation
4. Submit pull requests with clear descriptions

## License

Apache License 2.0 - see LICENSE file for details.

## Support

- **Documentation**: See `help/` directory
  - `help/TROUBLESHOOTING.md` - Common issues and solutions
  - `help/TESTING.md` - Validation procedures
  - `help/ROLE_BASED_ACCESS.md` - Restrict access to specific teams/roles
  - `help/ENHANCED_AGENT_README.md` - Optional enhanced deployment
- **Issues**: Submit via GitHub issues
- **Community**: Snowflake Community forums

**Disclaimer**: This is community-supported software. While thoroughly tested, it is provided "as-is" without warranties or guarantees. Users are responsible for testing in their own environments before production use. See LICENSE for full terms.

## Credits

Based on original work by Kaitlyn Wells (@snowflake). Enhanced and productionized by the Snowflake community.

---

**Ready to deploy?** Start with `help/deployment_checklist.md` to ensure all prerequisites are met!
