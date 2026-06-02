#!/usr/bin/env bash
# family-ca.sh — tiny private CA for jailynmarvin.com mTLS device certs.
# EC P-256, openssl-based, AI-free. Issues one client cert per family device.
#
# Subcommands:
#   init                      create the root CA (run ONCE, on the CA host)
#   issue-device <name>       issue a client (mTLS) cert for a device → <name>.p12 + .crt/.key
#   issue-server  <fqdn>      issue an internal server cert (for WG-only hosts) signed by the family CA
#   revoke        <name>      revoke a device cert and regenerate the CRL
#   crl                       (re)generate the CRL
#   trust                     print the path to ca.crt to hand to the edge (Caddy trust_pool)
#
# Layout (override with FAMILY_CA_DIR):
#   $CA_DIR/ca.crt ca.key  index.txt  serial  crl.pem  issued/<name>.{crt,key,p12}
set -euo pipefail

CA_DIR="${FAMILY_CA_DIR:-/etc/jailynmarvin-ca}"
CN_ORG="Jailyn Marvin Family Office"
DAYS_CA="${DAYS_CA:-3650}"        # 10y root
DAYS_CLIENT="${DAYS_CLIENT:-825}" # ~27 months per device
DAYS_SERVER="${DAYS_SERVER:-397}" # ~13 months internal server certs
CURVE="prime256v1"

die(){ echo "ERROR: $*" >&2; exit 1; }
need(){ command -v "$1" >/dev/null || die "missing tool: $1"; }
need openssl

ca_cnf() {  # minimal openssl CA config written on demand
  cat > "$CA_DIR/openssl.cnf" <<EOF
[ ca ]
default_ca = CA_default
[ CA_default ]
dir               = $CA_DIR
database          = \$dir/index.txt
serial            = \$dir/serial
new_certs_dir     = \$dir/newcerts
certificate       = \$dir/ca.crt
private_key       = \$dir/ca.key
default_md        = sha256
policy            = policy_any
crlnumber         = \$dir/crlnumber
default_crl_days  = 30
[ policy_any ]
commonName = supplied
[ client_ext ]
basicConstraints = CA:FALSE
keyUsage = critical, digitalSignature
extendedKeyUsage = clientAuth
[ server_ext ]
basicConstraints = CA:FALSE
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = \${ENV::SAN}
EOF
}

init() {
  [ -f "$CA_DIR/ca.key" ] && die "CA already exists at $CA_DIR (refusing to overwrite)"
  mkdir -p "$CA_DIR"/{newcerts,issued}
  chmod 700 "$CA_DIR"
  : > "$CA_DIR/index.txt"; echo 1000 > "$CA_DIR/serial"; echo 1000 > "$CA_DIR/crlnumber"
  openssl ecparam -name "$CURVE" -genkey -noout -out "$CA_DIR/ca.key"
  chmod 600 "$CA_DIR/ca.key"
  openssl req -x509 -new -key "$CA_DIR/ca.key" -sha256 -days "$DAYS_CA" \
    -out "$CA_DIR/ca.crt" -subj "/O=$CN_ORG/CN=$CN_ORG Root CA"
  ca_cnf
  echo "✓ Family CA created at $CA_DIR"
  echo "  Hand $CA_DIR/ca.crt to each edge (Caddy: tls > client_auth > trust_pool file)."
}

issue_device() {
  local name="${1:?usage: issue-device <name>}"
  [ -f "$CA_DIR/ca.key" ] || die "no CA — run 'init' first"
  ca_cnf
  local b="$CA_DIR/issued/$name"
  openssl ecparam -name "$CURVE" -genkey -noout -out "$b.key"
  openssl req -new -key "$b.key" -out "$b.csr" -subj "/O=$CN_ORG/CN=$name"
  SAN="" openssl ca -batch -config "$CA_DIR/openssl.cnf" -extensions client_ext \
    -days "$DAYS_CLIENT" -in "$b.csr" -out "$b.crt"
  rm -f "$b.csr"
  # Bundle a passworded .p12 for easy install on Mac/iOS (prompts for an export password)
  openssl pkcs12 -export -inkey "$b.key" -in "$b.crt" -certfile "$CA_DIR/ca.crt" \
    -name "$name @ jailynmarvin" -out "$b.p12"
  echo "✓ device cert: $b.p12  (install on the device; also $b.crt / $b.key for curl --cert)"
}

issue_server() {
  local fqdn="${1:?usage: issue-server <fqdn>}"
  [ -f "$CA_DIR/ca.key" ] || die "no CA — run 'init' first"
  ca_cnf
  local b="$CA_DIR/issued/$fqdn"
  openssl ecparam -name "$CURVE" -genkey -noout -out "$b.key"
  openssl req -new -key "$b.key" -out "$b.csr" -subj "/O=$CN_ORG/CN=$fqdn"
  SAN="DNS:$fqdn" openssl ca -batch -config "$CA_DIR/openssl.cnf" -extensions server_ext \
    -days "$DAYS_SERVER" -in "$b.csr" -out "$b.crt"
  rm -f "$b.csr"
  echo "✓ internal server cert: $b.crt / $b.key (trusted by family CA; for WG-only hosts)"
}

revoke() {
  local name="${1:?usage: revoke <name>}"
  ca_cnf
  openssl ca -config "$CA_DIR/openssl.cnf" -revoke "$CA_DIR/issued/$name.crt"
  gen_crl
  echo "✓ revoked $name; CRL regenerated at $CA_DIR/crl.pem — redeploy it to the edges"
}

gen_crl() { ca_cnf; openssl ca -config "$CA_DIR/openssl.cnf" -gencrl -out "$CA_DIR/crl.pem"; }

case "${1:-}" in
  init)          init ;;
  issue-device)  shift; issue_device "$@" ;;
  issue-server)  shift; issue_server "$@" ;;
  revoke)        shift; revoke "$@" ;;
  crl)           gen_crl; echo "✓ CRL at $CA_DIR/crl.pem" ;;
  trust)         echo "$CA_DIR/ca.crt" ;;
  *) echo "usage: $0 {init|issue-device <name>|issue-server <fqdn>|revoke <name>|crl|trust}" >&2; exit 2 ;;
esac
