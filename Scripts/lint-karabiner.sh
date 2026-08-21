#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="$ROOT/Karabiner/windowsmac.json"
CLI="/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli"

python3 -m json.tool "$CONFIG" >/dev/null

if [[ -x "$CLI" ]]; then
  "$CLI" --lint-complex-modifications "$CONFIG"
else
  echo "Karabiner CLI not installed; JSON syntax validation passed."
fi
