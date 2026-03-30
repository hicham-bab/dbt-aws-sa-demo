# Quickstart: dbt Platform + Amazon Redshift

Get from zero to a running dbt Mesh on Redshift in under 30 minutes.
Written for both **AWS Solutions Architects** (starting from zero AWS setup) and
**dbt Solutions Architects** (who may already have dbt Cloud but need a fresh Redshift target).

---

## What you'll have at the end

Three connected dbt projects — a full dbt Mesh — all running on Amazon Redshift:

| Project | Directory | What it contains |
|---|---|---|
| **AWS Ecommerce Platform** | `platform/` | 14 models, public contracts, Semantic Layer (5 metrics) |
| **Marketing Analytics** | `marketing/` | 2 models — customer segments, region performance |
| **Finance Analytics** | `finance/` | 3 models — revenue recognition, product P&L, geo P&L |

Cross-project lineage visible in dbt Explorer. Fusion LSP active in Kiro / VS Code / Cursor.

---

## Prerequisites

| Requirement | AWS SA path | dbt SA path |
|---|---|---|
| AWS account | Any account, free tier OK | Use a sandbox/demo account |
| Amazon Redshift | Create one (Step 1) | Request a shared demo cluster from your team, or create one |
| dbt Cloud account | Sign up free at cloud.getdbt.com | Use your internal account |
| GitHub account | Needed to fork this repo | Same |

---

## Step 1 — Set up Amazon Redshift

> **dbt SA tip:** If your team has a shared Redshift demo environment, skip to Step 2
> and just run `setup/01_redshift_setup.sql` against it.

### Option A — Redshift Serverless (recommended — fastest to spin up)

