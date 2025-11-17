# terraform-study

このリポジトリはTerraformの基本を学習するためのリポジトリです。

## 概要

このプロジェクトでは、TerraformでAWS S3バケットを作成する基本的な構成を学習できます。

## ファイル構成

- [main.tf](main.tf) - メインの設定ファイル（S3バケットのリソース定義）
- [variables.tf](variables.tf) - 変数定義ファイル
- [outputs.tf](outputs.tf) - 出力値定義ファイル
- [terraform.tfvars.example](terraform.tfvars.example) - 変数値の例
- [backend.tf.example](backend.tf.example) - リモートバックエンド設定の例
- [bootstrap/](bootstrap/) - バックエンド用リソース（S3・DynamoDB）作成用

## 使い方

### 1. 前提条件

- Terraformがインストールされていること（バージョン1.0以上）
- AWS CLIが設定されていること
- 適切なAWS認証情報が設定されていること

### 2. AWS SSO設定（AWS SSOを使用している場合）

AWS SSOを使用している場合は、以下の手順でログインしてください：

```bash
# 使用可能なプロファイルを確認
aws configure list-profiles

# AWS SSOにログイン
aws sso login --profile your-profile-name
```

### 3. 変数ファイルの準備

```bash
cp terraform.tfvars.example terraform.tfvars
```

`terraform.tfvars`を編集して、以下を設定してください：
- `aws_profile`: AWS SSOプロファイル名（AWS SSOを使用している場合）
- `bucket_name`: グローバルで一意のS3バケット名

### 4. Terraformの初期化

```bash
terraform init
```

### 5. 実行計画の確認

```bash
# 実行計画を確認
terraform plan

# 実行計画をファイルに保存（推奨）
terraform plan -out=tfplan

# 保存したプランを確認
terraform show tfplan

# テキスト形式でも保存（レビュー用）
terraform show tfplan > plan.txt
```

### 6. リソースの作成

```bash
# 対話的に適用
terraform apply

# 保存したプランを適用（推奨）
terraform apply tfplan
```

### 7. リソースの削除

```bash
terraform destroy
```

## 作成されるリソース

- S3バケット
  - バージョニング有効
  - サーバーサイド暗号化（AES256）
  - パブリックアクセスブロック設定

## 学習ポイント

1. **Terraformの基本構造**: `terraform`ブロックでバージョンとプロバイダーを定義
2. **プロバイダー設定**: `provider`ブロックでAWSリージョンとプロファイルを設定
3. **リソース定義**: `resource`ブロックでS3バケットとその設定を定義
4. **変数の使用**: `variable`で再利用可能な値を定義
5. **出力値**: `output`で作成されたリソースの情報を表示
6. **セキュリティベストプラクティス**: 暗号化とパブリックアクセスブロックの設定
7. **AWS SSO対応**: プロファイルを指定してAWS SSOで認証

## 実行計画の保存について

`terraform plan -out=tfplan`でプランを保存する利点：
- プラン作成時と適用時で状態が変わっても安全
- レビュープロセスに組み込める
- CI/CDパイプラインでの使用に適している

保存したプランは`terraform apply tfplan`で適用できます。

## リフレッシュオプションの使い分け

Terraformの`plan`コマンドには、リソースの状態取得（リフレッシュ）をコントロールするオプションがあります。

### デフォルト動作（`terraform plan`）

```bash
terraform plan
```

**動作**:
- AWSから最新のリソース状態を取得（リフレッシュ）
- ステートファイルとTerraformコードを比較
- 変更計画を表示

**ユースケース**:
- 通常の変更確認（最も一般的な使い方）
- 手動変更やドリフトの検出
- 本番環境への適用前の最終確認

### `-refresh-only`: 状態の同期のみ

```bash
# ステートとAWSリソースの差分を確認
terraform plan -refresh-only

# ステートを実際のAWS状態に同期
terraform apply -refresh-only
```

**動作**:
- AWSから最新のリソース状態を取得
- **リソースの変更は一切提案しない**
- ステートファイルと実際のリソースの差分のみを表示

