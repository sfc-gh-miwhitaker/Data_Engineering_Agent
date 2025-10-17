# Snowflake Data Engineering Agent

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
- Outbound email domain allow-listed for Snowflake notification integrations (update the script with your target address)
- Users must have an active warehouse to run agent queries (agent uses user's current warehouse context)

## Quick Start
 
1. **Review and Configure the Setup Script**
   - Open `Snowflake_Assistant_setup.sql`
   - Update configuration variables (lines 48-49):
     - `SET role_name = 'SYSADMIN';` (or your preferred role)
     - `SET warehouse_name = 'COMPUTE_WH';` (or your existing warehouse)
   - Replace `YOUR_EMAIL_ADDRESS@EMAILDOMAIN.COM` (line ~201) with your email address

2. **Execute the Script as ACCOUNTADMIN**
   - Sign in to Snowsight as a user with the `ACCOUNTADMIN` role
   - Run the entire script in the Worksheets UI
   - The script is idempotent and handles role grants, Marketplace installation, and agent provisioning

3. **Verify the Deployment**
   - Confirm the `snowflake_intelligence` database and `snowflake_assistant_v2` agent exist
   - Check that the test email was received
   - Test the agent by asking: "What were my slowest queries this week?"

## What Gets Created

- **snowflake_intelligence** database with `agents` and `tools` schemas (managed by `SYSADMIN` role)
- Semantic view `snowflake_intelligence.tools.snowflake_query_history` combining query and attribution history
- AI agent `snowflake_intelligence.agents.snowflake_assistant_v2` pre-configured with Cortex Analyst, Cortex Search, and email tooling
- Notification integration `email_integration` and supporting stored procedure for HTML email delivery
- Marketplace import of the Snowflake Documentation corpus (`snowflake_documentation` database)
- All objects use `SYSADMIN` role following the principle of least privilege

## Usage Examples

Once deployed, you can ask your Data Engineer Assistant questions like:

- "Based on my top 10 slowest queries, can you provide ways to optimize them?"
- "Which warehouses should be upgraded to Gen 2?"
- "Show me queries with compilation errors and how to fix them"
- "What queries are scanning the most data and how can I reduce that?"
- "Would my query benefit from Query Acceleration or Search Optimization Service?"
- "Send email to me summarizing the optimization plan"

## Project Structure

```
Data_Engineering_Agent/
├── .gitignore                       # Git ignore rules for sensitive files
├── LICENSE                          # Apache 2.0 license
├── README.md                        # This file
├── Snowflake_Assistant_setup.sql    # Full automation script for agent deployment
├── deployment_checklist.md          # Pre-deployment verification steps
├── teardown_script.sql             # Complete removal of all deployed resources
├── sql/                            # Enhanced agent SQL scripts
│   └── deploy_enhanced_agent.sql   # Complete enhanced agent deployment
├── help/                           # Documentation and guides
│   ├── TESTING.md                  # Validation procedures and test scenarios
│   ├── TROUBLESHOOTING.md          # Common issues and solutions
│   ├── ENHANCEMENT_RECOMMENDATIONS.md  # Optional improvements
│   ├── ENHANCED_AGENT_README.md    # Enhanced agent documentation
│   └── RELEASE_NOTES_v2.1.md       # Release notes for v2.1
├── .cursornotes/                   # Internal development notes (not committed)
└── archive/                        # Previous versions
```

## Enhanced Agent (Optional)

For improved performance and natural language understanding, deploy the **Enhanced Agent** with domain-specific semantic views:

- **Three specialized tools**: Query Performance, Cost Analysis, Warehouse Operations
- **Synonym support**: Better understanding of different phrasings
- **Faster queries**: Smaller, focused semantic views
- **Clear tool selection**: Keyword-based routing for better accuracy

See `help/ENHANCED_AGENT_README.md` for details and deployment instructions.

## Security Considerations

- The script uses `SYSADMIN` role following the principle of least privilege
- SQL injection protection implemented in the Python email procedure
- All user inputs are escaped before being passed to system procedures
- `PUBLIC` role is granted `USAGE` only (not ownership or modification rights)
- Review the email integration security requirements for your organization

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## Support

None - use at your own risk. This is community-supported code.

## Acknowledgments

Special thanks to Kaitlyn Wells (@snowflake) for the original implementation that serves as the foundation for this customer-ready version.
