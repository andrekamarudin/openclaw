#!/usr/bin/env python3
"""
One-time fix: Add remaining secrets to contabo-karakeep Infisical project
and grant contabo-agent identity access.

Usage:
    python scripts/fix_karakeep_infisical.py --token <admin-jwt>

The admin JWT can be obtained from browser DevTools on https://knives.bytesizeprotip.com
(Network tab → any API request → Authorization header → "Bearer <token>").
"""

import argparse
import sys

import requests

ORG_ID = "26dd1a0e-0187-4dc1-a970-8bea9361d1b2"
BASE_URL = "https://knives.bytesizeprotip.com"

# Secrets to add (OPENAI_API_KEY already added manually by user)
SECRETS_TO_ADD = {
    "KARAKEEP_VERSION": "release",
    "NEXTAUTH_SECRET": "PTyeYMToUHTj_QewRbXIN-rpFe9z4tSSZ9eAyhoe9Uwx6Nls",
    "MEILI_MASTER_KEY": "yq5tg4Sc5sea0vP4Thi4g75IpOSlLsIVVRnsI1guYJ553JcP",
    "NEXTAUTH_URL": "https://karakeep.bytesizeprotip.com",
    # AI config
    "INFERENCE_TEXT_MODEL": "gpt-5.4-nano",
    "INFERENCE_IMAGE_MODEL": "gpt-5.4-nano",
    "INFERENCE_ENABLE_AUTO_TAGGING": "true",
    "INFERENCE_ENABLE_AUTO_SUMMARIZATION": "true",
}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--token", required=True, help="Admin JWT from Infisical UI")
    args = parser.parse_args()

    s = requests.Session()
    s.headers.update(
        {
            "Authorization": f"Bearer {args.token}",
            "Content-Type": "application/json",
        }
    )

    # 1. Find contabo-karakeep project ID
    print("Finding contabo-karakeep project...")
    r = s.get(f"{BASE_URL}/api/v2/organizations/{ORG_ID}/workspaces")
    r.raise_for_status()
    projects = {p["name"]: p["id"] for p in r.json()["workspaces"]}

    if "contabo-karakeep" not in projects:
        print("ERROR: contabo-karakeep project not found in Infisical")
        sys.exit(1)

    project_id = projects["contabo-karakeep"]
    print(f"  Found: {project_id}")

    # 2. Find environment slug
    r = s.get(f"{BASE_URL}/api/v1/workspace/{project_id}")
    envs = r.json().get("workspace", {}).get("environments", [])
    env_slug = "prod"
    for e in envs:
        if e["slug"] in ("prod", "production"):
            env_slug = e["slug"]
            break
    print(f"  Using environment: {env_slug}")

    # 3. Check existing secrets
    r = s.get(
        f"{BASE_URL}/api/v3/secrets/raw?workspaceId={project_id}&environment={env_slug}&secretPath=/"
    )
    existing = {sec["secretKey"] for sec in r.json().get("secrets", [])}
    print(f"  Existing secrets: {existing}")

    # 4. Add missing secrets
    added = 0
    for key, value in SECRETS_TO_ADD.items():
        if key in existing:
            print(f"  [skip] {key} (already exists)")
            continue
        r = s.post(
            f"{BASE_URL}/api/v3/secrets/raw/{key}",
            json={
                "workspaceId": project_id,
                "environment": env_slug,
                "secretPath": "/",
                "secretValue": value,
                "type": "shared",
            },
        )
        if r.status_code < 400:
            print(f"  [added] {key}")
            added += 1
        else:
            print(f"  [ERROR] {key}: {r.status_code} {r.text[:200]}")

    print(f"\n  Added {added} secrets")

    # 5. Find contabo-agent identity and grant access
    print("\nGranting contabo-agent access to contabo-karakeep...")
    r = s.get(f"{BASE_URL}/api/v1/organizations/{ORG_ID}/identities")
    if r.status_code == 404:
        r = s.get(f"{BASE_URL}/api/v2/organizations/{ORG_ID}/identities")
    identities = r.json().get("identities", [])

    contabo_agent_id = None
    for ident in identities:
        name = ident.get("name", ident.get("identity", {}).get("name", ""))
        iid = ident.get("id", ident.get("identity", {}).get("id", ""))
        if "contabo-agent" in name:
            contabo_agent_id = iid
            break

    if not contabo_agent_id:
        print("  WARNING: contabo-agent identity not found!")
        print("  Available identities:")
        for i in identities:
            n = i.get("name", i.get("identity", {}).get("name", "?"))
            print(f"    - {n}")
        print("  You'll need to grant access manually in the Infisical UI.")
    else:
        print(f"  Found contabo-agent: {contabo_agent_id}")
        r = s.post(
            f"{BASE_URL}/api/v2/workspace/{project_id}/identity-memberships/{contabo_agent_id}",
            json={"role": "member"},
        )
        if r.status_code < 400:
            print("  [granted] contabo-agent now has access to contabo-karakeep")
        else:
            print(f"  [result] {r.status_code}: {r.text[:200]}")

    print(
        "\nDone! Now run: ssh contabo 'bash /opt/src/my_openclaw/infra_assets/scripts/deploy-karakeep.sh'"
    )


if __name__ == "__main__":
    main()
