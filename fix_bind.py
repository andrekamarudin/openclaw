import json
with open('/root/.openclaw/openclaw.json') as f:
    c = json.load(f)
c['gateway']['bind'] = 'auto'
with open('/root/.openclaw/openclaw.json', 'w') as f:
    json.dump(c, f, indent=2)
print('done')