**ユースケース**:
- 手動でリソースが変更された可能性がある場合の確認
- 他のツールや他の人が変更を加えた後の状態同期
- ドリフト検出（Terraformコード外での変更の確認）

**例**: AWSコンソールでS3バケットのタグを手動追加した場合
```bash
# 差分を確認
terraform plan -refresh-only
# Output: タグが追加されていることを検出

# ステートを更新（AWSリソースは変更しない）
terraform apply -refresh-only
```

### `-refresh=false`: リフレッシュをスキップ

```bash
terraform plan -refresh=false
```

**動作**:
- **AWSへの問い合わせをスキップ**
- ステートファイル（前回の状態）とTerraformコードのみを比較
- 高速に実行

**ユースケース**:
- 開発中の構文チェック・コード検証
- 大規模インフラでの高速確認
- CI/CDパイプラインの初期段階（構文チェック）
- API制限を回避したい場合

**注意**: 実際のAWS状態を確認しないため、手動変更や削除を見逃す可能性があります。

### 比較表

| オプション | AWSへの問い合わせ | リソース変更 | 速度 | 主な用途 |
|-----------|-----------------|------------|------|---------|
| デフォルト | ✓ | ✓ | 通常 | 通常の変更確認・適用前確認 |
| `-refresh-only` | ✓ | ✗ | 通常 | ドリフト検出・状態同期 |
| `-refresh=false` | ✗ | ✓ | 高速 | 構文チェック・開発中の確認 |

### 推奨ワークフロー

```bash
# 1. 開発中: 構文チェック（高速）
terraform plan -refresh=false

# 2. ドリフト確認: 手動変更の検出
terraform plan -refresh-only

# 3. 本番適用前: 完全な状態確認
terraform plan -out=tfplan

# 4. 適用
terraform apply tfplan
```

### 実践例

#### ケース1: 開発サイクル

```bash
# コード変更後、素早く構文確認
terraform plan -refresh=false

# 問題なければ、完全なプランを確認
terraform plan
```

#### ケース2: 定期的なドリフト検出

```bash
# 週次でドリフトをチェック
terraform plan -refresh-only -no-color > drift_report.txt

# 差分があればステートを更新
terraform apply -refresh-only
```

#### ケース3: 大規模インフラ

```bash
# 数百のリソースがある場合
terraform plan -refresh=false  # 数秒で完了
terraform plan                  # 数分かかる可能性
```

## ステートファイルのリモート管理（S3バックエンド）

チーム開発や本番環境では、ステートファイルをS3で管理することを推奨します。

### リモート管理の利点

- **チーム共有**: 複数人で同じステートを参照・更新できる
- **バージョン管理**: S3のバージョニングで履歴を保持
- **セキュリティ**: 暗号化とアクセス制御
- **ロック機能**: DynamoDBで同時実行を防止（コンフリクト回避）
- **バックアップ**: S3の耐久性でステートを安全に保管

### ディレクトリ構成

```
terraform-study/
├── bootstrap/              # バックエンド用リソース（最初に1回だけ実行）
│   ├── main.tf            # S3バケットとDynamoDBテーブルの定義
│   ├── outputs.tf         # バックエンド設定情報を出力
│   └── terraform.tfvars.example
└── (このディレクトリ)       # 実際のインフラ管理
    ├── main.tf            # S3バケット等のリソース定義
    ├── backend.tf         # ← S3バックエンドの設定（後で追加）
    └── ...
```

#### Terraformのディレクトリスコープ

**重要**: Terraformは**カレントディレクトリ内の`.tf`ファイルのみ**を読み込みます。

- `terraform plan/apply`を実行すると、**そのディレクトリ内**の`.tf`ファイルだけが対象
- サブディレクトリ（`bootstrap/`など）の`.tf`ファイルは**自動的には読み込まれない**
- そのため、`bootstrap/`ディレクトリのリソースを操作するには、`cd bootstrap`で移動する必要がある

**例**:
```bash
# ルートディレクトリで実行 → main.tf, backend.tf などが対象
terraform plan

# bootstrap/ディレクトリで実行 → bootstrap/main.tf などが対象
cd bootstrap
terraform plan
```

このスコープ分離により、バックエンド用リソースとアプリケーションリソースを独立して管理できます。

