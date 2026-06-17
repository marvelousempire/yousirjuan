# Runbook 01 — Triage family SSO stack

## When to use

Operator reports: second password, sign-in 502, login loop, “SSO not working.”

## Steps

```bash
lsof -nP -iTCP:8088,8781,8782 -sTCP:LISTEN
curl -sf 'http://127.0.0.1:8088/healthz' && echo "tower-api OK" || echo "tower-api DOWN"
curl -s 'http://127.0.0.1:8088/api/v1/auth/door-ticket?target=http://hello.localhost/'
curl -s -o /dev/null -w 'signin HTTP %{http_code}\n' 'http://pockit.localhost/signin'
```

## Interpret

| Observation | Meaning |
|---|---|
| Nothing on **8088** | Auth brain down — recovery runbook 02 |
| door-ticket **not_found** | Stale tower-api — restart stack |
| door-ticket **not_signed_in** | Route alive — need hub sign-in |
| signin **502** | Gateway up but tape-server :8781 down |
| signin **200** | Gate reachable — check cookies / credentials |

## Escalate to Nephew repo when

- door-ticket returns not_found after fresh `make pockit`
- Auth code changed but docs already current — file Issue-Log entry in nephew
