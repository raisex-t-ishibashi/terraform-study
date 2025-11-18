.PHONY: help init plan plan-show drift apply destroy clean

# デフォルトターゲット
help:
	@echo "Terraform操作のMakefileコマンド"
	@echo ""
	@echo "使い方:"
	@echo "  make init      - Terraformを初期化"
	@echo "  make plan      - 実行計画を作成してplans/に保存"
	@echo "  make plan-show - 実行計画を作成してテキスト形式でも保存"
	@echo "  make drift     - ドリフト検知（手動変更の確認）"
	@echo "  make apply     - plans/tfplanを適用"
	@echo "  make destroy   - リソースを削除"
	@echo "  make clean     - plans/ディレクトリをクリーンアップ"
	@echo ""
	@echo "Note: planコマンドは自動的にplans/ディレクトリを作成します"

# plansディレクトリを作成
plans:
	@mkdir -p plans

# Terraformを初期化
init:
	terraform init

# 実行計画を作成（plans/ディレクトリに保存）
plan: plans
	terraform plan -out=plans/tfplan
	@echo ""
	@echo "プランが plans/tfplan に保存されました"
	@echo "確認: terraform show plans/tfplan"
	@echo "適用: make apply"

# テキスト形式でもプランを保存
plan-show: plans
	terraform plan -out=plans/tfplan
	terraform show plans/tfplan -no-color > plans/plan.txt
	@echo "プランが plans/tfplan と plans/plan.txt に保存されました"

# ドリフト検知（手動変更の確認）
drift: plans
	terraform plan -refresh-only -no-color | tee plans/drift-report.txt
	@echo ""
	@echo "ドリフトレポートが plans/drift-report.txt に保存されました"
	@echo "差分があった場合は、以下で状態を同期できます:"
	@echo "  terraform apply -refresh-only"

# 保存したプランを適用
apply:
	@if [ ! -f plans/tfplan ]; then \
		echo "エラー: plans/tfplan が見つかりません"; \
		echo "先に 'make plan' を実行してください"; \
		exit 1; \
	fi
	terraform apply plans/tfplan

# リソースを削除
destroy:
	terraform destroy

# plansディレクトリをクリーンアップ
clean:
	rm -rf plans/
	@echo "plans/ディレクトリを削除しました"

pull-state:
	@mkdir -p state
	terraform state pull > state/remote-state.tfstate
	@echo "stateが state/remote-state.tfstate に保存されました"
