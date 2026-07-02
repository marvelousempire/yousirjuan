# Journal — LEDGER-0037

## 2026-07-02

- **fivemac:** WireGuard path to `10.1.0.5:3300` / `:2424` refused; Spark reachable on LAN `192.168.10.205`.
- **Verified:** `curl http://192.168.10.205:3300/api/v1/version` → `{"version":"1.22.6"}` (operator); on-Spark `127.0.0.1:3300` same.
- **Wiring:** Added `nephew-spark-lan` + `gitea-spark-lan` SSH aliases; SME `docs/ci-contract.md` updated.
- **Pending:** Push SME `3159134` + nephew door wrappers to Gitea via `gitea-spark-lan`.