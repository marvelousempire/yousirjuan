# 04 — DGX Spark Bootstrap (Ubuntu 24.04 arm64)

## Why

The DGX hosts hermes + Ollama and serves the actual model traffic. This runbook turns a fresh Ubuntu install into the configured state our mesh expects.

## Prereqs

- DGX Spark powered on, Ubuntu 24.04 arm64 installed
- Operator account `abrownsanta` (UID 1000) created during install
- Wired ethernet plugged into a GL-MT6000 LAN port (NOT the WAN port, NOT the AX1800)

## Steps

### 1. Initial network

DHCP should auto-assign `192.168.8.249` on the wired interface (`enP7s7`) if you reserved that IP in the GL-MT6000 (runbook 03). Verify:

```bash
ip -4 -br addr | grep enP7s7
# enP7s7  UP  192.168.8.249/24
```

### 2. SSH setup

From the Mac:

```bash
ssh-copy-id abrownsanta@192.168.8.249
```

Then add to `~/.ssh/config` on the Mac:

```
Host nephew-nivram
  HostName fd4b:36c7:d004::ffe   # DGX IPv6 ULA (more stable than v4)
  User abrownsanta
```

### 3. Run the DGX bootstrap playbook

From the operator's Mac:

```bash
scp ledger/LEDGER-0027-seed-to-tree-bootstrap/playbooks/dgx-bootstrap.sh nephew-nivram:/tmp/
ssh nephew-nivram 'sudo bash /tmp/dgx-bootstrap.sh'
```

That installs and configures:
- `docker.io` + `docker-compose-plugin` (rootful)
- `iptables-persistent`
- Hermes container under `~/.hermes/` with `docker-compose.yml` binding port 8642 to `0.0.0.0`
- `/etc/sysctl.d/99-nephew-arp-filter.conf` with `arp_filter=1` + `rp_filter=2`
- iptables INPUT rules restricting tcp/8642 to `127.0.0.0/8 + 192.168.8.0/24 + 10.0.0.0/24`
- Ollama systemd service with `qwen2.5:32b` pulled

### 4. Verify

```bash
sudo wg show 2>/dev/null || echo "(no WG client on DGX — DGX is reached via the GL-MT6000's WG server)"
docker ps --format "{{.Names}}: {{.Status}}" | grep hermes
sudo ss -tnlp | grep 8642
curl -s -H "Authorization: Bearer v7pQ40f8zgfW-O7xy9y_vMgmy5LAzoZdr-pEOC1UjZI" http://127.0.0.1:8642/v1/models
```

Last line should return a JSON model list.

## Success criteria

```bash
# Local
curl -s -H "Authorization: Bearer $KEY" http://127.0.0.1:8642/v1/models | jq '.data[].id'
# → hermes-agent (and any others you've loaded)

# From the GL-MT6000
ping -c 2 192.168.8.249    # < 5ms

# From a WG peer (after runbook 05)
ping -c 2 192.168.8.249    # < 200ms over WG
```

## Undo

```bash
ssh nephew-nivram '
sudo systemctl stop docker
sudo docker rm -f hermes 2>/dev/null
sudo rm -f /etc/sysctl.d/99-nephew-arp-filter.conf
sudo iptables -F INPUT
sudo netfilter-persistent save
'
```

Then re-run the bootstrap playbook.
