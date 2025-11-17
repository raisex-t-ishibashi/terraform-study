# ======================================================================
# Outputs
# ======================================================================

output "state_bucket_name" {
  description = "Terraformステート保存用S3バケット名"
  value       = aws_s3_bucket.terraform_state.id
}

output "state_bucket_arn" {
  description = "Terraformステート保存用S3バケットARN"
  value       = aws_s3_bucket.terraform_state.arn
}

output "dynamodb_table_name" {
  description = "Terraformステートロック用DynamoDBテーブル名"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "dynamodb_table_arn" {
  description = "Terraformステートロック用DynamoDBテーブルARN"
  value       = aws_dynamodb_table.terraform_locks.arn
}

output "backend_config" {
  description = "親ディレクトリのbackend.tfに設定する値"
  value = <<-EOT

  以下の設定を ../backend.tf に記述してください:

  terraform {
    backend "s3" {
      bucket         = "${aws_s3_bucket.terraform_state.id}"
      key            = "terraform.tfstate"
      region         = "${var.aws_region}"
      dynamodb_table = "${aws_dynamodb_table.terraform_locks.name}"
      encrypt        = true
      profile        = "${var.aws_profile}" # 必要に応じて変更
    }
  }
  EOT
}
