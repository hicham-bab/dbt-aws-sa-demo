# Quickstart: dbt Platform + Amazon Redshift

Get from zero to a running dbt project on Redshift in under 30 minutes.
This guide is written for AWS Solutions Architects trying dbt for the first time.

---

## What you'll have at the end

- A **dbt Mesh** with 3 projects connected to the same Redshift cluster:
  - `platform/` — 14 models (staging → intermediate → marts), public contracts, Semantic Layer
  - `marketing/` — 2 consumer models using cross-project `ref()`
  - `finance/` — 3 consumer models using cross-project `ref()`
- Auto-generated documentation and lineage graph spanning all three projects in dbt Explorer
- A Semantic Layer with 5 metrics ready for Bedrock or QuickSight to query
- Fusion LSP active in Kiro (or VS Code/Cursor) for live SQL feedback

---

## Prerequisites

| Requirement | Notes |
|---|---|
| AWS account | Any account works. Free tier is fine for the demo. |
| Amazon Redshift | Provisioned cluster **or** Serverless workgroup (see Step 1) |
| dbt Cloud account | Free trial at [cloud.getdbt.com](https://cloud.getdbt.com) — no credit card required |
| Git repo | Fork/clone this repo to your GitHub account |

---

## Step 1 — Set up Amazon Redshift

### Option A — Redshift Serverless (fastest, recommended for demos)

1. Open the [Redshift console](https://console.aws.amazon.com/redshiftv2)
2. Click **Try Amazon Redshift Serverless** → **Get started**
3. Choose **Use default settings** (creates a `default` workgroup and namespace)
4. Set an admin username and password — **save these**, you'll need them for dbt
5. Click **Save configuration** — the workgroup will be ready in ~2 minutes
6. Note your **endpoint**: `default.<account-id>.<region>.redshift-serverless.amazonaws.com`

### Option B — Redshift Provisioned Cluster

1. In the Redshift console, click **Create cluster**
2. Choose **Free trial** (dc2.large, 2 nodes) or your preferred node type
3. Set database name: `dev`, admin username: `admin`, and a password
4. Under **Additional configurations** → enable **Publicly accessible** if connecting from dbt Cloud
5. Note your cluster endpoint once the cluster status shows **Available**

### Make Redshift reachable from dbt Cloud

dbt Cloud connects to Redshift over the internet (from Redshift's perspective).
You need to allow inbound traffic on port **5439** from dbt Cloud's IP ranges.

1. Go to your cluster/workgroup → **Properties** → **Network and security**
2. Click the VPC security group → **Edit inbound rules**
3. Add a rule:
   - Type: **Custom TCP**
   - Port: **5439**
   - Source: **Custom** — paste the dbt Cloud IP ranges from [docs.getdbt.com/docs/cloud/about-cloud/access-regions-ip-addresses](https://docs.getdbt.com/docs/cloud/about-cloud/access-regions-ip-addresses) for your dbt Cloud region
4. Save the rule

> **Tip:** For a quick demo, you can temporarily allow `0.0.0.0/0` on port 5439, then restrict it after.

---

## Step 2 — Create the dbt database user

Connect to Redshift using the **Query Editor v2** in the AWS console (no client install needed).

Select your cluster/workgroup and database `dev`, then run the contents of [`setup/01_redshift_setup.sql`](setup/01_redshift_setup.sql):

```sql
-- Key commands (full script in setup/01_redshift_setup.sql)
CREATE USER dbt_user PASSWORD '<your-strong-password>';

CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS intermediate;
CREATE SCHEMA IF NOT EXISTS marts;

GRANT USAGE, CREATE ON SCHEMA raw         TO dbt_user;
GRANT USAGE, CREATE ON SCHEMA staging     TO dbt_user;
GRANT USAGE, CREATE ON SCHEMA intermediate TO dbt_user;
GRANT USAGE, CREATE ON SCHEMA marts       TO dbt_user;
```

---

## Step 3 — Create a dbt Cloud account and project

1. Sign up at [cloud.getdbt.com](https://cloud.getdbt.com) (free trial, no card required)
2. When prompted, choose **Start with a sample project** → then **I'll create my own project** to use this repo

### Connect your Git repository

1. Go to **Account settings** → **Integrations** → **GitHub** → click **Link**
2. Authorize dbt Cloud to access your GitHub account
3. In your new project: **Settings** → **Repository** → select your fork of this repo

---

## Step 4 — Connect dbt Cloud to Redshift

In your dbt Cloud project:

1. Go to **Settings** → **Connections** → click **+ Add connection**
2. Select **Redshift**
3. Fill in the form:

| Field | Value |
|---|---|
| Name | `AWS Demo Redshift` |
| Host | Your cluster endpoint (without `:5439`) |
| Port | `5439` |
| Database | `dev` |
| Username | `dbt_user` |
| Password | The password you set in Step 2 |

4. Click **Test connection** — you should see a green checkmark
5. Click **Save**

### Set up a development environment

1. Go to **Deploy** → **Environments** → click **+ Create environment**
2. Name it `Development`, type `Development`
3. Select your Redshift connection
4. Set **Default schema**: `dbt_dev` (this becomes your personal dev sandbox)
5. Save

### Set your developer credentials

1. Click your name (top right) → **Profile** → **Credentials**
2. Find your project → click **Edit**
3. Set schema: `dbt_<yourname>` (e.g. `dbt_alice`)
4. Save

---

## Step 5 — Set up the dbt Mesh projects in dbt Cloud

This repo has three dbt projects. In dbt Cloud you set each up as its own project,
all pointing to the same Redshift connection.

### 5a — Platform project (do this first)

1. In dbt Cloud, create a new project named **AWS Ecommerce Platform**
2. Set the **repository subdirectory** to `platform/`
3. Use the Redshift connection from Step 4
4. Set the default schema to `dbt_dev` for development

### 5b — Marketing consumer project

1. Create a second project named **Marketing Analytics**
2. Same repo, subdirectory `marketing/`
3. Same Redshift connection
4. In **Project settings** → **Dependencies**, add the **AWS Ecommerce Platform** project
   - This tells dbt Cloud how to resolve `ref('aws_ecommerce', '...')` calls
5. Default schema: `marketing_dev`

### 5c — Finance consumer project

1. Create a third project named **Finance Analytics**
2. Same repo, subdirectory `finance/`
3. Same Redshift connection
4. **Dependencies** → add **AWS Ecommerce Platform**
5. Default schema: `finance_dev`

> **Running locally?** Each project directory has a `profiles.yml.example`.
> Copy it to `profiles.yml`, fill in your Redshift credentials, and run
> `dbt build` from inside that directory.

---

## Step 6 — Load seed data and build the platform

All seed data lives in the platform project. **Run from the `platform/` directory:**

In the dbt Cloud IDE for the platform project:

```bash
dbt seed
```

This loads 6 CSV files into your `raw` schema in Redshift:
- `raw.raw_customers` (25 rows — customers across AMER / EMEA / APAC)
- `raw.raw_orders` (125 rows — 2024–2025 orders)
- `raw.raw_order_items` (173 rows — line items)
- `raw.raw_products` (18 rows — product catalog)
- `raw.raw_product_categories` (6 rows)
- `raw.aws_regions` (18 rows — AWS region reference)

Expected output: `Done. PASS=6 WARN=0 ERROR=0`

Then build all platform models:

```bash
dbt build
```

14 models built: staging (5) → intermediate (2) → marts (7).
Expected output: `Done. PASS=XX WARN=0 ERROR=0 SKIP=0 TOTAL=XX`

Then build the consumer projects (each from their own IDE or directory):

```bash
# Marketing project
cd ../marketing && dbt build

# Finance project
cd ../finance && dbt build
```

The consumer projects read the platform marts via cross-project `ref()` —
dbt resolves these to the actual Redshift tables in the `marts` schema.

---

## Step 7 — Explore in dbt Cloud

### Lineage graph
- In the IDE, click **Lineage** (bottom left of the editor) to see the full DAG
- Or open **Explore** (top nav) → find any model → click **Lineage** tab

### Auto-generated docs
- Click **Explore** → search for `fct_customer_lifetime_value`
- Click the model → see: description, column docs, test coverage, upstream/downstream lineage
- Use the search bar to find `total_revenue` — see which models define it

### Run a failing test (optional — good for demos)
Add a bad row in Redshift Query Editor v2:
```sql
INSERT INTO raw.raw_customers (customer_id, first_name, last_name, email, company, country, aws_region, customer_tier, created_at)
VALUES (1, 'Duplicate', 'Customer', 'alice.johnson@techcorp.com', 'Test', 'US', 'us-east-1', 'starter', '2025-01-01');
```
Then run `dbt test --select stg_customers` — watch the `unique` test fail.
Roll back: `DELETE FROM raw.raw_customers WHERE first_name = 'Duplicate';`

---

## Step 8 — (Optional) Connect the dbt Semantic Layer

To enable the Semantic Layer for Bedrock or QuickSight:

1. Go to **Account settings** → **Billing** → ensure you're on a plan with Semantic Layer access (Team or Enterprise)
2. Go to **Deploy** → **Environments** → open your **Production** environment
3. Under **Semantic Layer**, click **Configure** and note the connection details
4. Use these details to configure your Bedrock agent or JDBC connection

The 5 metrics defined in `platform/semantic_models/metrics.yml` will be available immediately:
- `total_revenue` — filterable by geography, region, customer_tier, date
- `order_count`
- `avg_order_value`
- `revenue_per_customer`
- `active_customers`

**Example MetricFlow query:**
```bash
# In the dbt Cloud IDE terminal
dbt sl query --metrics total_revenue --group-by geography,order_date__month --where "geography = 'EMEA'"
```

---

## Quick reference — useful dbt commands

```bash
# Load seed data
dbt seed

# Build everything (seed + models + tests)
dbt build

# Build only staging models
dbt build --select staging

# Build a specific model and all its upstream dependencies
dbt build --select +fct_customer_lifetime_value

# Run tests only
dbt test

# Generate and serve docs locally
dbt docs generate && dbt docs serve

# Compile a model without executing (Fusion Engine — instant, no warehouse)
dbt compile --select stg_aws_regions
```

---

## Troubleshooting

### "Connection refused" or timeout
- Check your Redshift security group allows inbound port 5439 from dbt Cloud IPs
- For Serverless, verify the workgroup is in "Available" state

### "Permission denied" on schema
- Reconnect to Redshift as admin and re-run `setup/01_redshift_setup.sql`
- Ensure `GRANT USAGE, CREATE ON SCHEMA` was run for all 4 schemas

### Seeds fail with "relation already exists"
- Run `dbt seed --full-refresh` to drop and recreate seed tables

### Models fail with "schema does not exist"
- dbt creates schemas automatically. If it fails, run the `CREATE SCHEMA` statements in `setup/01_redshift_setup.sql` manually as admin.

### dbt Cloud can't reach Redshift
- Confirm your cluster is set to **Publicly accessible** (Provisioned) or your Serverless workgroup has public access enabled
- Test connectivity: in Query Editor v2 → your cluster should show "Connected"

---

## What's next

- [dbt Learn](https://learn.getdbt.com) — free courses, including a Redshift-specific path
- [dbt Slack](https://getdbt.com/community) — 60,000+ practitioners
- [dbt on AWS Marketplace](https://aws.amazon.com/marketplace/pp/prodview-tjpcf42nbnhko) — start a trial in your existing AWS account
- [Amazon Bedrock + dbt Semantic Layer](https://docs.getdbt.com/docs/use-dbt-semantic-layer/avail-sl-integrations) — connect your metrics to Bedrock agents
