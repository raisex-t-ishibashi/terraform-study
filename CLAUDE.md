# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Terraform learning repository for AWS infrastructure management. The project demonstrates Terraform fundamentals including S3 bucket creation, remote state management with S3 backend, and AWS SSO authentication.

## Common Commands

### Makefile Commands (Preferred)

```bash
make help      # Display available commands
make init      # Initialize Terraform
make plan      # Create execution plan and save to plans/tfplan
make apply     # Apply the saved plan from plans/tfplan
make destroy   # Destroy all resources
make clean     # Clean up plans/ directory
```

### Direct Terraform Commands

```bash
# Initialization
terraform init
terraform init -reconfigure  # Reinitialize backend (e.g., switching between local and S3)

# Planning and applying
terraform plan                    # Default: refresh state and show changes
terraform plan -refresh=false     # Fast syntax check without AWS API calls
terraform plan -refresh-only      # Detect drift without proposing changes
terraform plan -out=plans/tfplan  # Save plan for later apply
terraform apply plans/tfplan      # Apply saved plan

# State management
terraform state list              # List all resources in state
terraform state show aws_s3_bucket.main  # Show specific resource details

# Cleanup
terraform destroy
```

### AWS SSO Authentication

```bash
# Required before Terraform operations when using AWS SSO
aws configure list-profiles
aws sso login --profile <profile-name>
```

## Architecture

### Directory Structure

```
terraform-study/
├── bootstrap/              # Bootstrap infrastructure (run once)
│   ├── main.tf            # S3 bucket + DynamoDB table for remote state
│   ├── outputs.tf         # Backend configuration instructions
│   └── terraform.tfvars   # Bootstrap variables (not in git)
├── main.tf                # Main S3 bucket resource definitions
├── variables.tf           # Variable declarations
├── outputs.tf             # Output values
├── backend.tf             # Remote state configuration (S3 backend)
├── terraform.tfvars       # Variable values (not in git)
└── Makefile              # Automation commands
```

### Terraform Scope Model

**Critical**: Terraform only processes `.tf` files in the current working directory. Subdirectories are NOT automatically included.

- Running `terraform plan` in root → processes `main.tf`, `backend.tf`, `variables.tf`, etc.
- Running `terraform plan` in `bootstrap/` → processes only `bootstrap/main.tf`, `bootstrap/outputs.tf`, etc.

This isolation allows independent management of bootstrap infrastructure vs. application infrastructure.

### Two-Tier Infrastructure Setup

1. **Bootstrap Layer** (`bootstrap/`):
   - S3 bucket for storing Terraform state
   - DynamoDB table for state locking
   - Uses local state (terraform.tfstate stored locally)
   - Created once, rarely modified

2. **Application Layer** (root directory):
   - S3 bucket resources (example infrastructure)
   - Uses remote state (stored in S3 from bootstrap layer)
   - Daily development work happens here

### Remote State Backend Flow

```
1. cd bootstrap/
   terraform apply
   → Creates S3 bucket + DynamoDB table (state stored locally)

2. cd ../
   Copy bootstrap outputs → backend.tf
   terraform init -reconfigure
   → Migrates local state → S3 remote state

3. Now all changes are tracked in S3 with DynamoDB locking
```

## Key Configuration Details

### Backend Configuration (backend.tf)

**Important**: The `backend` block does NOT support variables. All values must be hardcoded.

```hcl
terraform {
  backend "s3" {
    bucket         = "actual-bucket-name"      # NOT var.bucket_name
    key            = "dev/terraform.tfstate"   # State file path in S3
    region         = "ap-northeast-1"
    dynamodb_table = "terraform-state-locks"   # For state locking
    encrypt        = true
    profile        = "your-aws-profile"        # AWS SSO profile
  }
}
```

### Variable Files (terraform.tfvars)

Not tracked in git. Must be created from `terraform.tfvars.example`:

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars to set:
# - aws_profile: AWS SSO profile name
# - bucket_name: Globally unique S3 bucket name
```

### AWS Provider Configuration

The project uses AWS provider ~> 5.0 with profile-based authentication (AWS SSO support):

```hcl
provider "aws" {
  region  = var.aws_region   # Default: ap-northeast-1
  profile = var.aws_profile  # From terraform.tfvars
}
```

## Workflow Patterns

### Initial Project Setup

```bash
# 1. Set up variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# 2. Authenticate with AWS
aws sso login --profile <your-profile>

