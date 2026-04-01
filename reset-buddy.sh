#!/usr/bin/env bash
# reset-buddy.sh — Reset Claude Code companion by regenerating userID and clearing companion data.
# New userID follows Claude's rule: randomBytes(32).toString('hex') → 64 hex chars.
#
# Usage: bash reset-buddy.sh [--dry-run]

set -euo pipefail

CONFIG_FILE="$HOME/.claude.json"
BACKUP_FILE="$HOME/.claude.json.buddy-backup.$(date +%Y%m%d%H%M%S)"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "Error: $CONFIG_FILE not found"
  exit 1
fi

DRY_RUN=false
if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=true
  echo "[dry-run] No changes will be written."
fi

# Validate current file is valid JSON
if ! python3 -c "import json, sys; json.load(open(sys.argv[1]))" "$CONFIG_FILE" 2>/dev/null; then
  echo "Error: $CONFIG_FILE is not valid JSON"
  exit 1
fi

# Show current state
OLD_USER_ID=$(python3 -c "import json; d=json.load(open('$CONFIG_FILE')); print(d.get('userID', '(not found)'))")
OLD_COMPANION=$(python3 -c "import json; d=json.load(open('$CONFIG_FILE')); c=d.get('companion'); print(json.dumps(c, ensure_ascii=False) if c else '(none)')")

echo "Current state:"
echo "  userID:    $OLD_USER_ID"
echo "  companion: $OLD_COMPANION"

# Generate new userID: same as Node's crypto.randomBytes(32).toString('hex')
NEW_USER_ID=$(python3 -c "import secrets; print(secrets.token_hex(32))")

echo ""
echo "New userID: $NEW_USER_ID"

if [ "$DRY_RUN" = true ]; then
  echo ""
  echo "[dry-run] Would write:"
  echo "  userID    → $NEW_USER_ID"
  echo "  companion → (removed)"
  exit 0
fi

# Backup original
cp "$CONFIG_FILE" "$BACKUP_FILE"
echo ""
echo "Backup saved: $BACKUP_FILE"

# Update JSON: set new userID, remove companion
python3 -c "
import json, sys

with open(sys.argv[1], 'r') as f:
    data = json.load(f)

data['userID'] = sys.argv[2]
data.pop('companion', None)

with open(sys.argv[1], 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')
" "$CONFIG_FILE" "$NEW_USER_ID"

# Verify
VERIFY_UID=$(python3 -c "import json; d=json.load(open('$CONFIG_FILE')); print(d.get('userID'))")
VERIFY_COMP=$(python3 -c "import json; d=json.load(open('$CONFIG_FILE')); print(d.get('companion', '(none)'))")

echo ""
echo "Done. Verified:"
echo "  userID:    $VERIFY_UID"
echo "  companion: $VERIFY_COMP"
echo ""
echo "Restart Claude Code and run /buddy to hatch a new companion."
