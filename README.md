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

## Prerequisites

- Snowflake account with ACCOUNTADMIN privileges
- Snowflake Documentation Knowledge Extension (available from Marketplace)

## Quick Start

1. **Install Dependencies**
   - Navigate to Data Products > Marketplace in your Snowflake account
   - Search for and install "Snowflake Documentation" extension

2. **Run Setup Script**
   ```sql
   -- Update the username in the script
   -- Execute snowflake_intelligence_setup_minimal.sql as ACCOUNTADMIN
   ```

3. **Follow the Guided Setup**
   The SQL script includes comprehensive step-by-step instructions for:
   - Creating semantic views
   - Configuring the AI agent
   - Setting up tools and orchestration
   - Testing the assistant

## What Gets Created

- **AI_DEVELOPER** role and warehouse for agent operations
- **SNOWFLAKE_INTELLIGENCE** database with AGENTS and DATA_AGENTS schemas
- Semantic view analyzing QUERY_HISTORY and QUERY_ATTRIBUTION_HISTORY
- AI Agent with Cortex Analyst and Cortex Search capabilities
- Complete access controls and permissions

## Usage Examples

Once deployed, you can ask your Data Engineer Assistant questions like:

- "Based on my top 10 slowest queries, can you provide ways to optimize them?"
- "Which warehouses should be upgraded to Gen 2?"
- "Show me queries with compilation errors and how to fix them"
- "What queries are scanning the most data and how can I reduce that?"
- "Would my query benefit from Query Acceleration or Search Optimization Service?"

## Project Structure

```
Data_Engineering_Agent/
├── README.md                                    # This file
└── snowflake_intelligence_setup_minimal.sql    # Complete setup script with guided instructions
```

## Support

None - use at your own risk

## Acknowledgments

Special thanks to Kaitlyn Wells (@snowflake) for the original implementation that serves as the foundation for this customer-ready version.
