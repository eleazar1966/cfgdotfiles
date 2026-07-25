#!/bin/bash
# Renew OpenClaw MCP grant and update OpenCode config
GRANT=$(openclaw attach --print-config --ttl 86400000 2>&1)
TOKEN=$(echo "$GRANT" | python3 -c "import json,sys; print(json.load(sys.stdin)['env']['OPENCLAW_MCP_TOKEN'])")
CONFIG="$HOME/.config/opencode/opencode.json"

# Backup
cp "$CONFIG" "$CONFIG.bak"

# Update token in opencode.json
python3 -c "
import json
with open('$CONFIG') as f:
    d = json.load(f)
d.setdefault('mcp', {})['openclaw'] = {
    'enabled': True,
    'type': 'http',
    'url': 'http://127.0.0.1:39051/mcp',
    'headers': {'Authorization': 'Bearer $TOKEN'}
}
with open('$CONFIG', 'w') as f:
    json.dump(d, f, indent=2)
"
echo "MCP grant renewed. Token: ${TOKEN:0:16}..."
