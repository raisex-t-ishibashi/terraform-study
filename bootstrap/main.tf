# ======================================================================
# Terraform State Backend Bootstrap
# ======================================================================
# このファイルは、Terraformのステートファイルを保存するための
# S3バケットとDynamoDBテーブルを作成します。
#
# 使用方法:
# 1. terraform.tfvars を作成し、必要な変数を設定
# 2. terraform init
# 3. terraform apply
# 4. 出力されたバケット名とテーブル名を親ディレクトリのbackend.tfに設定
# ======================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# AWSプロバイダーの設定
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

# ======================================================================
# Variables
# ======================================================================

variable "aws_region" {
  description = "AWSリージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "aws_profile" {
  description = "AWS SSOプロファイル名"
  type        = string
  default     = null
}

variable "state_bucket_name" {
  description = "Terraformステート保存用S3バケット名（グローバルで一意である必要があります）"
  type        = string
}

variable "dynamodb_table_name" {
  description = "Terraformステートロック用DynamoDBテーブル名"
  type        = string
  default     = "terraform-state-locks"
}

variable "environment" {
  description = "環境名"
  type        = string
  default     = "infrastructure"
}

# ======================================================================
# S3 Bucket for Terraform State
# ======================================================================

resource "aws_s3_bucket" "terraform_state" {
  bucket = var.state_bucket_name

  tags = {
    Name        = "Terraform State Bucket"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Purpose     = "Terraform Remote State Storage"
  }
}

# バケットのバージョニングを有効化（履歴管理のため）
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# バケットの暗号化を有効化（セキュリティのため）
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# パブリックアクセスをブロック（セキュリティのため）
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ライフサイクルポリシー（古いバージョンを削除）
resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "delete-old-versions"
    status = "Enabled"

    # すべてのオブジェクトに適用
    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 90 # 90日以前の古いバージョンを削除
    }
  }

  rule {
    id     = "abort-incomplete-multipart-upload"
    status = "Enabled"

    # すべてのオブジェクトに適用
    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# ======================================================================
# DynamoDB Table for State Locking
# ======================================================================

resource "aws_dynamodb_table" "terraform_locks" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Lock Table"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Purpose     = "Terraform State Locking"
  }
}
