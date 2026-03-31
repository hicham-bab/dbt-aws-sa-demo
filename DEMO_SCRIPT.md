# Demo Script — dbt Platform on AWS
**Audience:** AWS Solutions Architects
**Total time:** ~25 minutes + Q&A

---

## Scene 1 — The Problem (2 min)

**What's on screen:** Draw or show a simple diagram:
```
S3 buckets → Glue jobs → Redshift tables → analysts query directly
```

**Talk track:**
> "This is what I see at most AWS customers. Data lands in S3, Glue loads it into
> Redshift, and from there it's a free-for-all. Analysts write their own queries,
> ML teams pull their own feature tables, and everyone has a slightly different
> definition of what 'revenue' means.
>
> When a Bedrock agent returns a wrong answer, nobody can trace why. Which table
> did it query? Was the data fresh? Did it use the right definition of revenue?
>
> This is the problem dbt solves. Let me show you."

---

## Scene 2 — dbt Platform Tour (5 min)

### Step 1 — Open the dbt Cloud IDE

Open `models/staging/stg_orders.sql`.

> "Notice we never hardcode table names. This `source()` macro tells dbt exactly
> where the data comes from — S3 via Glue into Redshift — and dbt tracks every
> dependency. The `ref()` macro here connects this model to other models downstream."

Point at `source('raw', 'raw_orders')` and `ref()` calls.

### Step 2 — Open the Lineage Graph

Click **Lineage** in the IDE or open **Explore** → search any model → **Lineage** tab.

> "This is the full data lineage from your S3 ingestion all the way to the mart
> your Bedrock agent will query. Every node is tested. Every edge is tracked.
> If someone changes a source table upstream, dbt knows which downstream models
> are affected."

Show the DAG: raw seeds → stg_* → int_* → mart models.

### Step 3 — Open dbt Explorer

Navigate to `fct_customer_lifetime_value`.

> "Every column is described. When Bedrock or a SageMaker feature pipeline consumes
> this table, it knows exactly what it's working with. This is the context layer AI
> needs — not just schema metadata, but business definitions."

Point out:
- Model description
- Column-level docs (especially `ltv_segment` with its business rule documented)
- Test coverage badge
- Upstream/downstream lineage

### Step 4 — Show a failing test (optional, powerful)

Run in the IDE terminal:
```bash
dbt test --select stg_customers
```

> "Every column with a `not_null` or `unique` test is continuously validated.
> A test just confirmed our customer data is clean — no duplicates, no nulls
> in critical fields. This is the trust guarantee dbt gives you before any
> data reaches your AI."

---

## Scene 3 — Agentic Development: Kiro × dbt MCP × Fusion Engine (7 min)

### Step 1 — Show the dbt MCP Server connection (30 sec)

Open Kiro IDE. Show the MCP tool palette (sidebar or settings).

> "Kiro now has full context of our dbt project — every model, every dependency,
> every test, every metric — without me pasting a single line of code into the prompt.
> The MCP server exposes our entire project graph as structured tools the agent can call."

### Step 2 — Invoke the Agent Skill

Type into Kiro chat:
```
Create a new staging model for the aws_regions source table.
Follow our existing staging naming conventions (look at stg_customers.sql as a reference),
add a not_null test for region_code, and document all columns in schema.yml.
```

Watch the agent:
1. Call `get_model_details` on `stg_customers` to read our conventions
2. Generate `stg_aws_regions.sql` with the correct `source()` macro
3. Append model + column tests to `schema.yml`

> "The agent didn't guess our naming conventions — it read our actual project via MCP.
> That's the difference between a generic AI assistant and one that understands
> your specific data context."

### Step 3 — Trigger the Fusion Engine feedback loop

