# 出力値定義ファイル

output "bucket_id" {
  description = "S3バケットのID"
  value       = aws_s3_bucket.main.id
}

output "bucket_arn" {
  description = "S3バケットのARN"
  value       = aws_s3_bucket.main.arn
}

output "bucket_domain_name" {
  description = "S3バケットのドメイン名"
  value       = aws_s3_bucket.main.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "S3バケットのリージョナルドメイン名"
  value       = aws_s3_bucket.main.bucket_regional_domain_name
}
