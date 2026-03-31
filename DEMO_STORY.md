# Demo Story — dbt as the AI Control Plane on AWS
**For slide deck production · Share with Claude coworker**
**Audience:** AWS Solutions Architects pitching to data + AI buyers

---

## The Big Idea (One Sentence Per Slide)

> **"AWS gives you the best AI services in the world. dbt makes sure they're
> working with data you can actually trust."**

---

## Slide Structure

---

### SLIDE 1 — Title

**Headline:** dbt + AWS: The AI-Ready Data Stack
**Subhead:** How dbt acts as the Context Layer between your AWS infrastructure and every AI service you deploy
**Visual:** dbt logo + AWS logo side by side on a clean dark background

---

### SLIDE 2 — The Problem Every AWS Customer Has

**Headline:** Your AI is only as good as the data it touches

**Three-column layout:**

| Without dbt | The consequence | The risk |
|-------------|-----------------|----------|
| 5 teams, 5 definitions of "revenue" | Bedrock returns different numbers than QuickSight | Executive loses trust in AI |
| No lineage from S3 → AI output | Can't explain why Bedrock gave that answer | Compliance and audit exposure |
| ML features built on untested tables | Model trained on wrong data | Silent, costly errors in production |

**Speaker note:** *"This is the invisible tax on every AWS AI investment. You spend months building Bedrock agents and SageMaker pipelines — and then someone asks 'why is this number different from the dashboard?' and nobody can answer."*

---

### SLIDE 3 — dbt is the Context Layer

**Headline:** dbt sits between your data infrastructure and your AI

**Visual: Architecture diagram**

```
┌─────────────────────────────────────────────────────────┐
│                   AWS Data Sources                       │
│   S3 · Kinesis · Glue · RDS · DynamoDB streams          │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│                  dbt Context Layer                       │
│                                                          │
│   Models          Tests           Semantic Layer         │
│   (trusted SQL)   (data quality)  (one metric definition)│
│                                                          │
│   Lineage         Docs            Contracts              │
│   (full graph)    (col-level)     (enforced schemas)     │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│                   AI Consumers                           │
│   Bedrock AgentCore · QuickSight Q · SageMaker           │
│   Kiro IDE · Custom agents · Any MCP-compatible tool     │
└─────────────────────────────────────────────────────────┘
```

**Speaker note:** *"dbt doesn't replace Bedrock or SageMaker. It's the trust and context layer they need underneath. Same data. Now explainable, tested, and governed."*

---

### SLIDE 4 — dbt is Native on Every AWS Layer

**Headline:** Wherever your customers are on AWS, dbt plugs in natively

**Full-width table:**

| AWS Layer | Services | dbt Integration |
|-----------|----------|-----------------|
| **Compute** | Redshift · Athena · RDS/Aurora · Glue/EMR · SageMaker Lakehouse | Native adapters for all |
| **Open Data** | Apache Iceberg on S3 | dbt writes Iceberg tables natively via Athena or Redshift |
| **Marketplace** | AWS Marketplace | dbt Platform available — bill against existing AWS spend |
| **Orchestration** | Native scheduler · MWAA (Airflow) · Step Functions | dbt jobs + API triggers |
| **AI / BI** | Bedrock AgentCore · QuickSight Q · SageMaker | Semantic Layer API + dbt MCP Server |
| **Developer** | Kiro IDE | dbt MCP Server — full project context in every AI prompt |

**Speaker note:** *"Wherever your customers are on AWS — managed warehouse, open lakehouse, or both — dbt plugs in natively."*

---

### SLIDE 5 — The Open Data Lakehouse Story (Iceberg)

**Headline:** Open Data Infrastructure: same dbt, open table format

**Two-column layout:**

**Left — Managed Warehouse**
```
S3 → Glue → Redshift
         ↓
      dbt models
         ↓
    Bedrock / QS
```
- Proprietary Redshift tables
- Native Redshift performance
- Governed by dbt

**Right — Open Lakehouse**
```
S3 (Iceberg) → Athena / Redshift Spectrum
                      ↓
                 dbt models
                      ↓
              Any AI tool reads it
```
- Open Apache Iceberg format
- Any query engine can read it
- Same dbt governance

**Pull quote:**
> *"For customers moving toward an open data lakehouse on S3 with Iceberg —
> dbt is the Context Layer there too. Same models, tests, lineage and docs,
> but writing open table formats. The AI readiness story is identical."*