1. Open the [Amazon Redshift console](https://console.aws.amazon.com/redshiftv2)
2. If you see a "Try Amazon Redshift Serverless" banner, click it → **Get started**
   - If not: click **Serverless** in the left nav → **Create workgroup**
3. Choose **Use default settings**
   - This creates a workgroup named `default` and a namespace named `default`
4. Under **Credentials**, set an admin username (e.g. `admin`) and a password — **write these down**
5. You'll see a **Permissions** section warning about IAM roles — **skip it**.
   An IAM role is only needed for COPY/UNLOAD from S3. dbt connects with username + password,
   and we load data via `dbt seed` (SQL INSERT, not S3 COPY), so no IAM role is required.
6. Click **Save configuration**
7. Wait ~2 minutes until the workgroup status shows **Available**

**Find your endpoint:**
- Left nav → **Serverless** → **Workgroups** → click `default`
- Under **General information**, find the **Endpoint** field
- It looks like: `default.123456789012.us-east-1.redshift-serverless.amazonaws.com:5439/dev`
- Note it down — you'll need it in Step 4

**Enable public accessibility (required for dbt Cloud):**
- On the same workgroup page → **Actions** → **Edit publicly accessible setting** → turn it **On**
- Without this, dbt Cloud cannot reach your Serverless endpoint from the internet

### Option B — Redshift Provisioned Cluster

1. In the Redshift console, click **Create cluster**
2. Choose **Free trial** (dc2.large) or your preferred node type
3. Under **Database configurations**:
   - Database name: `dev`
   - Admin username: `admin`
   - Admin password: set one and write it down
4. Under **Additional configurations** → expand **Network and security**
   - Enable **Publicly accessible**
5. Click **Create cluster** and wait until status shows **Available**

**Find your endpoint:**
- Click your cluster → **General information** → **Endpoint**
- It looks like: `my-cluster.abc123def456.us-east-1.redshift.amazonaws.com:5439/dev`

### Allow dbt Cloud to reach Redshift (both options)

dbt Cloud connects to Redshift over the internet. You need to open port 5439 in the security group.

1. Go to your cluster/workgroup page → **Properties** tab → **Network and security**
2. Click the link under **VPC security group** to open EC2
3. Click **Edit inbound rules** → **Add rule**:
   - Type: `Custom TCP`
   - Port range: `5439`
   - Source: `Anywhere-IPv4` (`0.0.0.0/0`) — fine for a demo; restrict to
     [dbt Cloud IPs](https://docs.getdbt.com/docs/cloud/about-cloud/access-regions-ip-addresses)
     for production
4. Click **Save rules**

---

## Step 2 — Create the dbt database user and schemas

Open **Redshift Query Editor v2** (no local client needed):
- Redshift console → **Query editor v2** (left nav)
- Connect to your cluster/workgroup and select database `dev`

Run the full script at `platform/setup/01_redshift_setup.sql`. The key parts are:

```sql
-- Create a dedicated user for dbt (don't use your admin for dbt)
CREATE USER dbt_user PASSWORD '<choose-a-strong-password>';

-- Create all schemas dbt will write to
CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS intermediate;
CREATE SCHEMA IF NOT EXISTS marts;
CREATE SCHEMA IF NOT EXISTS marketing;
CREATE SCHEMA IF NOT EXISTS finance;

-- Grant dbt_user access to all schemas
GRANT USAGE, CREATE ON SCHEMA raw          TO dbt_user;
GRANT USAGE, CREATE ON SCHEMA staging      TO dbt_user;
GRANT USAGE, CREATE ON SCHEMA intermediate TO dbt_user;
GRANT USAGE, CREATE ON SCHEMA marts        TO dbt_user;
GRANT USAGE, CREATE ON SCHEMA marketing    TO dbt_user;
GRANT USAGE, CREATE ON SCHEMA finance      TO dbt_user;
```

---

## Step 3 — Create a dbt Cloud account and connect your repo

### Create an account
1. Go to [cloud.getdbt.com](https://cloud.getdbt.com) → **Start for free**
2. Sign up with your work email — no credit card required for the free trial
3. When the setup wizard starts, choose **I'll configure my project manually**

### Fork and connect this repo
1. Fork this repo to your GitHub account
2. In dbt Cloud: **Account settings** (gear icon, top right) → **Integrations** → **GitHub**
3. Click **Link** and authorize dbt Cloud to access your GitHub account
4. You'll be redirected back to dbt Cloud — GitHub is now connected

---

## Step 4 — Connect dbt Cloud to Redshift

This step is where most people hit errors. Read carefully.

### Find the correct hostname

The hostname is the **bare domain name only** — no port, no database name, no protocol prefix.

**From your endpoint (which you noted in Step 1), extract just this part:**

| Your full endpoint | What to paste in dbt Cloud |
|---|---|
| `default.123456789012.us-east-1.redshift-serverless.amazonaws.com:5439/dev` | `default.123456789012.us-east-1.redshift-serverless.amazonaws.com` |
| `my-cluster.abc123.us-east-1.redshift.amazonaws.com:5439/dev` | `my-cluster.abc123.us-east-1.redshift.amazonaws.com` |

**Rule:** Stop at `.amazonaws.com` — strip everything after it (`:5439/dev`).

> **"Create connection error: The request was invalid"** — this error in dbt Cloud almost always
> means the Host field contains the port (`:5439`) or the database (`/dev`). Strip both.

### Create the connection in dbt Cloud

1. In your dbt Cloud project: top nav → **Deploy** → **Connections** → **+ New connection**
   - Alternatively: **Account settings** → **Connections** → **+ New connection**
2. Select **Redshift**
3. Fill in the form exactly as follows:

| Field | Value | Notes |
|---|---|---|
| Connection name | `Redshift Demo` | Any name |
| Host | `<hostname only — see table above>` | No port, no `/dev` |
| Port | `5439` | Always 5439 for Redshift |
| Database | `dev` | Must match the database in your endpoint |
| Username | `dbt_user` | The user you created in Step 2 |
| Password | `<your dbt_user password>` | |

4. Leave all other fields at their defaults
5. Click **Test connection**
   - Green checkmark ✅ → proceed to Save
   - If it times out → your security group is not open (revisit Step 1, the inbound rule)
   - If "authentication failed" → wrong username or password (re-check Step 2)
6. Click **Save**

### Create a development environment

1. **Deploy** → **Environments** → **+ Create environment**
2. Fill in:
   - Name: `Development`
   - Environment type: `Development`
   - Connection: select `Redshift Demo`
3. Click **Save**

### Set your personal developer schema

1. Click your name (top right) → **Profile settings** → **Credentials**
2. Find the project row → click **Edit**
3. Set **Schema**: `dbt_<yourfirstname>` (e.g. `dbt_hicham`)
   — this is your personal dev sandbox, isolated from others
4. Click **Save**

---

## Step 5 — Set up the three Mesh projects

This repo has three independent dbt projects. Each needs its own project in dbt Cloud,
all sharing the same Redshift connection.

### Project 1 — Platform (set this up first)

1. In dbt Cloud: top nav → **Account settings** → **Projects** → **+ New project**
2. Name: `AWS Ecommerce Platform`
3. Repository: select your fork → **Subdirectory**: `platform`
4. Connection: `Redshift Demo`
5. Development schema: `platform_dev`
6. Click **Save**

### Project 2 — Marketing (consumer)

1. **+ New project** → Name: `Marketing Analytics`
2. Same repo → **Subdirectory**: `marketing`
3. Same connection
4. Development schema: `marketing_dev`
5. **Project dependencies**: add `AWS Ecommerce Platform`
   - This tells dbt Cloud how to resolve `ref('aws_ecommerce', 'model_name')` cross-project calls
6. Click **Save**

### Project 3 — Finance (consumer)

1. **+ New project** → Name: `Finance Analytics`
2. Same repo → **Subdirectory**: `finance`
3. Same connection
4. Development schema: `finance_dev`
5. **Project dependencies**: add `AWS Ecommerce Platform`
6. Click **Save**

> **Running locally instead of dbt Cloud?**
> Each project directory has a `profiles.yml.example`. Copy it to `profiles.yml`,
> fill in your Redshift credentials, and run `dbt build` from inside that directory.
> The `platform/` project must be built first.

---

## Step 6 — Load data and build all models

### Open the dbt Cloud IDE for the Platform project

1. In dbt Cloud: switch to the **AWS Ecommerce Platform** project (top nav project picker)
2. Click **Develop** → **Cloud IDE**
3. Wait for the IDE to load and the git status to show "No changes"

### Load the seed data

In the IDE terminal (bottom of the screen), run:

```bash
dbt seed
```

This loads 6 CSV files into the `raw` schema in Redshift:

| Table | Rows | Description |
|---|---|---|
| `raw.raw_customers` | 25 | Customers across AMER / EMEA / APAC |
| `raw.raw_orders` | 125 | Orders Jan 2024 – Mar 2025 |
| `raw.raw_order_items` | 173 | Line items (product × qty × price) |
| `raw.raw_products` | 18 | Cloud product catalog |
| `raw.raw_product_categories` | 6 | Category reference |
| `raw.aws_regions` | 18 | AWS region → geography mapping |

Expected: `Done. PASS=6 WARN=0 ERROR=0`

### Build the platform models

```bash
dbt build
```

Runs in dependency order: seeds → staging (5 views) → intermediate (2 views) → marts (7 tables).
All 7 mart models are built as physical Redshift tables with enforced contracts.

Expected: `Done. PASS=XX WARN=0 ERROR=0 SKIP=0 TOTAL=XX`

### Build the consumer projects

Switch to the **Marketing Analytics** project (project picker, top nav) → open the IDE:

```bash
dbt build
```

Then repeat for **Finance Analytics**.

The consumer models read the platform marts via cross-project `ref()` — dbt Cloud resolves
`ref('aws_ecommerce', 'fct_orders')` to the physical `marts.fct_orders` table in Redshift.

---

## Step 7 — Explore in dbt Cloud

### See the cross-project lineage (the Mesh moment)

1. Top nav → **Explore**
2. Search for `mart_customer_segments` (marketing project)
3. Click **Lineage** tab
4. The graph shows: `marketing.mart_customer_segments` → `aws_ecommerce.fct_customer_lifetime_value`
   → `aws_ecommerce.int_customer_orders` → `aws_ecommerce.stg_orders` → raw source

This is the full Mesh lineage — from S3 (simulated) all the way to a marketing mart,
spanning three separate dbt projects.

### Check the public contract on a platform model

1. In Explore → search for `fct_orders`
2. Click the model → **Details** tab
3. You'll see: `access: public`, `contract: enforced`, all columns with `data_type`
4. Click any consumer project model → its lineage back to `fct_orders` reflects the contract

### Run a failing test (powerful demo moment)

Insert a duplicate customer in Redshift Query Editor v2:
```sql
INSERT INTO raw.raw_customers
  (customer_id, first_name, last_name, email, company, country, aws_region, customer_tier, created_at)
VALUES
  (1, 'Duplicate', 'Customer', 'alice.johnson@techcorp.com', 'Test', 'US', 'us-east-1', 'starter', '2025-01-01');
```

In the dbt Cloud IDE (platform project):
```bash
dbt test --select stg_customers
```

The `unique` test on `customer_id` fails. Clean it up:
```sql
DELETE FROM raw.raw_customers WHERE first_name = 'Duplicate';
```

---

## Step 8 — (Optional) Enable the dbt Semantic Layer

Required for the Bedrock text-to-SQL demo in Scene 4.

1. **Account settings** → **Billing** → confirm you're on Team or Enterprise plan
   (Semantic Layer is not available on the free Developer plan)
2. **Deploy** → **Environments** → open the **Production** environment for the Platform project
3. Under **Semantic Layer**, click **Configure** and note:
   - Host URL
   - Environment ID
   - Service token (create one under **API tokens**)
4. Use these to configure your Bedrock agent or QuickSight connection

Test immediately in the IDE terminal:
```bash
dbt sl query \
  --metrics total_revenue \
  --group-by geography,order_date__month \
  --where "geography = 'EMEA' AND order_date__month BETWEEN '2025-01-01' AND '2025-03-31'"
```

Expected answer: **$68,299.60** — the exact figure for the Scene 4 Bedrock demo.

---

## Step 9 — (Optional) Set up Fusion LSP in Kiro or VS Code

See [`kiro/lsp-setup.md`](kiro/lsp-setup.md) for the full setup guide.

Short version:
1. Open the `platform/` directory in Kiro, VS Code, Cursor, or Windsurf
2. Install the **dbt** extension (publisher: `dbtLabsInc`) from the extensions marketplace
3. The extension downloads the Fusion engine binary automatically on first load
4. Open any `.sql` model file — you'll see autocomplete on `ref()` and `source()`,
   and red squiggles appear within ~2 seconds of a SQL error

---

## Quick reference — dbt commands

```bash
# Run from inside the project directory (platform/, marketing/, or finance/)

# Load CSV seed data into Redshift
dbt seed

# Build everything: models + tests
dbt build

# Build one model and all its upstream dependencies
dbt build --select +fct_customer_lifetime_value

# Run tests only
dbt test

# Compile without hitting the warehouse (Fusion — instant feedback)
dbt compile --select stg_aws_regions

# Query a metric via the Semantic Layer
dbt sl query --metrics total_revenue --group-by geography

# Generate and open docs locally
dbt docs generate && dbt docs serve
```

---

## Troubleshooting

### "Create connection error: The request was invalid"

**Cause:** The Host field in dbt Cloud contains the port or database name.

**Fix:** The Host field must contain the bare hostname only:
- Wrong: `my-cluster.abc123.us-east-1.redshift.amazonaws.com:5439`
- Wrong: `my-cluster.abc123.us-east-1.redshift.amazonaws.com:5439/dev`
- Wrong: `jdbc:redshift://my-cluster.abc123.us-east-1.redshift.amazonaws.com:5439/dev`
- **Correct:** `my-cluster.abc123.us-east-1.redshift.amazonaws.com`

Strip everything after `.amazonaws.com`. Put `5439` in the separate Port field and `dev` in the Database field.

### "Connection timed out" or no response from Test Connection

**Causes and fixes (in order):**
1. Security group not open — verify port 5439 is allowed from `0.0.0.0/0` (or dbt Cloud IPs)
2. Serverless workgroup not publicly accessible — go to workgroup → **Actions** → **Edit publicly accessible setting** → On
3. Workgroup not in Available state — wait and refresh the Redshift console
4. Wrong region — your dbt Cloud account region and Redshift region don't need to match, but confirm the hostname contains the correct region (e.g. `us-east-1`)

### "Authentication failed" or "password authentication failed for user"

- The username or password entered in dbt Cloud doesn't match what you set in Step 2
- Re-run `CREATE USER dbt_user PASSWORD '<password>';` in Query Editor v2 to reset it
- Make sure you're connecting to the `dev` database, not a different one

### "Permission denied" on schema

```sql
-- Run as admin in Query Editor v2
GRANT USAGE, CREATE ON SCHEMA raw          TO dbt_user;
GRANT USAGE, CREATE ON SCHEMA staging      TO dbt_user;
GRANT USAGE, CREATE ON SCHEMA intermediate TO dbt_user;
GRANT USAGE, CREATE ON SCHEMA marts        TO dbt_user;
GRANT USAGE, CREATE ON SCHEMA marketing    TO dbt_user;
GRANT USAGE, CREATE ON SCHEMA finance      TO dbt_user;
```

### `dbt seed` fails with "relation already exists"

```bash
dbt seed --full-refresh
```

### Consumer models fail with "cross-project ref not found"

- Make sure you ran `dbt build` in the **platform/** project first — the marts must exist before consumers can ref them
- In dbt Cloud: confirm the consumer project has **AWS Ecommerce Platform** listed under **Project dependencies**

### dbt Semantic Layer returns no data

- Semantic Layer requires a **Production** environment with a successful `dbt build` run
- Ensure you're using the correct environment ID and service token from Step 8

---

## Resources

| Resource | Link |
|---|---|
| dbt on AWS Marketplace | https://aws.amazon.com/marketplace/pp/prodview-tjpcf42nbnhko |
| dbt Cloud documentation | https://docs.getdbt.com |
| dbt + Redshift adapter docs | https://docs.getdbt.com/docs/core/connect-data-platform/redshift-setup |
| dbt Semantic Layer integrations | https://docs.getdbt.com/docs/use-dbt-semantic-layer/avail-sl-integrations |
| dbt MCP Server (GitHub) | https://github.com/dbt-labs/dbt-mcp |
| dbt Cloud IP ranges (for security groups) | https://docs.getdbt.com/docs/cloud/about-cloud/access-regions-ip-addresses |
| dbt Community Slack | https://getdbt.com/community |
| dbt Learn (free courses) | https://learn.getdbt.com |
