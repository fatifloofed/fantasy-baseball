<div align="center">
  <img src="https://icon.icepanel.io/Technology/svg/HashiCorp-Terraform.svg" title="Terraform" alt="Terraform" width="180" height="180" />

  <h1>3-Tier Web Architecture — Terraform</h1>
  <p>Infrastructure-as-Code for a secure, production-grade 3-tier web application on AWS.<br/>
  Deployed via GitLab CI/CD using Terraform and the GitLab-managed HTTP backend.</p>

  ![Terraform](https://img.shields.io/badge/Terraform-≥1.14-7B42BC?logo=terraform)
  ![AWS Provider](https://img.shields.io/badge/AWS_Provider-%3C6.0-FF9900?logo=amazonaws)
  ![License](https://img.shields.io/badge/License-MIT-blue)

</div>

---

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Module Structure](#module-structure)
- [Prerequisites](#prerequisites)
  - [Required Tools](#required-tools)
  - [AWS IAM Setup — Deployment Role](#aws-iam-setup--deployment-role)
  - [AWS Access Key Configuration](#aws-access-key-configuration)
  - [ACM Certificate](#acm-certificate)
- [Configuration](#configuration)
  - [Environment Variable Files](#environment-variable-files)
  - [Required Variables Reference](#required-variables-reference)
- [GitLab CI/CD Pipeline](#gitlab-cicd-pipeline)
  - [Pipeline Triggers](#pipeline-triggers)
  - [Required CI/CD Variables](#required-cicd-variables)
  - [Pipeline Stages](#pipeline-stages)
- [Deploying Manually](#deploying-manually)
- [Destroying Infrastructure](#destroying-infrastructure)
- [Post-Deployment Steps](#post-deployment-steps)
- [Security Notes](#security-notes)

---

## Architecture Overview

```
Internet
    │
    ▼ HTTPS
┌─────────────────────────────────────────────────────────┐
│  PRESENTATION TIER                                      │
│  CloudFront CDN                                         │
│    ├── /*        ──OAC──▶  S3 (private, static assets) │
│    └── /api/*    ──────▶   Application ALB              │
└──────────────────────────────┬──────────────────────────┘
                               │ HTTPS (certificate required)
                               ▼
┌──────────────────────────────────────────────────────────┐
│  APPLICATION TIER  (private subnets)                     │
│  ALB  ──▶  ECS Fargate Cluster                          │
│              ├── API Service        (auto-scales)        │
│              ├── Worker Service     (FARGATE_SPOT)       │
│              └── Scheduled Task     (EventBridge cron)   │
└──────────────────────────────┬───────────────────────────┘
                               │ port 5432
                               ▼
┌──────────────────────────────────────────────────────────┐
│  DATA TIER  (isolated subnets — no internet route)       │
│  RDS PostgreSQL 16  (Multi-AZ configurable)              │
└──────────────────────────────────────────────────────────┘
```


---

## Module Structure

```
.
├── main.tf                   # Root module — wires all child modules together
├── variables.tf              # All input variable declarations
├── outputs.tf                # CloudFront domain + distribution ID
├── locals.tf                 # name_prefix = "${application}-${environment}"
├── providers.tf              # AWS provider, backend, version constraints
├── values/
│   ├── dev.tfvars            # Development environment values
│   ├── uat.tfvars            # UAT environment values
│   └── prod.tfvars           # Production environment values
└── modules/
    ├── network/              # VPC, subnets (3 tiers), IGW, NAT GWs, route tables, NACLs
    ├── security/             # Security Groups (ALB, App, DB, VPC Endpoint)
    ├── kms/                  # Customer-managed KMS keys (secrets, services, CloudWatch)
    ├── secrets/              # Secrets Manager secrets for DB and app credentials
    ├── iam/                  # ECS execution role + task role with scoped policies
    ├── s3/                   # Web assets bucket (CloudFront OAC) + ALB log bucket
    ├── cloudfront/           # CloudFront distribution with OAC → S3
    ├── alb/                  # Application Load Balancer, HTTPS listener, target group
    ├── ecr/                  # ECR repositories (api, worker, scheduled-task) with KMS + lifecycle
    ├── ecs/                  # ECS cluster, task definitions, services, auto-scaling, EventBridge
    ├── rds/                  # RDS PostgreSQL instance, parameter group, enhanced monitoring
    ├── endpoints/            # VPC Interface Endpoints (ECR, Secrets Manager, CloudWatch Logs)
    └── monitoring/           # CloudWatch Log Groups with KMS encryption and retention
```

---

## Prerequisites

### Required Tools

Install the following on your local machine before working with this repository.

| Tool | Minimum Version | Installation |
|---|---|---|
| [Terraform](https://developer.hashicorp.com/terraform/install) | 1.14.0 | `brew install terraform` or [official installer](https://developer.hashicorp.com/terraform/install) |
| [AWS CLI](https://aws.amazon.com/cli/) | 2.x | `brew install awscli` or [official installer](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) |
| [Git](https://git-scm.com/) | 2.x | `brew install git` ||
| [tflint](https://github.com/terraform-linters/tflint) | 0.50+ | `brew install tflint` |

Verify your installations:

```bash
terraform version
aws --version
tflint --version
```

---

### AWS IAM Setup — Deployment Role

Terraform deploys by **assuming a dedicated IAM role** (`assume_role_arn` in your `.tfvars`). This follows AWS best practices for least-privilege CI/CD deployments — no long-lived access keys with admin permissions are needed.

#### Step 1 — Create the Terraform Deployment Role

In the AWS Console or via the CLI, create an IAM role that Terraform will assume:

```bash
# Create the role with a trust policy (replace ACCOUNT_ID with your AWS account ID)
aws iam create-role \
  --role-name terraform-deployer \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "AWS": "arn:aws:iam::ACCOUNT_ID:root"
        },
        "Action": "sts:AssumeRole",
        "Condition": {
          "Bool": {
            "aws:MultiFactorAuthPresent": "true"
          }
        }
      }
    ]
  }'
```

> **For CI/CD (GitLab runners):** Modify the trust policy to allow the GitLab runner's IAM user or role to assume it, and remove the `MultiFactorAuthPresent` condition since runners cannot use MFA.

#### Step 2 — Attach Permissions to the Role

This project requires the following managed policies attached to the `terraform-deployer` role:

```bash
ROLE_NAME="terraform-deployer"

policies=(
  "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
  "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
  "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
  "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
  "arn:aws:iam::aws:policy/AWSKeyManagementServicePowerUser"
  "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
  "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  "arn:aws:iam::aws:policy/CloudFrontFullAccess"
  "arn:aws:iam::aws:policy/IAMFullAccess"
  "arn:aws:iam::aws:policy/AmazonEventBridgeFullAccess"
)

for policy in "${policies[@]}"; do
  aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn "$policy"
  echo "Attached: $policy"
done
```

> For a hardened production setup, replace the managed policies above with a single custom inline policy scoped to the specific resource ARNs in your account.

#### Step 3 — Note the Role ARN

```bash
aws iam get-role --role-name terraform-deployer --query 'Role.Arn' --output text
# Output: arn:aws:iam::123456789012:role/terraform-deployer
```

Use this ARN as `assume_role_arn` in your `.tfvars` file.

---

### AWS Access Key Configuration

Terraform uses the AWS CLI credentials to call `sts:AssumeRole` and obtain temporary credentials for the deployment role. There are two setups depending on your context.

#### Option A — Local Development (Named Profile with MFA)

This is the recommended approach for running Terraform locally. It uses a named AWS CLI profile that is configured to assume the deployment role.

**1. Create or verify a base IAM user** in the AWS Console that has only `sts:AssumeRole` permission on the deployment role:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": "arn:aws:iam::ACCOUNT_ID:role/terraform-deployer",
      "Condition": {
        "Bool": { "aws:MultiFactorAuthPresent": "true" }
      }
    }
  ]
}
```

**2. Generate access keys** for this IAM user in the AWS Console under **IAM → Users → [your user] → Security credentials → Create access key**. Choose the "Command Line Interface (CLI)" use case.

**3. Configure the AWS CLI** with the base credentials and a profile that assumes the deployment role:

```bash
# Configure the base credential profile
aws configure --profile terraform-base
# AWS Access Key ID: AKIAIOSFODNN7EXAMPLE
# AWS Secret Access Key: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
# Default region name: eu-west-1
# Default output format: json
```

**4. Add a role-assuming profile** to `~/.aws/config`:

```ini
[profile terraform-deployer]
role_arn       = arn:aws:iam::123456789012:role/terraform-deployer
source_profile = terraform-base
mfa_serial     = arn:aws:iam::123456789012:mfa/your-iam-username
region         = eu-west-1
```

> If your deployment role does not require MFA (e.g. for a sandbox account), omit the `mfa_serial` line.

**5. Test the configuration:**

```bash
AWS_PROFILE=terraform-deployer aws sts get-caller-identity
```

You should be prompted for your MFA token, then see a response showing the assumed role ARN.

**6. Use the profile with Terraform:**

```bash
export AWS_PROFILE=terraform-deployer
terraform init
terraform plan -var-file=values/dev.tfvars
```

---

#### Option B — GitLab CI/CD Runner (OIDC or Access Key)

The GitLab pipeline assumes the deployment role automatically. There are two ways to provide the base credentials to the runner.

**Recommended: OIDC Federation (no long-lived access keys)**

Configure your GitLab runner to use OIDC to assume the deployment role directly. Add the following to the trust policy of your `terraform-deployer` role:

```json
{
  "Effect": "Allow",
  "Principal": {
    "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/gitlab.com"
  },
  "Action": "sts:AssumeRoleWithWebIdentity",
  "Condition": {
    "StringEquals": {
      "gitlab.com:aud": "https://gitlab.com"
    },
    "StringLike": {
      "gitlab.com:sub": "project_path:your-group/your-project:ref_type:branch:ref:main"
    }
  }
}
```

Then in `.gitlab-ci.yml`, add the `id_tokens` block and use `AWS_ROLE_ARN` to configure the provider — no secrets stored in GitLab at all.

**Alternative: Static Access Key (simpler, less secure)**

If OIDC is not available, create a dedicated CI IAM user with only `sts:AssumeRole` permission. Generate an access key pair and store them as **protected, masked** CI/CD variables in GitLab (**Settings → CI/CD → Variables**):

| Variable Name | Description | Flags |
|---|---|---|
| `AWS_ACCESS_KEY_ID` | Access key ID for the CI IAM user | Protected, Masked |
| `AWS_SECRET_ACCESS_KEY` | Secret access key for the CI IAM user | Protected, Masked |
| `AWS_DEFAULT_REGION` | Deployment region (e.g. `eu-west-1`) | Protected |

The `providers.tf` `assume_role` block will then use these credentials to assume `var.assume_role_arn` (set in your `.tfvars`) when Terraform runs.

> **Never commit** access keys or secret values to this repository. All secrets must flow through CI/CD variables or AWS Secrets Manager.

---

### ACM Certificate

The ALB HTTPS listener requires a valid ACM certificate **in the same region as your deployment**.

**1. Request the certificate:**

```bash
aws acm request-certificate \
  --domain-name "api.yourdomain.com" \
  --validation-method DNS \
  --region eu-west-1
```

**2. Complete DNS validation** by adding the CNAME records provided by ACM to your DNS provider. The certificate status will change to `ISSUED` once validated (typically within a few minutes).

**3. Retrieve the ARN:**

```bash
aws acm list-certificates --region eu-west-1 \
  --query 'CertificateSummaryList[?DomainName==`api.yourdomain.com`].CertificateArn' \
  --output text
```

**4. Set the ARN** in your `.tfvars` file:

```hcl
certificate_arn = "arn:aws:acm:eu-west-1:123456789012:certificate/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

> **CloudFront custom domain:** If you also want a custom domain on CloudFront (not just the default `*.cloudfront.net` domain), you need a **second certificate in `us-east-1`** regardless of your deployment region — this is a CloudFront-specific AWS requirement. Uncomment the `domain_aliases` and `acm_certificate_arn` variables in the relevant `.tfvars` and in `modules/cloudfront/main.tf`.

---

---

## Configuration

### Environment Variable Files

Environment-specific values live in `values/`. The `.gitlab-ci.yml` pipeline selects the correct file automatically based on the branch (`dev.tfvars` on `dev`, `uat.tfvars` on `uat`, `prod.tfvars` on `main`).

For local runs, pass the file explicitly:

```bash
terraform plan  -var-file=values/dev.tfvars
terraform apply -var-file=values/dev.tfvars
```

---

### Required Variables Reference

The table below lists every variable with **no default value** — these must be present in your `.tfvars` file or the plan will fail.

| Variable | Type | Description | Example |
|---|---|---|---|
| `application` | `string` | Application name. Used in all resource names and tags. | `"my-app"` |
| `environment` | `string` | Deployment environment. Must be `dev`, `uat`, or `prod`. | `"prod"` |
| `aws_account_id` | `string` | Target AWS account ID. | `"123456789012"` |
| `assume_role_arn` | `string` | IAM role ARN that Terraform assumes to deploy. | `"arn:aws:iam::123456789012:role/terraform-deployer"` |
| `aws_region` | `string` | AWS region for all resources. | `"eu-west-1"` |
| `vpc_cidr_block` | `string` | VPC CIDR block. | `"10.0.0.0/16"` |
| `public_subnets` | `map(object)` | Public subnets — one per AZ. Used by ALB and NAT Gateways. | See example below |
| `private_app_subnets` | `map(object)` | Private subnets for ECS tasks. | See example below |
| `private_db_subnets` | `map(object)` | Isolated subnets for RDS. No internet route. | See example below |
| `certificate_arn` | `string` | ACM certificate ARN for the ALB HTTPS listener. Same region as deployment. | `"arn:aws:acm:eu-west-1:123456789012:certificate/..."` |
| `capacity_providers` | `list(string)` | ECS capacity providers. Put `FARGATE` first. | `["FARGATE", "FARGATE_SPOT"]` |

**Subnet object shape:**

```hcl
public_subnets = {
  web_1 = { cidr_block = "10.0.1.0/24", az = "eu-west-1a" }
  web_2 = { cidr_block = "10.0.2.0/24", az = "eu-west-1b" }
}

private_app_subnets = {
  app_1 = { cidr_block = "10.0.11.0/24", az = "eu-west-1a" }
  app_2 = { cidr_block = "10.0.12.0/24", az = "eu-west-1b" }
}

private_db_subnets = {
  db_1 = { cidr_block = "10.0.21.0/24", az = "eu-west-1a" }
  db_2 = { cidr_block = "10.0.22.0/24", az = "eu-west-1b" }
}
```

> Each subnet map key must be unique. The network module derives NAT Gateway → route table associations from the `az` field, so every `private_app_subnet` must share its AZ with exactly one `public_subnet`.

**Variables with defaults** (override in `.tfvars` as needed):

| Variable | Default | Notes |
|---|---|---|
| `ecs_task_cpu` | `256` | 0.25 vCPU |
| `ecs_task_memory` | `512` | MiB |
| `api_desired_count` | `2` | Minimum for HA |
| `worker_desired_count` | `1` | |
| `container_port` | `8080` | |
| `db_instance_class` | `db.t3.medium` | |
| `db_name` | `appdb` | |
| `db_engine_version` | `16.2` | PostgreSQL |
| `db_allocated_storage` | `20` | GiB |
| `db_max_allocated_storage` | `100` | GiB — autoscaling ceiling |
| `db_multi_az` | `false` | Set `true` for production |

---

## GitLab CI/CD Pipeline

### Pipeline Triggers

The pipeline triggers automatically based on branch and event type:

| Branch / Event | Environment | Behaviour |
|---|---|---|
| MR targeting `dev` | `dev` | Runs full pipeline; apply is manual |
| MR targeting `uat` | `uat` | Runs full pipeline; apply is manual |
| MR targeting `main` | `prod` | Runs full pipeline; apply is manual |
| Push to `main` | `prod` | Runs full pipeline; apply is manual |
| Git tags | — | Pipeline is skipped |

### Required CI/CD Variables

Configure these in **GitLab → Settings → CI/CD → Variables** before running the pipeline. All should be marked **Protected** and **Masked**.

| Variable | Description | Where to get it |
|---|---|---|
| `TF_HTTP_USER` | GitLab username or access token name used to authenticate with the GitLab HTTP Terraform state backend | Create a **Project** or **Group Access Token** with `api` scope in GitLab |
| `TF_HTTP_PW` | Password or token value paired with `TF_HTTP_USER` | The token value shown once at creation |
| `AWS_ACCESS_KEY_ID` | *(If not using OIDC)* Access key ID for the CI IAM user | AWS Console → IAM → User → Security credentials |
| `AWS_SECRET_ACCESS_KEY` | *(If not using OIDC)* Secret access key for the CI IAM user | Shown once at key creation |
| `AWS_DEFAULT_REGION` | *(If not using OIDC)* AWS region | e.g. `eu-west-1` |

> The `assume_role_arn` that Terraform actually deploys with is set per-environment inside the relevant `.tfvars` file, not as a CI variable. This means each environment can target a different AWS account and role.

### Pipeline Stages

```
pre-build ──────────────────────────────────── build ──── deploy
    │                                            │           │
    ├── tf-init    (init + backend config)       │           │
    ├── tf-validate (syntax + consistency)       │           │
    ├── tf-fmt     (formatting check)            │           │
    └── tflint     (AWS rule linting)            │           │
                                                 │           │
                                          tf-plan           │
                                      (creates tfplan       │
                                       artifact + JSON)     │
                                                            │
                                                     tf-apply (manual)
                                                   (applies tfplan artifact)
```

The `tf-apply` job requires manual approval — navigate to **CI/CD → Pipelines**, find the successful plan, and click the ▶ play button next to `tf-apply`.

---

## Deploying Manually

Use this approach for local development, initial bootstrapping, or when you need to deploy outside of the CI pipeline.

**1. Clone and enter the repository:**

```bash
git clone <repository-url>
cd <repository-name>
```

**2. Set your AWS credentials profile:**

```bash
export AWS_PROFILE=terraform-deployer
# Verify role assumption works
aws sts get-caller-identity
```


**3. Initialise Terraform:**

```bash
terraform init
```

For a local backend (no GitLab state), the `backend "local" {}` block in `providers.tf` is already configured. For the GitLab HTTP backend used in CI, you will need to pass `-backend-config` flags as the pipeline does, or temporarily switch to `backend "local" {}` for local experimentation.

**4. Plan against your target environment:**

```bash
terraform plan -var-file=values/dev.tfvars -out=tfplan
```

Review the plan output carefully. Confirm the resource count and that no unexpected changes are shown.

**5. Apply:**

```bash
terraform apply tfplan
```

**6. Retrieve the CloudFront domain:**

```bash
terraform output cloudfront_domain_name
```

Open the domain in a browser — you should see the default CloudFront response (until you deploy frontend assets to S3).

**7. Deploy your frontend assets to S3:**

```bash
# Build your SPA (adjust the build command to your framework)
npm run build

# Sync to the S3 web assets bucket
aws s3 sync ./dist/ s3://$(terraform show -json | jq -r '.values.outputs.cloudfront_domain_name') --delete

# Invalidate the CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id $(terraform output -raw cloudfront_distribution_id) \
  --paths "/*"
```

**8. Push your container images to ECR:**

```bash
REGION="eu-west-1"
ACCOUNT_ID="123456789012"
APP="my-app"
ENV="dev"

# Authenticate Docker with ECR
aws ecr get-login-password --region $REGION | \
  docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

# Build, tag, and push each image
for service in api worker scheduled-task; do
  docker build -t ${APP}-${ENV}/${service}:latest ./services/${service}
  docker tag ${APP}-${ENV}/${service}:latest \
    ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${APP}-${ENV}/${service}:latest
  docker push \
    ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${APP}-${ENV}/${service}:latest
done
```

**9. Rotate the placeholder secrets:**

Terraform seeds Secrets Manager with `"rotate-me-please"` placeholder values. Replace them immediately after first deploy:

```bash
APP="my-app"
ENV="dev"

# Set real DB credentials
aws secretsmanager put-secret-value \
  --secret-id "${APP}-${ENV}/rds/credentials" \
  --secret-string '{
    "username": "dbadmin",
    "password": "your-secure-password-here",
    "engine":   "postgres",
    "port":     5432
  }'

# Set real app secrets
aws secretsmanager put-secret-value \
  --secret-id "${APP}-${ENV}/app/credentials" \
  --secret-string '{"api_key": "your-real-api-key"}'
```

The `ignore_changes = [secret_string]` lifecycle rules on these secrets ensure Terraform will never overwrite your real values on subsequent applies.

---

## Destroying Infrastructure

> ⚠️ **This permanently deletes all infrastructure, including the database.** RDS has `deletion_protection = true` and `skip_final_snapshot = false` — a final snapshot is taken automatically, but this must still be treated with extreme caution in production.

**Step 1 — Disable RDS deletion protection:**

```bash
APP="my-app"
ENV="prod"

aws rds modify-db-instance \
  --db-instance-identifier "${APP}-${ENV}-postgres" \
  --no-deletion-protection \
  --apply-immediately
```

**Step 2 — Empty the S3 buckets** (Terraform cannot delete non-empty buckets):

```bash
ACCOUNT_ID="123456789012"
APP="my-app"
ENV="prod"

for bucket in "${APP}-${ENV}-web-assets" "${APP}-${ENV}-alb-logs" "${APP}-${ENV}-cf-logs-${ACCOUNT_ID}"; do
  echo "Emptying: $bucket"
  aws s3 rm "s3://${bucket}" --recursive
done
```

**Step 3 — Destroy all resources:**

```bash
terraform destroy -var-file=values/prod.tfvars
```

Type `yes` when prompted. This takes approximately 15–20 minutes.

**Step 4 — Schedule KMS key deletion** (optional):

KMS keys are placed in a 30-day pending-deletion window by default (set in the `deletion_window_in_days` parameter). To cancel deletion if needed:

```bash
# List all keys with the project alias prefix
aws kms list-aliases --query 'Aliases[?starts_with(AliasName, `alias/my-app-prod`)].TargetKeyId' --output text

# Cancel pending deletion for a specific key
aws kms cancel-key-deletion --key-id <key-id>
```

---

## Post-Deployment Steps

After a successful first deploy, complete these steps before go-live:

| # | Action | Why |
|---|---|---|
| 1 | Rotate placeholder secrets in Secrets Manager | Default values of `"rotate-me-please"` are not secure |
| 2 | Push container images to ECR | ECS tasks will fail to start until images exist |
| 3 | Deploy frontend assets to S3 + invalidate CloudFront | S3 bucket is empty after first apply |
| 4 | Set `db_multi_az = true` in `prod.tfvars` | Default is `false` for cost; enable for production HA |
| 5 | Set `api_desired_count = 2` (or higher) in `prod.tfvars` | Single task has no redundancy |
| 6 | Configure CloudWatch alarms | No alerting is provisioned by default |
| 7 | Point your domain's DNS CNAME to the `cloudfront_domain_name` output | Required for custom domain traffic |
| 8 | Tighten the `kms/services_key_policy` service principals | See critical fix #13 in the audit report |

---

## Security Notes

- **No IAM users or access keys are created by this Terraform code.** All authentication flows through the assumed role pattern.
- **Secrets Manager secrets are seeded with placeholder values.** Rotate them immediately after first deploy (see step 10 above). The `ignore_changes` lifecycle block prevents Terraform from reverting your real values.
- **ECS Exec is enabled** (`enable_execute_command = true`) on both services for debugging. Disable this in production if your security policy prohibits interactive container access.
- **`db_multi_az` defaults to `false`** to reduce cost in dev/uat. Always set it to `true` in production tfvars.
- **The GitLab state backend** stores Terraform state, which may contain sensitive outputs. Ensure the GitLab project has appropriate access controls and that the state is not publicly accessible.
- **KMS key policies** use a `Deny` with `kms:ViaService` on the secrets key — this means the secrets key can only be used when the request originates from Secrets Manager, preventing direct key usage by other principals.
