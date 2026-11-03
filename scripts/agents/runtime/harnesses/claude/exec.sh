#!/usr/bin/env bash

# SPDX-FileCopyrightText: Copyright (c) 2025-2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "usage: exec.sh <prompt-file>" >&2
    exit 2
fi

[[ -n "${CLAUDE_CODE_OAUTH_TOKEN:-}" ]] || { echo "missing required env: CLAUDE_CODE_OAUTH_TOKEN" >&2; exit 1; }

PROMPT_FILE="$1"
export HOME="${OPENSHELL_AGENT_HOME:-/sandbox/home}"
export DISABLE_AUTOUPDATER=1
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
mkdir -p "$HOME/.claude"
# No AI attribution in commits or PRs made by lanes. Long commands (a full build or test suite in a
# batch review) may run up to two hours instead of Claude Code's 10-minute default cap.
cat > "$HOME/.claude/settings.json" <<'JSON'
{
  "includeCoAuthoredBy": false,
  "attribution": { "commit": "", "pr": "" },
  "env": { "BASH_DEFAULT_TIMEOUT_MS": "7200000", "BASH_MAX_TIMEOUT_MS": "7200000" }
}
JSON

WORK="${OPENSHELL_AGENT_WORKDIR:-$(mktemp -d)}"
mkdir -p "$WORK"
cd "$WORK"

CLAUDE_BIN="${CLAUDE_BIN:-claude}"
CLAUDE_MODEL="${CLAUDE_MODEL:-sonnet}"

echo "openshell-agent: invoking Claude Code bounded cycle (model=$CLAUDE_MODEL, workdir=$WORK)" >&2

# The sandbox is the permission boundary, so Claude Code's own prompts are skipped.
exec "$CLAUDE_BIN" -p \
    --model "$CLAUDE_MODEL" \
    --output-format text \
    --dangerously-skip-permissions \
    --no-session-persistence \
    < "$PROMPT_FILE"
