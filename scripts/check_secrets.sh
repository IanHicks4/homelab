#!/usr/bin/env bash
set -euo pipefail

PATTERN='password|passwd|token|secret|apikey|api_key|api-key|private|wireguard|admin_token'

echo "Checking tracked files for secret-like strings..."
git grep -nEi "$PATTERN" -- . \
  ':!.gitignore' \
  ':!*.env' \
  ':!**/.env' \
  ':!*.env.example' \
  ':!**/*.env.example' || true

echo
echo "Checking staged diff for secret-like strings..."
git diff --cached | grep -Ei "$PATTERN" || true

echo
echo "Reminder: review findings manually. Variable names and blank examples may be expected."
