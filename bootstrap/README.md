# Bootstrap: Terraform Backend Setup

このディレクトリは、Terraformのリモートバックエンド（S3 + DynamoDB）を構築するためのものです。

## 目的

親ディレクトリのTerraform構成がステートファイルをS3で管理できるように、以下のリソースを作成します:

- **S3バケット**: Terraformステートファイルの保存先
- **DynamoDBテーブル**: ステートファイルのロック管理

## 使用方法

### 1. 変数ファイルの作成

```bash
cd bootstrap
cp terraform.tfvars.example terraform.tfvars
```

`terraform.tfvars`を編集して、以下を設定:
- `state_bucket_name`: グローバルで一意のS3バケット名
- `aws_profile`: AWS SSOプロファイル名

### 2. バックエンドリソースの作成

```bash
# 初期化
terraform init

# 実行計画の確認
terraform plan

# リソースの作成
terraform apply
```

### 3. 出力の確認

`terraform apply`実行後、バックエンド設定に必要な情報が出力されます:

```
Outputs:

backend_config = <<EOT

  以下の設定を ../backend.tf に記述してください:

  terraform {
    backend "s3" {
      bucket         = "your-bucket-name"
      key            = "terraform.tfstate"
      region         = "ap-northeast-1"
      dynamodb_table = "terraform-state-locks"
      encrypt        = true
      profile        = "your-profile"
    }
  }
EOT
```

### 4. 親ディレクトリでバックエンドを設定

出力された設定を使って、親ディレクトリに`backend.tf`を作成します:

```bash
cd ..
# backend.tf.example を参考にbackend.tfを作成
```

### 5. 親ディレクトリでバックエンドを初期化

```bash
cd ..
terraform init -reconfigure
```

## 注意事項

- このディレクトリの`terraform.tfstate`はローカルに保存されます
- バックエンドリソース作成後は、このディレクトリのステートファイルを安全に保管してください
- バックエンドリソースを削除する場合は、先に親ディレクトリのリソースを削除してください

## 作成されるリソース

- **S3バケット**
  - バージョニング有効
  - サーバーサイド暗号化（AES256）
  - パブリックアクセスブロック
  - ライフサイクルポリシー（90日以前のバージョンを削除）

- **DynamoDBテーブル**
  - オンデマンド課金
  - ステートロック用

## クリーンアップ

バックエンドリソースが不要になった場合:

```bash
# 親ディレクトリのリソースを先に削除
cd ..
terraform destroy

# backend.tfを削除してローカルバックエンドに戻す
rm backend.tf
terraform init -reconfigure

# その後、bootstrapディレクトリのリソースを削除
cd bootstrap
terraform destroy
```
