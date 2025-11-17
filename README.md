# terraform-study

このリポジトリはTerraformの基本を学習するためのリポジトリです。

## 概要

このプロジェクトでは、TerraformでAWS S3バケットを作成する基本的な構成を学習できます。

## ファイル構成

- [main.tf](main.tf) - メインの設定ファイル（S3バケットのリソース定義）
- [variables.tf](variables.tf) - 変数定義ファイル
- [outputs.tf](outputs.tf) - 出力値定義ファイル
- [terraform.tfvars.example](terraform.tfvars.example) - 変数値の例

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

