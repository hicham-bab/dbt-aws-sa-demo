# Demo Script — dbt Platform on AWS
**Audience:** AWS Solutions Architects
**Total time:** ~22 minutes + Q&A

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

## Scene 4 — dbt → Amazon Bedrock (6 min)

### Step 1 — Show the clean mart in Redshift

Open **Redshift Query Editor v2** (or dbt Explorer).

Run:
```sql
SELECT geography, SUM(total_revenue) as revenue
FROM marts.fct_revenue_by_region
WHERE order_month BETWEEN '2025-01-01' AND '2025-03-31'
GROUP BY 1
ORDER BY 2 DESC;
```

> "This table went through dbt. It's tested, documented, and trusted.
> The EMEA number you see here is the same number every team, every tool,
> and every AI agent will get — because the definition lives in one place."

### Step 2 — Demo Bedrock query via Semantic Layer

**Option A — Semantic Layer text-to-SQL:**

Show a Bedrock Agent prompt (or type in dbt Cloud IDE terminal):
```bash
dbt sl query \
  --metrics total_revenue \
  --group-by geography,order_date__month \
  --where "geography = 'EMEA' AND order_date__month BETWEEN '2025-01-01' AND '2025-03-31'"
```

> "What was total revenue from EMEA customers in Q1 2025?"

Expected answer: **$68,299.60**

> "The metric definition lives in dbt. Bedrock never guesses what 'revenue' means —
> it asks dbt. That's why you can trust the answer."

**Option B — RAG on dbt-prepared mart (simpler):**

Show a Knowledge Base built on `fct_customer_lifetime_value`. Ask:
> "Who are our top 5 customers by lifetime value, and which AWS regions are they in?"

> "The answer is only trustworthy because the data underneath it went through dbt."

### Step 3 — Optional: show the dbt MCP Server connected to Bedrock AgentCore

> "For teams building agents — the same dbt MCP Server we just used with Kiro
> can be connected to Bedrock AgentCore. Your agents get full project context:
> model lineage, metric definitions, column documentation — all structured, all current."

---

## Scene 5 — Wrap (2 min)

Return to the architecture slide:

```
S3  →  Glue  →  Redshift  →  dbt  →  Bedrock / SageMaker
                              ↑
                         trust & context layer
```

Three closing lines:

1. > "Every AWS customer investing in Bedrock or SageMaker needs this layer. Without it,
>    their AI is operating on data nobody can explain or audit."

2. > "dbt is on AWS Marketplace — your customers can start today, in the account
>    they already have, billing against existing AWS spend."

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

**Q: How does the dbt Semantic Layer connect to Bedrock?**
> Via JDBC or the Semantic Layer API. You define your metrics in dbt once,
> and any MCP-compatible tool — including Bedrock AgentCore — can query them
> in natural language. dbt translates the question to SQL, Redshift executes it,
> and Bedrock gets a governed, consistent answer.

**Q: Is dbt open source?**
> dbt Core is fully open source (Apache 2.0). dbt Cloud (the platform with IDE,
> scheduler, Explorer, CI/CD, and Semantic Layer) is a commercial product with
> a free tier and a Team plan. It's available on AWS Marketplace.
