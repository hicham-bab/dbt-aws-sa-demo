# Kiro Agent Skill — Scene 3 Demo Prompts

These are the exact prompts to use in the Kiro chat during Scene 3 of the demo.

## Step 2 — Invoke the Agent Skill

Paste this into the Kiro chat:

```
Create a new staging model for the aws_regions source table.
Follow our existing staging naming conventions (look at stg_customers.sql as a reference),
add a not_null test for region_code, and document all columns in schema.yml.
```

**What Kiro will do (via MCP):**
1. Call `get_model_details` on `stg_customers` to read naming conventions
2. Call `list_models` to confirm `stg_aws_regions` doesn't already exist
3. Generate `stg_aws_regions.sql` with the correct `source()` macro
4. Append the model and column tests to `models/staging/schema.yml`

## Step 3 — Trigger the Fusion Engine feedback loop

After Kiro generates the model, deliberately introduce an error:

**In `stg_aws_regions.sql`, change:**
```sql
select
    region_code,
    region_name,
    upper(geography) as geography,
    primary_az
from source
```

**To (wrong column name):**
```sql
select
    region_code,
    region_name,
    upper(geo_grouping) as geography,   -- <-- column doesn't exist
    primary_az
from source
```

Then ask Kiro to compile:
```
Compile stg_aws_regions.sql using the Fusion engine.
```

Fusion returns the error in ~2 seconds: `column "geo_grouping" does not exist`.
Kiro self-corrects back to `geography`.

## Step 4 — Run dbt build

In the Kiro terminal or dbt Cloud IDE:
```bash
dbt build --select stg_aws_regions
```

Expected output: model created ✅, 2 tests passed ✅.