### セットアップ手順

#### ステップ1: バックエンド用リソースの作成

まず、`bootstrap/`ディレクトリでバックエンド用のS3とDynamoDBを作成します：

```bash
# bootstrapディレクトリに移動
cd bootstrap

# 変数ファイルの準備
cp terraform.tfvars.example terraform.tfvars

# terraform.tfvarsを編集
# - state_bucket_name: グローバルで一意のバケット名
# - aws_profile: AWS SSOプロファイル名

# Terraform初期化
terraform init

# 実行計画の確認
terraform plan

# バックエンド用リソースの作成
terraform apply
```

作成されるリソース：
- S3バケット（バージョニング・暗号化・ライフサイクル設定済み）
- DynamoDBテーブル（ステートロック用）

#### ステップ2: 出力の確認

`terraform apply`実行後、以下のような出力が表示されます：

```
Outputs:

state_bucket_name = "your-terraform-state-bucket-name"
dynamodb_table_name = "terraform-state-locks"

backend_config = <<EOT

  以下の設定を ../backend.tf に記述してください:

  terraform {
    backend "s3" {
      bucket         = "your-terraform-state-bucket-name"
      key            = "terraform.tfstate"
      region         = "ap-northeast-1"
      dynamodb_table = "terraform-state-locks"
      encrypt        = true
      profile        = "your-profile"
    }
  }
EOT
```

この情報をメモしておきます。

#### ステップ3: 親ディレクトリに戻る

```bash
# 親ディレクトリに戻る
cd ..
```

#### ステップ4: backend.tfの作成

出力された情報を使って、`backend.tf`を作成します：

```bash
# backend.tf.exampleをコピー
cp backend.tf.example backend.tf

# backend.tfを編集して以下を変更:
# - bucket: 実際に作成されたバケット名
# - profile: AWS SSOプロファイル名（必要に応じて）
```

[backend.tf](backend.tf)の例：
```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-20251117"  # 実際のバケット名
    key            = "terraform-study/terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
    profile        = "dev"  # 実際のプロファイル名
  }
}
```

#### ステップ5: バックエンドの初期化（ローカル→S3への移行）

```bash
# バックエンドを再初期化（ローカルステートをS3に移行）
terraform init -reconfigure
```

以下のメッセージが表示されます：

```
Initializing the backend...
Do you want to copy existing state to the new backend?
  Pre-existing state was found while migrating the previous "local" backend to the
  newly configured "s3" backend. No existing state was found in the newly
  configured "s3" backend. Do you want to copy this state to the new "s3"
  backend? Enter "yes" to copy and "no" to start with an empty state.

  Enter a value:
```

**`yes`** を入力してローカルのステートをS3にコピーします。

#### ステップ6: 動作確認

```bash
# S3にステートファイルがアップロードされたことを確認
aws s3 ls s3://your-terraform-state-bucket-name/terraform-study/

# Terraformコマンドが正常に動作するか確認
terraform plan
```

### バックエンド設定の詳細

[backend.tf](backend.tf.example)の主要な設定項目：

| パラメータ | 説明 | 例 |
|-----------|------|-----|
| `bucket` | ステート保存先S3バケット名 | `my-terraform-state` |
| `key` | ステートファイルのパス | `terraform-study/terraform.tfstate` |
| `region` | S3バケットのリージョン | `ap-northeast-1` |
| `dynamodb_table` | ロック用DynamoDBテーブル | `terraform-state-locks` |
| `encrypt` | 暗号化の有効化 | `true` |
| `profile` | AWS SSOプロファイル名 | `dev` |

### ステートの確認・操作

```bash
# S3上のステートファイルを確認
aws s3 ls s3://your-terraform-state-bucket-name/terraform-study/

# ステートに記録されているリソースの一覧
terraform state list

# 特定リソースの詳細情報
terraform state show aws_s3_bucket.main

# ステートファイルの内容を表示（JSON形式）
terraform show -json
```

### ステートファイルのキー（パス）変更

既存のステートファイルのキーを変更したい場合（例: `terraform.tfstate` → `dev/terraform.tfstate`）：

