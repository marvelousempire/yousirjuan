.PHONY: verify forge-push forge-sync forge-status setup-forge-remotes hooks

verify:
	@node scripts/yousirjuan-verify.mjs

forge-push: verify
	@bash scripts/forge-push.sh

forge-sync:
	@bash scripts/forge-sync.sh yousirjuan

forge-sync-all:
	@bash scripts/forge-sync-all.sh

forge-sync-core:
	@bash scripts/forge-sync-core.sh

forge-status:
	@bash scripts/forge-status.sh

setup-forge-remotes:
	@bash scripts/setup-forge-remotes.sh

setup-cassette-git-ssh:
	@bash scripts/setup-cassette-git-ssh.sh

hooks:
	@bash scripts/install-git-hooks.sh

test:
	@npm test --if-present