# 3. Initialize and apply
make init
make plan
make apply
```

### Setting Up Remote State (First Time)

```bash
# 1. Bootstrap backend resources
cd bootstrap/
cp terraform.tfvars.example terraform.tfvars
# Edit: set state_bucket_name and aws_profile
terraform init
terraform apply

# 2. Configure backend in root
cd ../
# Copy output from bootstrap/outputs.tf → backend.tf
# Edit backend.tf with actual values

# 3. Migrate to remote state
terraform init -reconfigure
# Answer "yes" to copy local state to S3
```

### Changing State File Path in S3

When changing the `key` parameter in backend.tf:

```bash
# 1. Update backend.tf key
# Before: key = "terraform.tfstate"
# After:  key = "dev/terraform.tfstate"

# 2. Reinitialize
terraform init -reconfigure

# 3. MANUALLY copy state file to new location
aws s3 cp s3://bucket/terraform.tfstate s3://bucket/dev/terraform.tfstate --profile <profile>

# 4. Verify
terraform plan  # Should show "No changes"
```

**Critical**: `terraform init -reconfigure` alone does NOT move the state file. Manual S3 copy is required.

### Development Workflow Options

```bash
# Fast iteration: syntax check without AWS API calls
terraform plan -refresh=false

# Detect manual changes (drift detection)
terraform plan -refresh-only

# Full check before applying
terraform plan -out=plans/tfplan
terraform apply plans/tfplan
```

## Important Files

- `main.tf:20-28` - S3 bucket resource definition
- `backend.tf:19-28` - Remote state configuration
- `bootstrap/main.tf:68-77` - State bucket creation
- `bootstrap/main.tf:142-158` - State lock DynamoDB table
- `Makefile:25-31` - Plan command with automatic plans/ directory creation
- `Makefile:40-46` - Apply command with plan existence validation

## State Management Considerations

### Local State Files (bootstrap/)

- `bootstrap/terraform.tfstate` is stored locally
- Contains state for S3 + DynamoDB backend resources
- **Must be backed up** - required to destroy backend resources

### Remote State Files (root)

- `terraform.tfstate` stored in S3 after backend migration
- Empty local file may remain (safe to ignore)
- Versioning enabled in S3 (90-day retention for old versions)

### State Locking

DynamoDB table prevents concurrent `terraform apply` operations:
- Automatic locking during apply/destroy
- If locked, wait for other operations to complete
- Force unlock only if certain no other operations running: `terraform force-unlock <LOCK_ID>`

## Resource Configuration Details

### S3 Bucket (Application Layer)

Created in main.tf with:
- Versioning (configurable via `enable_versioning` variable)
- Server-side encryption (AES256)
- Public access blocking (all 4 settings enabled)
- Tags: Name, Environment, ManagedBy

### S3 Bucket (Bootstrap Layer)

State storage bucket includes:
- Versioning enabled (always)
- Server-side encryption (AES256)
- Public access blocking
- Lifecycle policy: Delete versions older than 90 days
- Lifecycle policy: Abort incomplete multipart uploads after 7 days

## Common Issues

### State Lock Errors

If `terraform apply` fails with lock error:
1. Check if another operation is running
2. Wait for completion or contact team member
3. Force unlock only if certain: `terraform force-unlock <LOCK_ID>`

### Backend Migration Issues

If `terraform plan` shows all resources as new after backend change:
- State file was not copied to new S3 location
- Manually copy state file: `aws s3 cp s3://bucket/old-path s3://bucket/new-path`

### AWS SSO Session Expired

```bash
# Re-authenticate
aws sso login --profile <your-profile>
```

## Project-Specific Conventions

- Plans are saved to `plans/` directory (gitignored)
- Backend configuration values must be hardcoded (no variables allowed)
- Environment-specific states use different S3 keys: `dev/`, `staging/`, `prod/`
- All S3 resources include mandatory encryption and public access blocking
