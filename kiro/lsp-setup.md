# dbt Language Server (LSP) + Fusion Engine in Kiro

## What the LSP gives you during the demo

The dbt Fusion LSP provides real-time feedback *as you type* — no warehouse round-trip needed:

| Feature | Demo value |
|---|---|
| Red squiggles on bad column refs | Live in Scene 3 — shows the error instantly |
| Autocomplete for `ref()` and `source()` | Type `ref('` → model list appears |
| Go-to-definition | Ctrl/Cmd+click a `ref()` → jumps to the model file |
| Compiled SQL side-by-side | See what Redshift will actually execute |
| Column-level lineage | Click a column → see where it originates |
| Hover on `*` | Expands to show all columns without running a query |

## Official IDE support

The dbt VS Code extension (published by `dbtLabsInc`) officially supports:
- VS Code
- Cursor
- Windsurf

**Kiro** is not on the official list, but it is built on VS Code's open-source core
and supports VS Code Marketplace extensions. In practice, the dbt extension installs
and works in Kiro — the LSP binary is IDE-agnostic.

## Installing the dbt extension in Kiro

1. Open Kiro's Extensions panel (`Cmd+Shift+X`)
2. Search for **dbt Power User** or **dbt** (publisher: `dbtLabsInc`)
3. Click **Install**
4. Open your `platform/` folder as the workspace root
5. When prompted, install the dbt Fusion engine binary — click **Yes**
6. The LSP starts automatically and begins compiling your project in the background

> If the extension is not found in Kiro's marketplace (Kiro may use Open VSX),
> download the `.vsix` file from the VS Code Marketplace and install via:
> **Extensions → ... → Install from VSIX**

## Configuring the workspace

Create `.vscode/settings.json` in the `platform/` directory:

```json
{
  "dbt.dbtPythonPathOverride": "",
  "dbt.profilesDirOverride": ".",
  "dbt.projectsRootPath": ".",
  "editor.formatOnSave": true
}
```

## Connecting the dbt MCP Server in Kiro

Add this to Kiro's MCP configuration (`~/.kiro/settings/mcp.json` or via Kiro UI):

```json
{
  "mcpServers": {
    "dbt": {
      "command": "uvx",
      "args": ["dbt-mcp"],
      "env": {
        "DBT_HOST": "<your-dbt-cloud-host>",
        "DBT_TOKEN": "<your-dbt-cloud-service-token>",
        "DBT_ENVIRONMENT_ID": "<your-environment-id>",
        "DBT_PROJECT_ID": "<your-project-id>"
      }
    }
  }
}
```

The MCP server gives Kiro's agent:
- `list_models` — all models in the project
- `get_model_details` — SQL, columns, tests for a specific model
- `get_lineage` — upstream/downstream graph
- `list_metrics` — Semantic Layer metrics

## Scene 3 demo flow with LSP active

1. Open `platform/models/staging/stg_aws_regions.sql` in Kiro
2. The LSP is already compiling — notice the status bar shows "dbt: Parsing..."
3. In the Kiro chat, invoke the agent skill (see `agent-skill-demo.md`)
4. When the agent writes the new model, hover over `source('raw', 'aws_regions')` → LSP shows the source columns
5. Introduce the deliberate error (`geo_grouping` instead of `geography`) → red squiggle appears in ~2 seconds
6. Point to the squiggle: *"This is Fusion. No warehouse query. Just instant feedback."*
7. Kiro reads the LSP diagnostic and self-corrects

## Fallback: use the Fusion CLI directly

If the extension doesn't load in Kiro, you can demo Fusion compile feedback in the terminal:

```bash
cd platform/
dbt compile --select stg_aws_regions
```

The error message from Fusion is fast and clean — works equally well for the demo story.
