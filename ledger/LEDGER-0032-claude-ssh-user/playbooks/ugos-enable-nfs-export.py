#!/usr/bin/env python3
"""Enable UGOS NFS export for search-my-engine via reverse-engineered UGOS Pro API."""

from __future__ import annotations

import argparse
import base64
import getpass
import json
import os
import ssl
import sys
import urllib.error
import urllib.request
from typing import Any

try:
    from cryptography.hazmat.primitives import hashes, serialization
    from cryptography.hazmat.primitives.asymmetric import padding
except ImportError:
    print("✗ Install cryptography: python3 -m pip install cryptography", file=sys.stderr)
    raise SystemExit(1)


DEFAULT_HOST = os.environ.get("NAS_HOST", "nasa.local")
DEFAULT_PORT = int(os.environ.get("NAS_UGOS_API_PORT", "9443"))
DEFAULT_USER = os.environ.get("NAS_SSH_USER", "abrownsanta")
DEFAULT_SHARE = os.environ.get("NAS_SHARE_NAME", "search-my-engine")
DEFAULT_CLIENT = os.environ.get("NAS_NFS_CLIENT", "192.168.8.0/24")
DEFAULT_EXPORT = os.environ.get("NAS_EXPORT", "/volume1/search-my-engine")


class UgosClient:
    def __init__(self, host: str, port: int, username: str, password: str) -> None:
        self.base = f"https://{host}:{port}/ugreen/v1"
        self.username = username
        self.password = password
        self.token: str | None = None
        self.ctx = ssl.create_default_context()
        self.ctx.check_hostname = False
        self.ctx.verify_mode = ssl.CERT_NONE

    def _request(
        self,
        method: str,
        path: str,
        body: dict[str, Any] | None = None,
        *,
        auth: bool = True,
    ) -> dict[str, Any]:
        url = f"{self.base}/{path.lstrip('/')}"
        if auth and self.token:
            sep = "&" if "?" in url else "?"
            url = f"{url}{sep}token={self.token}"
        data = None
        headers = {
            "ug-agent": "PC/WEB",
            "Accept": "application/json",
        }
        if body is not None:
            data = json.dumps(body).encode()
            headers["Content-Type"] = "application/json"
        req = urllib.request.Request(url, data=data, headers=headers, method=method)
        try:
            with urllib.request.urlopen(req, context=self.ctx, timeout=30) as resp:
                raw = resp.read().decode()
                if method == "POST" and path.endswith("verify/check"):
                    rsa_token = resp.headers.get("x-rsa-token")
                    if rsa_token:
                        return {"x_rsa_token": rsa_token, "body": json.loads(raw) if raw else {}}
                return json.loads(raw) if raw else {}
        except urllib.error.HTTPError as exc:
            detail = exc.read().decode(errors="replace")
            raise RuntimeError(f"{method} {path} failed ({exc.code}): {detail}") from exc

    def login(self) -> None:
        check = self._request("POST", "verify/check", {"username": self.username}, auth=False)
        rsa_b64 = check.get("x_rsa_token")
        if not rsa_b64:
            raise RuntimeError("UGOS did not return x-rsa-token header")
        pem = base64.b64decode(rsa_b64).decode()
        public_key = serialization.load_pem_public_key(pem.encode())
        encrypted = public_key.encrypt(
            self.password.encode(),
            padding.PKCS1v15(),
        )
        payload = {
            "username": self.username,
            "password": base64.b64encode(encrypted).decode(),
            "keepalive": False,
            "otp": False,
            "is_simple": False,
        }
        resp = self._request("POST", "verify/login", payload, auth=False)
        if resp.get("code") != 200:
            msg = resp.get("msg") or str(resp)
            if "too many failed logins" in msg.lower() or resp.get("code") == 1025:
                raise RuntimeError(
                    f"UGOS login locked: {msg}. Wait ~5 minutes, then re-run setup-nas-dgx-storage.sh"
                )
            raise RuntimeError(f"Login failed: {msg}")
        token = (resp.get("data") or {}).get("token")
        if not token:
            raise RuntimeError(f"Login response missing token: {resp}")
        self.token = token

    def get(self, path: str) -> dict[str, Any]:
        resp = self._request("GET", path)
        if resp.get("code") not in (200, None):
            raise RuntimeError(f"GET {path}: {resp.get('msg') or resp}")
        return resp

    def post(self, path: str, body: dict[str, Any]) -> dict[str, Any]:
        resp = self._request("POST", path, body)
        if resp.get("code") not in (200, None):
            raise RuntimeError(f"POST {path}: {resp.get('msg') or resp}")
        return resp

    def ensure_nfs_service(self) -> None:
        cfg = self.get("file/nfs/config")
        data = cfg.get("data") or {}
        if data.get("enableNfsServer"):
            print("✓ NFS service already enabled")
            return
        body = {
            "enableNfsServer": True,
            "maximumNFSProtocol": data.get("maximumNFSProtocol") or "NFSv3",
            "applyDefaultUNIXPerm": bool(data.get("applyDefaultUNIXPerm", False)),
            "customerPort": bool(data.get("customerPort", False)),
            "statdPort": int(data.get("statdPort") or 0),
            "nlockMgrPort": int(data.get("nlockMgrPort") or 0),
            "defaultReadPacketSize": data.get("defaultReadPacketSize") or "",
            "defaultWritePacketSize": data.get("defaultWritePacketSize") or "",
            "nFSvDomain": data.get("nFSvDomain") or "localdomain",
            "logs": True,
            "enableAdvance": True,
        }
        self.post("file/nfs/start", body)
        print("✓ NFS service enabled")

    def find_share_id(self, share_name: str) -> int:
        resp = self.get("filemgr/getSharedFolderList")
        rows = (resp.get("data") or {}).get("result") or resp.get("data") or []
        if isinstance(rows, dict):
            rows = rows.get("result") or rows.get("list") or []
        for row in rows:
            name = row.get("name") or row.get("folder_name") or row.get("share_name")
            path = row.get("path") or ""
            if name == share_name or path.rstrip("/").endswith(f"/{share_name}"):
                share_id = row.get("id") or row.get("shared_folder_id")
                if share_id is not None:
                    return int(share_id)
        raise RuntimeError(f"Shared folder {share_name!r} not found in getSharedFolderList")

    def list_nfs_rules(self, share_id: int) -> list[dict[str, Any]]:
        resp = self.get(f"filemgr/getNfsPermissionList?shared_folder_id={share_id}")
        data = resp.get("data") or {}
        rules = data.get("result") or data.get("list") or []
        return list(rules)

    def ensure_share_nfs_rule(self, share_id: int, client: str) -> None:
        rules = self.list_nfs_rules(share_id)
        for rule in rules:
            if rule.get("ip") == client:
                print(f"✓ NFS rule already present for {client}")
                return
        new_rule = {
            "ip": client,
            "permission": 2,
            "identity": 3,
            "safety": 1,
            "async": True,
            "cross": False,
            "port": False,
            "allow_non_privileged_port": False,
        }
        body = {
            "id": share_id,
            "set_share_folder_info": None,
            "no_permission_hide": False,
            "permissions": [],
            "nfs_permission": rules + [new_rule],
        }
        resp = self.post("filemgr/updateShareFolderInfo", body)
        if not (resp.get("data") or {}).get("result", True):
            raise RuntimeError(f"updateShareFolderInfo failed: {resp}")
        print(f"✓ Added NFS rule {client} rw (all users → admin)")


def main() -> int:
    parser = argparse.ArgumentParser(description="Enable UGOS NFS export for DGX mount")
    parser.add_argument("--host", default=DEFAULT_HOST)
    parser.add_argument("--port", type=int, default=DEFAULT_PORT)
    parser.add_argument("--user", default=DEFAULT_USER)
    parser.add_argument("--share", default=DEFAULT_SHARE)
    parser.add_argument("--client", default=DEFAULT_CLIENT)
    parser.add_argument("--export-path", default=DEFAULT_EXPORT)
    args = parser.parse_args()

    password = os.environ.get("NAS_PASSWORD") or os.environ.get("UGOS_PASSWORD")
    if not password:
        password = getpass.getpass(f"UGOS password for {args.user}@{args.host}: ")

    client = UgosClient(args.host, args.port, args.user, password)
    print(f"→ Logging in to https://{args.host}:{args.port} as {args.user}")
    client.login()
    client.ensure_nfs_service()
    share_id = client.find_share_id(args.share)
    print(f"→ Shared folder {args.share!r} id={share_id}")
    client.ensure_share_nfs_rule(share_id, args.client)
    print(f"→ Export target: {args.host}:{args.export_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
