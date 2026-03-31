# Kiro × dbt Semantic Layer — AI-Ready Demo Guide

**Add-on to Scene 3 or Scene 4 in the main demo script (~3 min)**

---

## The Story

Every AWS AI service — Bedrock, QuickSight Q, SageMaker — needs a consistent answer
to "what does revenue mean?" Without a Semantic Layer, each AI tool invents its own
definition. With dbt, there is one definition, governed, versioned, and tested.

```
Kiro IDE  ──┐
            │  dbt MCP Server
Bedrock   ──┤  ──────────────▶  Semantic Layer  ──▶  Redshift
            │  (structured       (metrics.yml)        (trusted data)
QuickSight──┘   tool calls)
```

---

## Demo Step 1 — Show Kiro has full Semantic Layer context

Open Kiro IDE chat. Type:

```
What metrics are defined in this dbt project?
```

Kiro calls `mcp__dbt_MCP_Server__list_metrics` and returns all 11 metrics:
`total_revenue`, `order_count`, `avg_order_value`, `revenue_per_customer`,
`active_customers`, `avg_ltv`, `product_revenue`, `units_sold`,
`revenue_ytd`, `revenue_trailing_3m`, `revenue_mom_growth`

> "Kiro didn't read from a wiki or Confluence — it read the actual metric
> definitions from the project, live, via the MCP Server. Same definitions
> that power Bedrock, QuickSight, and every dashboard."

---

## Demo Step 2 — Executive KPI snapshot

Ask Kiro:

```
Run the executive_kpis saved query and show me the results.
```

Kiro executes:
```bash
dbt sl query --saved-query executive_kpis
```

Returns a single-row KPI snapshot — total revenue, orders, AOV, active customers,
revenue per customer, and YTD revenue.

> "This is a Bedrock briefing agent's answer to 'give me the business summary.'
> Not a hallucination. A governed query against tested, lineage-tracked data."

---

## Demo Step 3 — The EMEA geography question

Ask Kiro:

```
Using the dbt Semantic Layer, what was total revenue
from EMEA customers in Q1 2025?
```

Kiro runs:
```bash
dbt sl query \
  --saved-query revenue_by_geography \
  --where "Dimension('order__geography') = 'EMEA'" \
  --start-time 2025-01-01 \
  --end-time 2025-03-31
```

Expected answer: **$68,299.60**

> "That answer is auditable. You can trace it from this response back to
> fct_revenue_by_region → int_orders_enriched → the raw Kinesis stream in S3.
> Lineage-backed AI. That's what AWS customers need."

---

## Demo Step 4 — Customer segment breakdown

Ask Kiro:

```
Which customer segment drives the most revenue?
Show me revenue and average LTV per segment.
```

Kiro runs `customer_segment_performance` saved query.

> "The marketing team's segmentation logic and the platform team's revenue
> definition — accessible through one interface, without either team
> duplicating work or diverging definitions."

---

## Demo Step 5 — Month-over-month growth (time spine in action)

Ask Kiro:

```
What is the month-over-month revenue growth trend for 2024?
```

Kiro runs:
```bash
dbt sl query \
  --metrics revenue_mom_growth \
  --group-by order__order_date__month \
  --start-time 2024-01-01 \
  --end-time 2024-12-31
```

> "This metric uses a time spine — a calendar table dbt manages — to compute
> period-over-period comparisons. The logic lives in dbt once. Bedrock,
> QuickSight, and SageMaker all inherit it automatically."

---

## Talking Points

**dbt as the AI Control Plane**
> "dbt is not a BI tool. It's the context layer between your raw AWS data
> infrastructure and every AI consumer. It answers three questions every AI
> needs: What does this data mean? Where did it come from? Can I trust it?"

**One Definition, Many Consumers**
> "total_revenue is defined once in metrics.yml. When Bedrock asks for revenue,
> when QuickSight renders a chart, when SageMaker pulls a training feature,
> when Kiro answers a prompt — they all get the same number. Not luck.
> Enforcement."

**Iceberg + Open Lakehouse**
> "For customers on S3 with Apache Iceberg — dbt is the same Context Layer.
> Same models, tests, lineage, docs — but writing open Iceberg table formats
> via Athena or Redshift instead of proprietary tables. The AI readiness
> story is identical: any tool can consume it."

**AWS Marketplace**
> "dbt Platform is on AWS Marketplace. Start today, in the account they
> already have, billed against existing AWS committed spend."
