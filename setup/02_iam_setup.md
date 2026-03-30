# IAM Setup for dbt + Redshift

If you prefer IAM authentication over password auth (recommended for production),
follow these steps instead of using a static password.

## Option A — IAM Database Authentication (Redshift Provisioned)

1. **Enable IAM auth on your cluster**
   - In the Redshift console, go to your cluster → Properties → Database configurations
   - Enable "IAM database authentication"

2. **Create an IAM policy for dbt**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "redshift:GetClusterCredentials",
        "redshift:CreateClusterUser",
        "redshift:JoinGroup"
      ],
      "Resource": [
        "arn:aws:redshift:<region>:<account-id>:dbname:<cluster-id>/dev",
        "arn:aws:redshift:<region>:<account-id>:dbuser:<cluster-id>/dbt_user"
      ]
    }
  ]
}
```

3. **Attach policy** to the IAM role/user that runs dbt (e.g. your dbt Cloud connection role).

4. **Update `profiles.yml`** to use IAM:

```yaml
aws_ecommerce:
  target: dev
  outputs:
    dev:
      type: redshift
      method: iam
      cluster_id: <your-cluster-id>
      host: <cluster>.redshift.amazonaws.com
      port: 5439
      dbname: dev
      schema: dbt_dev
      iam_profile: default      # or specify a named AWS profile
      threads: 4
```

## Option B — Redshift Serverless (Workgroup)

For Redshift Serverless, use the workgroup endpoint:

```yaml
aws_ecommerce:
  target: dev
  outputs:
    dev:
      type: redshift
      host: <workgroup-name>.<account-id>.<region>.redshift-serverless.amazonaws.com
      port: 5439
      dbname: dev
      schema: dbt_dev
      user: dbt_user
      password: "{{ env_var('DBT_PASSWORD') }}"
      threads: 4
```

## Option C — dbt Cloud Native Connection (Recommended)

When using dbt Cloud, you can configure the Redshift connection directly in the
**Account Settings → Connections** UI. dbt Cloud stores credentials encrypted and
handles IAM role assumption automatically when you use the AWS Marketplace integration.

See the QUICKSTART.md for the step-by-step dbt Cloud connection setup.