---

### SLIDE 6 — The Semantic Layer: One Definition for Every AI

**Headline:** Define revenue once. Every AI gets the same answer.

**Visual: Hub-and-spoke diagram**

Center node: **`total_revenue` (defined in dbt)**
Spokes pointing out to:
- Amazon Bedrock AgentCore
- Amazon QuickSight Q
- SageMaker feature pipeline
- Kiro IDE
- Custom agent / API

**Below the diagram:**

```yaml
# metrics.yml — one file, one definition
- name: total_revenue
  description: Sum of completed order revenue. Excludes returns and cancellations.
  type: simple
  filter: "status = 'completed'"
```

**Speaker note:** *"Without this, Bedrock invents its own revenue SQL. QuickSight uses a different one. SageMaker trains on a third. With dbt Semantic Layer, there is one definition — governed, versioned, tested."*

---

### SLIDE 7 — Pre-Built AI Queries: Saved Queries

**Headline:** Don't let AI guess. Give it governed, pre-built questions.

**What's a saved query?**
A saved query is a named, reusable Semantic Layer entry point. AI tools call it by name instead of writing raw SQL.

**Five saved queries in this demo:**

| Saved Query | What it answers |
|-------------|-----------------|
| `executive_kpis` | Total revenue, orders, AOV, active customers, YTD revenue — single row |
| `revenue_by_geography` | Monthly revenue by AMER / EMEA / APAC |
| `customer_segment_performance` | Revenue + LTV by champion / loyal / potential / new |
| `product_category_revenue` | All-time revenue and units sold by product category |
| `regional_customer_growth` | Customer acquisition trends by geography over time |

**Speaker note:** *"Each of these is a governed entry point. Bedrock calls `executive_kpis` every morning for the daily briefing. QuickSight renders `revenue_by_geography` as a heatmap. Kiro answers natural language prompts using any of them. Same data, same definition, everywhere."*

---

### SLIDE 8 — Kiro + dbt MCP: Agentic Development

**Headline:** Kiro understands your dbt project — model by model, metric by metric

**What the dbt MCP Server gives Kiro:**

```
Kiro prompt: "What was EMEA revenue in Q1 2025?"

Kiro calls:  mcp__dbt_MCP_Server__query_metrics
             → saved_query: revenue_by_geography
             → filter: geography = 'EMEA', Q1 2025

Answer:      $68,299.60  ← same as QuickSight, same as Bedrock
             Traceable back to fct_revenue_by_region → raw S3 data
```

**Kiro capabilities via dbt MCP:**
- Read model definitions, schemas, column docs
- Query the Semantic Layer (natural language → governed SQL)
- Generate new dbt models following your project's conventions
- Compile instantly via Fusion Engine (2-second feedback, no warehouse cost)
- Check lineage before any change

**Speaker note:** *"This is the difference between a generic AI coding assistant and one that knows your data. Kiro with dbt MCP doesn't hallucinate table names — it reads them."*

---

### SLIDE 9 — The Bedrock + QuickSight Integration

**Headline:** From natural language to trusted answer — end to end on AWS

**Flow diagram:**

```
User asks Bedrock:
"Which AWS region had the highest revenue growth in 2024?"
        │
        ▼
Bedrock AgentCore
calls dbt MCP Server tool: query_metrics
        │
        ▼
dbt Semantic Layer
resolves: revenue_mom_growth metric, group by aws_region
        │
        ▼
Redshift executes governed SQL
        │
        ▼
Bedrock returns: "us-east-1 had the highest MoM growth at +23% in October 2024"
+ lineage: "Based on fct_revenue_by_region, tested daily, last run 2h ago"
```

**QuickSight Q path (parallel):**

```
User asks QuickSight Q:
"Show me revenue by region for 2024"
        │
        ▼
QuickSight Q → dbt Semantic Layer JDBC
        │
        ▼
Same metric, same SQL, same Redshift table
```

**Speaker note:** *"Two different AI surfaces. One data definition. No reconciliation meeting needed."*

---

### SLIDE 10 — dbt Mesh: Governance at Scale

**Headline:** Multiple teams, one governed data platform

**Visual: Three-project Mesh diagram**

