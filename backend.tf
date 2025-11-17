# ======================================================================
# Terraformのバックエンド設定（S3 + DynamoDB）
# ======================================================================
#
# 前提条件:
# 1. bootstrap/ディレクトリでバックエンド用リソースを作成済みであること
# 2. terraform apply実行後に出力された値を以下に設定すること
#
# 使用方法:
# 1. このファイルを backend.tf にリネーム
# 2. bucket, region, profile を実際の値に変更
# 3. terraform init -reconfigure を実行してローカルからS3に移行
#
# 注意:
# - backendブロック内では変数（var.xxx）を使用できません
# - 値は直接記述する必要があります
# ======================================================================

terraform {
  backend "s3" {
    bucket         = ""
    key            = "dev/terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
    profile        = "" # 必要に応じて変更
  }
}