In `stg_aws_regions.sql`, change `geography` to `geo_grouping` (a column that doesn't exist).

Ask Kiro:
```
Compile stg_aws_regions.sql and check for errors.
```

Fusion returns in ~2 seconds: `column "geo_grouping" does not exist`

Kiro reads the error, self-corrects, re-compiles — green.

> "Traditional AI coding assistants have to hit your warehouse to discover SQL errors.
> With Fusion, agents get instant compile-time feedback — no Redshift query executed,
> no compute cost, no 30-second wait. It's what makes agentic dbt development
> practical at scale."

### Step 4 — Run dbt build

```bash
dbt build --select stg_aws_regions
```

> "An AI agent just wrote, tested, and documented a production-ready dbt model —
> fully lineage-aware, zero hallucinated table references."

### Optional — 60-second dbt Copilot callout

Switch to dbt Cloud IDE → open Copilot. Type:
```
Generate a model that summarises total revenue by AWS region and month.
```

> "For teams who want AI natively inside dbt Platform — no external IDE —
> dbt Copilot is the answer. Two entry points, one context layer."

---

## Scene 4 — dbt Semantic Layer + AI Consumers (8 min)

### Step 1 — Show the Semantic Layer definition

Open `platform/semantic_models/metrics.yml` in the IDE.

> "This is the dbt Semantic Layer. Every metric your AI tools will ever query
> is defined here — once. `total_revenue` excludes returned and cancelled orders.
> `revenue_ytd` resets at the start of each year. `revenue_mom_growth` computes
> period-over-period using a time spine dbt manages automatically.
>
> One file. One definition. Zero discrepancy between Bedrock, QuickSight,
> SageMaker, and Kiro."

Point at the `saved_queries` section:

> "Saved queries are pre-built, governed entry points for AI tools. Instead of
> letting every agent write its own SQL, you define the canonical questions here.
> Bedrock asks for `executive_kpis` and gets the same answer as QuickSight.
> Always."

### Step 2 — Run the executive KPI saved query from Kiro

Switch to Kiro chat. Type:
```
Run the executive_kpis saved query and show me the results.
```

Kiro executes:
```bash
dbt sl query --saved-query executive_kpis
```

Single-row KPI snapshot: total revenue, orders, AOV, active customers,
revenue per customer, YTD revenue.

> "A Bedrock daily briefing agent can call this every morning and narrate
> the numbers — and they are always governed, always current, always the
> same definition every other dashboard uses."

### Step 3 — EMEA revenue question (the $68K moment)

Ask Kiro:
```
What was total revenue from EMEA customers in Q1 2025?
```

Kiro calls the `revenue_by_geography` saved query with EMEA filter.

Expected answer: **$68,299.60**

> "That answer is auditable. Trace it from this response back to
> fct_revenue_by_region → int_orders_enriched → the raw Kinesis stream in S3.
> Lineage-backed AI. That's what 'AI-ready data' actually means."

### Step 4 — Customer segment breakdown

Ask Kiro:
```
Which customer segment drives the most revenue?
Show revenue and average LTV per segment.
```

Kiro runs `customer_segment_performance` saved query.

> "The platform team owns the revenue definition. The marketing team owns the
> segmentation. Both are exposed through one Semantic Layer — so Bedrock and
> Kiro get a coherent, cross-team answer."

### Step 5 — QuickSight Q integration callout

> "For customers already on QuickSight — the same Semantic Layer connects
> directly. `total_revenue` in a Kiro prompt and `total_revenue` in a
> QuickSight Q question resolve to identical SQL against the same Redshift table.
> No BI-team interpretation step. No 'which revenue number did you use?'"

### Step 6 — Bedrock AgentCore connection

> "For teams building agents at scale — the dbt MCP Server we just used with
> Kiro connects directly to Bedrock AgentCore. Your agents get full project
> context: model lineage, metric definitions, column docs, saved queries —
> all structured, governed, and current."

---

## Scene 5 — dbt + AWS: Native at Every Layer (1.5 min)

**What's on screen:** Build this diagram layer by layer:

```
┌──────────────────────────────────────────────────────────────────┐
│  COMPUTE       Redshift · Athena · RDS/Aurora · Glue/EMR         │
│                SageMaker Lakehouse                                │
│                                                                   │
│  OPEN DATA     Apache Iceberg on S3                               │
│                dbt writes Iceberg tables natively via Athena      │
│                or Redshift — open format, any AI tool consumes it │
│                                                                   │
│  MARKETPLACE   dbt Platform on AWS Marketplace                    │
│                                                                   │
│  ORCHESTRATION Native scheduler · MWAA (Airflow) · Step Functions │
│                                                                   │
│  AI / BI       Bedrock AgentCore · QuickSight Q · SageMaker       │
│                                                                   │
│  DEVELOPER     Kiro IDE + dbt MCP Server                          │
└──────────────────────────────────────────────────────────────────┘
                              ↑
               dbt — the Context Layer across all of it
```

> "Wherever your customers are on AWS — managed warehouse, open lakehouse,
> or both — dbt plugs in natively."

**Iceberg talking point** *(use when the customer mentions open lakehouse / S3)*:

> "For customers moving toward an open data lakehouse on S3 with Apache Iceberg —
> dbt is the Context Layer there too. Same models, tests, lineage, and docs,
> but writing open Iceberg table formats via Athena or Redshift instead of
> proprietary warehouse tables. The AI readiness story is identical: governed,
> tested, lineage-tracked data — open format, any AI tool can consume it."

---

## Scene 6 — Wrap (1 min)

Three closing lines:

1. > "Every AWS customer investing in Bedrock or SageMaker needs this layer. Without it,
>    their AI is operating on data nobody can explain or audit."

2. > "dbt is on AWS Marketplace — your customers can start today, in the account
>    they already have, billing against existing AWS committed spend."

3. > "The data your AI touches went through dbt. That's why you can trust the answer."

Hand off to Q&A.

---

## Common Q&A

**Q: How does dbt compare to AWS Glue DataBrew?**
> DataBrew is a no-code data prep tool — great for data cleaning by non-engineers.
> dbt is a transformation framework for data engineers who want version-controlled,
> tested SQL in production. They're complementary: Glue brings data into Redshift,
> dbt transforms it and governs it from there.

**Q: Does dbt replace Amazon DataZone?**
> No — they complement each other. dbt handles transformation, testing, and the
> Semantic Layer (business metric definitions). DataZone handles data cataloging,
> access governance, and cross-account data sharing. Many customers run both.

**Q: Can we use dbt with other AWS data stores — not just Redshift?**
> Yes. dbt supports Athena (S3 via Glue Catalog), RDS PostgreSQL, Aurora,
> and Glue Iceberg tables. If the data is in a SQL-queryable AWS service, dbt can transform it.

**Q: Does dbt work with Apache Iceberg on S3?**
> Yes. dbt writes Iceberg tables natively via Athena or Redshift Spectrum.
> Same models, tests, lineage, and Semantic Layer — but writing open Iceberg
> format instead of proprietary tables. Every AI tool consumes the same
> governed metrics regardless of the underlying table format.

**Q: How does the dbt Semantic Layer connect to Bedrock?**
> Via JDBC or the Semantic Layer API. You define your metrics in dbt once,
> and any MCP-compatible tool — including Bedrock AgentCore — can query them
> in natural language. dbt translates the question to SQL, Redshift executes it,
> and Bedrock gets a governed, consistent answer.

**Q: How does the dbt Semantic Layer connect to QuickSight?**
> Via the dbt Semantic Layer JDBC driver or the Semantic Layer API.
> QuickSight Q questions resolve against the same metric definitions as
> Bedrock and Kiro — one definition, many consumers.

**Q: What is the dbt MCP Server and how does it connect to Kiro?**
> The dbt MCP Server exposes your entire dbt project — models, metrics, lineage,
> column docs — as structured tools an AI agent can call. Kiro connects via the
> MCP protocol. See `kiro/quickstart-kiro-mcp.md` for a 5-minute setup guide.

**Q: Is dbt open source?**
> dbt Core is fully open source (Apache 2.0). dbt Cloud (the platform with IDE,
> scheduler, Explorer, CI/CD, and Semantic Layer) is a commercial product with
> a free tier and a Team plan. It's available on AWS Marketplace.
