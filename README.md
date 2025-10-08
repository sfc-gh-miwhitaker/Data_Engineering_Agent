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

## Quick Start
 
1. **Review and Update the Setup Script**
   - Open `Snowflake_Assistant_setup.sql`
   - Replace `YOUR_EMAIL_ADDRESS@EMAILDOMAIN.COM` with the address that should receive notifications

2. **Execute the Script as ACCOUNTADMIN**
   - Sign in to Snowsight as a user with the `ACCOUNTADMIN` role
   - Run the entire script in the Worksheets UI (the script handles role creation, grants, Marketplace installation, and agent provisioning)

3. **Verify the Deployment**
   - Confirm the `snowflake_intelligence` database, `cortex_role`, and `Snowflake_Assistant_V2` agent exist
   - Send a test message to the agent and trigger an email via the provided `send_email` procedure

## What Gets Created

- **cortex_role** with the minimum privileges required to manage Snowflake Intelligence assets
- **snowflake_intelligence** database with `agents` and `tools` schemas
- Semantic view `snowflake_intelligence.tools.Snowflake_Query_History` combining query and attribution history
- AI agent `snowflake_intelligence.agents.Snowflake_Assistant_V2` pre-configured with Cortex Analyst, Cortex Search, and email tooling
- Notification integration `email_integration` and supporting stored procedure for HTML email delivery
- Marketplace import of the Snowflake Documentation corpus (`SNOWFLAKE_DOCUMENTATION` database)

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
├── README.md                       # This file
└── Snowflake_Assistant_setup.sql   # Full automation script for agent deployment
```

## Support

None - use at your own risk

## Acknowledgments

Special thanks to Kaitlyn Wells (@snowflake) for the original implementation that serves as the foundation for this customer-ready version.
