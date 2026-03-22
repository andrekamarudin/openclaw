import json

config = {
    "meta": {
        "lastTouchedVersion": "2026.3.13",
        "lastTouchedAt": "2026-03-22T10:00:00.000Z",
    },
    "wizard": {
        "lastRunAt": "2026-03-21T23:45:18.032Z",
        "lastRunVersion": "2026.3.13",
        "lastRunCommand": "doctor",
        "lastRunMode": "local",
    },
    "agents": {
        "defaults": {
            "model": {
                "primary": "openai/gpt-5.4-mini",
                "fallbacks": ["anthropic/claude-haiku-4-5"],
            },
            "models": {
                "openai/gpt-5.4-mini": {"alias": "cheap"},
                "openai/gpt-5.4-nano": {"alias": "nano"},
                "openai/gpt-5.4": {"alias": "smart"},
                "anthropic/claude-haiku-4-5": {"alias": "haiku"},
                "anthropic/claude-sonnet-4-6": {"alias": "sonnet"},
            },
        }
    },
    "tools": {
        "profile": "full",
        "elevated": {"enabled": True, "allowFrom": {"telegram": [876499264]}},
    },
    "commands": {
        "native": "auto",
        "nativeSkills": "auto",
        "restart": True,
        "ownerDisplay": "raw",
    },
    "channels": {
        "telegram": {
            "enabled": True,
            "dmPolicy": "allowlist",
            "botToken": "7489114952:AAGkeDnS8rpqH1DYTj4pROdr00zH-1UUQx8",
            "groupPolicy": "disabled",
            "streaming": "partial",
            "allowFrom": [876499264],
        }
    },
    "gateway": {
        "mode": "local",
        "bind": "lan",
        "controlUi": {
            "allowedOrigins": [
                "http://localhost:18789",
                "http://127.0.0.1:18789",
                "http://23.226.133.245:18789",
            ]
        },
        "auth": {"mode": "token"},
    },
}

with open("/root/.openclaw/openclaw.json", "w") as f:
    json.dump(config, f, indent=2)

print("Config written successfully")
print("bind:", config["gateway"]["bind"])