```
┌─────────────────────────┐
│   aws_ecommerce         │  ← Platform team
│   (platform project)    │    6 public mart models
│   6 Public Models       │    Contracts enforced
└────────────┬────────────┘
             │  cross-project ref()
    ┌────────┴────────┐
    ▼                 ▼
┌───────────┐   ┌────────────┐
│marketing  │   │  finance   │  ← Consumer teams
│_aws       │   │  _aws      │    Own their logic
│           │   │            │    Depend on platform contracts
└───────────┘   └────────────┘
```

- Platform team owns the canonical mart models + Semantic Layer
- Marketing and Finance teams build on top via `ref('aws_ecommerce', 'fct_orders')`
- If platform changes a public model, both downstream projects are notified
- Contracts (`contract: enforced: true`) prevent silent schema breaks

**Speaker note:** *"This is how you scale data governance across teams without a central bottleneck. Each team moves independently — but within governed contracts the platform team enforces."*

---

### SLIDE 11 — Live Demo Flow

**Headline:** What you'll see in the next 20 minutes

**Timeline:**

| # | Scene | Duration | What you'll see |
|---|-------|----------|-----------------|
| 1 | The Problem | 2 min | Why ungoverned data breaks AI |
| 2 | dbt Platform Tour | 5 min | Source → lineage → docs → tests |
| 3 | Kiro × MCP × Fusion | 7 min | AI agent writes, tests, and fixes a dbt model live |
| 4 | Semantic Layer + AI | 8 min | Saved queries, EMEA $68K, Bedrock integration |
| 5 | AWS Native Stack | 1.5 min | Full AWS layer diagram with Iceberg callout |
| 6 | Wrap | 1 min | Three closing lines |

---

### SLIDE 12 — Call to Action

**Headline:** Three ways to start this week

**Three-column layout:**

| Today (free) | This week | This month |
|--------------|-----------|------------|
| Install dbt Core (open source) and run your first model against Redshift | Set up dbt Cloud free tier + connect to your S3/Redshift stack | Enable the Semantic Layer, connect Bedrock or QuickSight Q |
| `pip install dbt-redshift` | dbt Cloud free at cloud.getdbt.com | Connect via JDBC or MCP Server |
| **dbt Core is Apache 2.0** | **No credit card required** | **Available on AWS Marketplace** |

**Bottom banner:**
> dbt Platform is available on AWS Marketplace — bill against existing AWS committed spend. No new procurement cycle.

---

### SLIDE 13 — Summary

**Headline:** dbt is the trust layer your AWS AI stack is missing

**Four-box grid:**

| **Govern** | **Connect** |
|------------|-------------|
| Every model tested. Every column documented. Every metric defined once. | Native on Redshift, Athena, Iceberg — and on AWS Marketplace. |
| **Scale** | **Accelerate** |
| dbt Mesh: multiple teams, enforced contracts, independent deployments. | Kiro + MCP: AI that writes production dbt code with full project context. |

**Closing line (large text):**
> *"The data your AI touches went through dbt. That's why you can trust the answer."*

---

## Appendix: Key Demo Numbers

| Fact | Value | Source |
|------|-------|--------|
| EMEA Q1 2025 revenue | **$68,299.60** | `saved_query: revenue_by_geography` |
| Fusion compile time | **~2 seconds** | No warehouse query needed |
| Platform public models | **6** | `fct_orders`, `fct_revenue_by_region`, `fct_customer_lifetime_value`, `fct_product_performance`, `dim_customers`, `dim_products` |
| Semantic Layer metrics | **11** | See `platform/semantic_models/metrics.yml` |
| Saved queries | **5** | `executive_kpis`, `revenue_by_geography`, `customer_segment_performance`, `product_category_revenue`, `regional_customer_growth` |
| Mesh projects | **3** | `aws_ecommerce` (platform), `marketing_aws`, `finance_aws` |

---

## Appendix: Slide Design Notes for Claude

- **Color palette:** AWS dark navy (#232F3E) background, AWS orange (#FF9900) accents, white text
- **Font:** AWS uses Ember for headlines; use a clean sans-serif (Inter or Helvetica Neue)
- **Code blocks:** Dark background, syntax-highlighted YAML and SQL
- **Diagrams:** Box-and-arrow style, consistent node shapes (rectangles for services, rounded for concepts)
- **Icons:** Use official AWS service icons where available (S3, Redshift, Bedrock, SageMaker, QuickSight)
- **dbt logo:** Use official dbt orange-on-white or white-on-dark version
- **Slide count target:** 13 content slides + title + any appendix slides needed
- **Tone:** Confident, technical but accessible — this is for SAs, not executives
