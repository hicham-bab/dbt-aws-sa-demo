# dbt Platform on AWS — SA Demo Repository

A complete, runnable dbt project for demonstrating dbt Platform with Amazon Redshift
to AWS customers. Built for AWS Solutions Architect enablement sessions.

**Data model:** SaaS e-commerce company selling cloud infrastructure products to customers
across AMER, EMEA, and APAC — structured so every demo question maps naturally to
AWS regions and geographies your customers already understand.

---

## dbt Mesh structure

This repo uses **dbt Mesh** — three independent dbt projects with enforced cross-project contracts.

```
dbt-aws-sa-demo/
├── platform/                    # Data Platform team — producer
│   ├── dbt_project.yml          # project: aws_ecommerce
│   ├── models/
│   │   ├── staging/             # protected — stg_* views (S3 → Glue → Redshift)
│   │   ├── intermediate/        # protected — int_* business logic views
│   │   └── marts/               # PUBLIC — contracted models consumed by other projects
│   │       ├── customers/       # dim_customers, fct_customer_lifetime_value
│   │       ├── orders/          # fct_orders, fct_revenue_by_region
│   │       └── products/        # dim_products, fct_product_performance
│   ├── seeds/                   # CSV seed data (replaces S3/Glue for demo setup)
│   └── semantic_models/         # dbt Semantic Layer — 5 metrics for Bedrock
│
├── marketing/                   # Marketing Analytics team — consumer
│   ├── dbt_project.yml          # project: marketing
│   └── models/
│       ├── mart_customer_segments.sql   # ref('aws_ecommerce', 'fct_customer_lifetime_value')
│       └── mart_region_performance.sql  # ref('aws_ecommerce', 'fct_revenue_by_region')
│
├── finance/                     # Finance Analytics team — consumer
│   ├── dbt_project.yml          # project: finance
│   └── models/
│       ├── fct_revenue_recognised.sql   # ref('aws_ecommerce', 'fct_orders')
│       ├── fct_product_revenue.sql      # ref('aws_ecommerce', 'fct_product_performance')
│       └── fct_geography_pnl.sql        # ref('aws_ecommerce', 'fct_revenue_by_region')
│
├── setup/                       # Redshift setup SQL + IAM guide
├── kiro/                        # Kiro IDE config, MCP setup, LSP guide, Scene 3 prompts
├── QUICKSTART.md                # Step-by-step: Redshift → dbt Cloud → mesh running
└── DEMO_SCRIPT.md               # Full scene-by-scene talk track
```

### Mesh access model

| Layer | Access | Who can ref it |
|---|---|---|
| `staging/*` | `protected` | Only models in `aws_ecommerce` project |
| `intermediate/*` | `protected` | Only models in `aws_ecommerce` project |
| `marts/*` | `public` + contract enforced | Any project — `marketing`, `finance`, Bedrock |

Consumers use **two-argument `ref()`**: `{{ ref('aws_ecommerce', 'fct_orders') }}`

---

## Quickstart (30 minutes)

See [QUICKSTART.md](QUICKSTART.md) for the full step-by-step guide.

The short version:

```bash
# 1. Seed the demo data into Redshift
dbt seed

# 2. Build all 14 models and run all tests
dbt build

# 3. Open Explore in dbt Cloud to see lineage + docs
```

---

## Data model

### Source (raw schema)
Raw tables seeded from CSV — in production, these are loaded by **AWS Glue jobs** from **S3**.

| Table | Rows | Description |
|---|---|---|
| raw_customers | 25 | Customers across 15 AWS regions |
| raw_orders | 125 | Orders from Jan 2024 – Mar 2025 |
| raw_order_items | 173 | Line items (product × quantity × price) |
| raw_products | 18 | Cloud product catalog (storage, compute, security, analytics) |
| raw_product_categories | 6 | Product categories |
| aws_regions | 18 | AWS region → geography (AMER / EMEA / APAC) mapping |

