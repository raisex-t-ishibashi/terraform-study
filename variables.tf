# 変数定義ファイル

variable "aws_region" {
  description = "AWSリージョン"
  type        = string
  default     = "ap-northeast-1" # 東京リージョン
}

variable "aws_profile" {
  description = "AWS SSOプロファイル名"
  type        = string
  default     = null # デフォルトプロファイルを使用する場合はnull
}

variable "bucket_name" {
  description = "S3バケット名（グローバルで一意である必要があります）"
  type        = string
}

variable "environment" {
  description = "環境名（dev, staging, production等）"
  type        = string
  default     = "dev"
}

variable "enable_versioning" {
  description = "バケットのバージョニングを有効にするかどうか"
  type        = bool
  default     = true
}
