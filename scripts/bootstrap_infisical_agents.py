#!/usr/bin/env python3
"""
Bootstrap Infisical agent credentials on each VPS.

Reads infisical_credentials.json and SSHes into each VPS to:
  1. Install /opt/config/infisical-agent.env with clientId + clientSecret
  2. Install /opt/config/infisical-env.sh helper script

Usage:
    python scripts/bootstrap_infisical_agents.py
"""
import json
import os
import subprocess
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(SCRIPT_DIR)
CREDS_FILE = os.path.join(REPO_ROOT, "infisical_credentials.json")
HELPER_SCRIPT = os.path.join(REPO_ROOT, "infra_assets", "scripts", "infisical-env.sh")

VPS_MAP = {
    "racknerd-agent": {
        "ssh": "racknerd",
        "description": "RackNerd (23.226.133.245)",
    },
    "contabo-agent": {
        "ssh": "contabo",
        "description": "Contabo (46.250.234.28)",
    },
    "greencloud-agent": {
        "ssh": "greencloud",
        "description": "GreenCloud (167.253.159.196)",
    },
    "hostinger-agent": {
        "ssh": "my_n8n",
        "description": "Hostinger (31.97.71.85)",
    },
}

INFISICAL_URL = "https://knives.bytesizeprotip.com"


def ssh_run(host: str, cmd: str) -> tuple[int, str]:
    result = subprocess.run(
        ["ssh", host, cmd],
        capture_output=True, text=True, timeout=30,
    )
    return result.returncode, result.stdout + result.stderr


def scp_to(local_path: str, host: str, remote_path: str) -> int:
    result = subprocess.run(
        ["scp", local_path, f"{host}:{remote_path}"],
        capture_output=True, text=True, timeout=30,
    )
    return result.returncode


def main():
    if not os.path.exists(CREDS_FILE):
        print(f"ERROR: {CREDS_FILE} not found. Run setup_infisical.py first.")
        sys.exit(1)

    with open(CREDS_FILE) as f:
        creds = json.load(f)

    identities = creds.get("identities", {})

    for agent_name, vps_cfg in VPS_MAP.items():
        ssh_host = vps_cfg["ssh"]
        desc = vps_cfg["description"]
        agent_creds = identities.get(agent_name)

        if not agent_creds:
            print(f"  [SKIP] {agent_name}: no credentials found")
            continue

        client_id = agent_creds["clientId"]
        client_secret = agent_creds["clientSecret"]

        print(f"\n{'='*50}")
        print(f"Bootstrapping {agent_name} on {desc}")
        print(f"{'='*50}")

        # 1. Create /opt/config directory
        rc, out = ssh_run(ssh_host, "mkdir -p /opt/config")
        if rc != 0:
            print(f"  ERROR creating /opt/config: {out}")
            continue

        # 2. Write agent credentials
        agent_env_content = (
            f"# Infisical agent credentials — DO NOT EDIT\n"
            f"# Identity: {agent_name}\n"
            f"INFISICAL_URL={INFISICAL_URL}\n"
            f"INFISICAL_CLIENT_ID={client_id}\n"
            f"INFISICAL_CLIENT_SECRET={client_secret}\n"
        )

        # Write via SSH (avoid temp file on Windows)
        escaped = agent_env_content.replace("'", "'\\''")
        rc, out = ssh_run(ssh_host,
            f"printf '%s' '{escaped}' > /opt/config/infisical-agent.env && chmod 600 /opt/config/infisical-agent.env")
        if rc != 0:
            print(f"  ERROR writing agent env: {out}")
            continue
        print(f"  [OK] /opt/config/infisical-agent.env")

        # 3. Upload infisical-env.sh helper
        rc = scp_to(HELPER_SCRIPT, ssh_host, "/opt/config/infisical-env.sh")
        if rc != 0:
            print(f"  ERROR uploading helper script")
            continue

        rc, out = ssh_run(ssh_host, "chmod +x /opt/config/infisical-env.sh")
        print(f"  [OK] /opt/config/infisical-env.sh")

        # 4. Verify connectivity
        rc, out = ssh_run(ssh_host,
            f"source /opt/config/infisical-env.sh && "
            f"_infisical_get_token '{client_id}' '{client_secret}' '{INFISICAL_URL}' > /dev/null 2>&1 && echo OK || echo FAIL")
        status = out.strip().split('\n')[-1]
        if status == "OK":
            print(f"  [OK] Infisical auth verified")
        else:
            print(f"  [WARN] Auth check: {out.strip()}")

    print(f"\n{'='*50}")
    print("Bootstrap complete!")
    print(f"{'='*50}")
    print("\nNext: Update deploy scripts to call `infisical_fetch` before starting containers.")


if __name__ == "__main__":
    main()