### Mart models (what Bedrock queries)

| Model | Description |
|---|---|
| `fct_customer_lifetime_value` | CLV per customer with ltv_score and ltv_segment |
| `fct_revenue_by_region` | Monthly revenue by AWS geography — answers "EMEA Q1 revenue" questions |
| `fct_orders` | Order fact enriched with customer geography |
| `dim_customers` | Customer dimension with region metadata |
| `fct_product_performance` | Revenue and units sold per product |

### Semantic Layer metrics
Defined in `semantic_models/metrics.yml` — queryable via Bedrock, QuickSight, or `dbt sl query`:

- `total_revenue` — filterable by geography, region, customer_tier, date
- `order_count`
- `avg_order_value`
- `revenue_per_customer`
- `active_customers`

---

## Demo scenes

| Scene | Duration | Key moment |
|---|---|---|
| 1 — The Problem | 2 min | Raw Redshift diagram, no trust, no lineage |
| 2 — dbt Platform Tour | 5 min | IDE → Lineage DAG → Explorer docs |
| 3 — Kiro × MCP × Fusion Engine | 7 min | Agent writes `stg_aws_regions`, Fusion catches error in 2s |
| 4 — dbt → Amazon Bedrock | 6 min | "EMEA revenue Q1 2025" answered via Semantic Layer |
| 5 — Wrap | 2 min | S3 → Redshift → dbt → Bedrock = trusted AI stack |

See [DEMO_SCRIPT.md](DEMO_SCRIPT.md) for the full talk track.

---

## Scene 3 demo prompt (Kiro)

```
Create a new staging model for the aws_regions source table.
Follow our existing staging naming conventions (look at stg_customers.sql as a reference),
add a not_null test for region_code, and document all columns in schema.yml.
```

See [kiro/agent-skill-demo.md](kiro/agent-skill-demo.md) for the full Scene 3 setup.

---

## Scene 4 demo query (Bedrock / dbt Semantic Layer)

```
What was total revenue from EMEA customers in Q1 2025?
```

The Semantic Layer translates this to:
```sql
SELECT SUM(order_revenue)
FROM marts.fct_revenue_by_region
WHERE geography = 'EMEA'
  AND order_month BETWEEN '2025-01-01' AND '2025-03-31'
```

Expected answer: **$68,299.60**

---

## Key talking points

**Why dbt on AWS?**
- Every Bedrock / SageMaker workload needs trusted, governed data. dbt is the trust layer.
- dbt is on **AWS Marketplace** — your customers can start billing to their existing AWS spend.
- The **dbt Semantic Layer** gives Bedrock agents a single, consistent definition of "revenue" — no hallucinated numbers.
- **Fusion Engine** gives AI agents instant compile-time feedback — no warehouse queries needed to discover SQL errors.

**dbt × AWS native services:**

| dbt component | AWS equivalent / integration |
|---|---|
| Sources (S3 → Redshift) | AWS Glue, Firehose, or DMS |
| dbt Cloud IDE | Kiro IDE with dbt MCP Server |
| Lineage graph | Amazon DataZone (complementary) |
| Semantic Layer | Amazon Bedrock Agents (text-to-SQL) |
| dbt tests | AWS Glue Data Quality (complementary) |
| dbt Explorer docs | AWS Glue Data Catalog (complementary) |

---

## Resources

- [dbt on AWS Marketplace](https://aws.amazon.com/marketplace/pp/prodview-tjpcf42nbnhko)
- [dbt Cloud documentation](https://docs.getdbt.com)
- [dbt Semantic Layer integrations](https://docs.getdbt.com/docs/use-dbt-semantic-layer/avail-sl-integrations)
- [dbt MCP Server](https://github.com/dbt-labs/dbt-mcp)
- [Amazon Redshift + dbt adapter](https://docs.getdbt.com/docs/core/connect-data-platform/redshift-setup)
- [dbt Community Slack](https://getdbt.com/community)
