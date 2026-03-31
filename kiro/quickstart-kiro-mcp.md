# Kiro + dbt MCP Server — 5-Minute Setup

Connect Kiro IDE to your dbt Cloud project so the AI assistant has full context
of every model, metric, lineage edge, and column definition — without you pasting
anything into a prompt.

---

## Prerequisites

| What | Where to get it |
|------|----------------|
| Kiro IDE | [kiro.dev](https://kiro.dev) — download and install |
| dbt Cloud account | Your dbt Platform environment |
| dbt Cloud service token | Account Settings → API Tokens → Service Tokens |
| Environment ID | dbt Cloud → Deploy → Environments → click your env → copy ID from URL |
| Project ID | dbt Cloud → Account Settings → Projects → copy ID from URL |

---

## Step 1 — Install the dbt MCP Server

```bash
# Requires Python 3.11+ and uv (https://github.com/astral-sh/uv)
pip install uv

# Verify dbt-mcp is available
uvx dbt-mcp --help
```

---

## Step 2 — Configure MCP in Kiro

Create or open `~/.kiro/mcp.json` (Kiro's global MCP config):

```json
{
  "mcpServers": {
    "dbt": {
      "command": "uvx",
      "args": ["dbt-mcp"],
      "env": {
        "DBT_HOST": "YOUR_ACCOUNT.us1.dbt.com",
        "DBT_TOKEN": "YOUR_SERVICE_TOKEN",
        "DBT_ENVIRONMENT_ID": "YOUR_ENVIRONMENT_ID",
        "DBT_PROJECT_ID": "YOUR_PROJECT_ID"
      }
    }
  }
}
```

Fill in your values from the Prerequisites table above.
A filled-in template is also at `kiro/dbt-mcp-config.json` in this repo.

---

## Step 3 — Enable the dbt VS Code Extension (LSP + Fusion)

For inline SQL validation, autocomplete, and go-to-definition inside Kiro:

1. Open Kiro → Extensions panel
2. Search **dbt Power User** → Install
3. Open `.vscode/settings.json` in this repo (or create it):

```json
{
  "dbt.projectPaths": ["platform"],
  "dbt.dbtIntegration": "dbt_cloud",
  "dbt.dbtCloudEnvironmentId": "YOUR_ENVIRONMENT_ID"
}
```

Fusion Engine provides **~2-second compile feedback** — red squiggles on bad
column references, autocomplete on `ref()` and `source()`, compiled SQL side-by-side.

---

## Step 4 — Verify the connection

Open Kiro chat and type:

```
What models are in this dbt project?
```

Kiro calls `mcp__dbt_MCP_Server__get_all_models` and returns the full model list.
If it works, you're live.

```
What metrics are defined?
```

Kiro calls `mcp__dbt_MCP_Server__list_metrics` and returns all Semantic Layer metrics.

---

## Step 5 — Run your first Semantic Layer query from Kiro

```
Run the executive_kpis saved query and show me the results.
```

Kiro executes:
```bash
dbt sl query --saved-query executive_kpis
```

---

## What Kiro can now do with dbt MCP

| Prompt | MCP tool called |
|--------|----------------|
| "What does fct_orders contain?" | `get_model_details` |
| "Show me the lineage for fct_customer_lifetime_value" | `get_lineage` |
| "What metrics are available?" | `list_metrics` |
| "Run the revenue_by_geography saved query" | `query_metrics` |
| "Create a staging model for raw_returns following our conventions" | `get_model_details` → writes SQL |
| "Compile stg_returns and check for errors" | `compile` (Fusion Engine) |
| "What columns does dim_customers expose publicly?" | `get_model_details` |
| "Which models depend on fct_orders?" | `get_model_children` |

---

## Connecting to Amazon Bedrock AgentCore (bonus)

The same dbt MCP Server works as a tool provider for Bedrock agents:

1. Deploy the MCP server as a Lambda or ECS task in your AWS account
2. Register it in Bedrock AgentCore as a custom tool group
3. Your Bedrock agents can now call `list_metrics`, `query_metrics`,
   and `get_model_details` to answer natural language data questions
   with governed, lineage-backed answers

```
Bedrock Agent prompt: "What was total revenue from EMEA in Q1 2025?"
→ calls dbt MCP → dbt Semantic Layer → Redshift
→ returns: $68,299.60  (auditable, lineage-tracked)
```

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `uvx: command not found` | Install uv: `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| `dbt-mcp: authentication failed` | Check `DBT_TOKEN` has "Semantic Layer" permission scope |
| `Environment not found` | Confirm `DBT_ENVIRONMENT_ID` matches a **deployment** environment (not dev) |
| MCP tools not appearing in Kiro | Restart Kiro after editing `mcp.json` |
| `mf validate-configs` shows stale results | Run `dbt parse` first to regenerate the manifest |