#### 手順

```bash
# 1. backend.tfのkeyを変更
# backend.tf の key を編集
# 例: key = "dev/terraform.tfstate"

# 2. バックエンド設定を再初期化
terraform init -reconfigure

# 3. 古いステートファイルを新しいパスにコピー
aws s3 cp \
  s3://your-bucket-name/terraform.tfstate \
  s3://your-bucket-name/dev/terraform.tfstate \
  --profile your-profile

# 4. 既存リソースが認識されることを確認
terraform plan
# Output: "No changes. Your infrastructure matches the configuration."

# 5. 古いステートファイルを削除（オプション）
aws s3 rm s3://your-bucket-name/terraform.tfstate --profile your-profile
```

#### 注意点

- **`terraform init -reconfigure`だけでは不十分**: バックエンド設定は更新されますが、ステートファイルは自動的に移動しません
- **手動コピーが必須**: `aws s3 cp`で既存のステートファイルを新しいパスにコピーする必要があります
- **コピー前にplanを実行すると**: 新しいパスにステートが存在しないため、全リソースが新規作成扱いになります

#### 結果の確認

```bash
# S3上のファイル構造を確認
aws s3 ls s3://your-bucket-name/ --recursive --profile your-profile

# ローカルのバックエンド設定を確認
cat .terraform/terraform.tfstate | jq '.backend.config.key'
```

### 複数環境の管理

環境ごとに`key`を分けることで、同じバックエンドリソースを使いながら環境を分離できます：

```hcl
# 開発環境
key = "dev/terraform.tfstate"

# ステージング環境
key = "staging/terraform.tfstate"

# 本番環境
key = "prod/terraform.tfstate"
```

### 注意点

#### 1. バックエンド設定では変数を使用できない

```hcl
# ❌ これはエラーになります
terraform {
  backend "s3" {
    bucket = var.state_bucket_name  # 変数は使えない
  }
}

# ✅ 直接値を記述する必要があります
terraform {
  backend "s3" {
    bucket = "my-terraform-state-bucket"
  }
}
```

#### 2. チーム開発での推奨事項

- `backend.tf`はGitで管理してチーム全員で共有
- S3バケットへのアクセス権限を適切に設定（IAMポリシー）
- DynamoDBでロックを有効化（同時実行防止）
- `.gitignore`に`*.tfstate`を追加（ローカルステートは管理しない）

#### 3. bootstrap/のステートファイル管理

`bootstrap/`ディレクトリの`terraform.tfstate`はローカルに保存されます。このファイルは以下の理由で重要です：

- バックエンド用リソース（S3・DynamoDB）の状態を記録
- バックエンドリソースを削除する際に必要

**推奨**: `bootstrap/terraform.tfstate`をバックアップしておく

### トラブルシューティング

#### ロックエラーが発生した場合

他の人が`terraform apply`実行中の場合や、前回の実行が異常終了した場合にロックエラーが発生します：

```
Error: Error acquiring the state lock
```

**対処法1: 実行中のプロセスを待つ**
```bash
# 他の人が実行中でないか確認
```

**対処法2: 強制的にロックを解除**（注意: 他の人が実行中でないことを確認してから）
```bash
terraform force-unlock <LOCK_ID>
```

LOCK_IDはエラーメッセージに表示されます。

#### バックエンドをローカルに戻す場合

```bash
# 1. backend.tfを削除またはリネーム
mv backend.tf backend.tf.bak

# 2. ローカルバックエンドに戻す
terraform init -reconfigure

# 3. S3からローカルにステートをコピー
# （"yes"を入力）
```

#### bootstrapリソースの削除

バックエンドが不要になった場合：

```bash
# 1. 親ディレクトリのリソースを先に削除
terraform destroy

# 2. backend.tfを削除してローカルに戻す
rm backend.tf
terraform init -reconfigure

# 3. bootstrapディレクトリのリソースを削除
cd bootstrap
terraform destroy
```

### 参考資料

- [Terraform Backend Configuration](https://developer.hashicorp.com/terraform/language/settings/backends/s3)
- [bootstrap/README.md](bootstrap/README.md) - 詳細な手順

