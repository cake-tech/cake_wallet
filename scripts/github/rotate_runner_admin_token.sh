#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-adrienlacombe/cake_wallet}"
SECRET_NAME="${SECRET_NAME:-RUNNER_ADMIN_TOKEN}"
OWNER="${OWNER:-${REPO%%/*}}"
TOKEN_NAME="${TOKEN_NAME:-cake-wallet-runner-admin}"
TOKEN_DESCRIPTION="${TOKEN_DESCRIPTION:-Ephemeral self-hosted runner registration for ${REPO}}"
TOKEN_EXPIRY_DAYS="${TOKEN_EXPIRY_DAYS:-30}"
RUNNER_TOKEN_VALUE="${RUNNER_ADMIN_TOKEN_VALUE:-}"

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "missing required command: $1" >&2
    exit 1
  }
}

need gh
need python3

urlencode() {
  python3 - <<'PY' "$1"
import sys
import urllib.parse

print(urllib.parse.quote(sys.argv[1], safe=""))
PY
}

build_template_url() {
  printf '%s\n' "https://github.com/settings/personal-access-tokens/new?name=$(urlencode "$TOKEN_NAME")&description=$(urlencode "$TOKEN_DESCRIPTION")&target_name=$(urlencode "$OWNER")&expires_in=$(urlencode "$TOKEN_EXPIRY_DAYS")&actions=write&metadata=read"
}

set_secret() {
  if [[ -z "$RUNNER_TOKEN_VALUE" ]]; then
    if [[ -t 0 ]]; then
      read -r -s -p "Paste the fine-grained PAT for ${REPO}: " RUNNER_TOKEN_VALUE
      printf '\n' >&2
    else
      RUNNER_TOKEN_VALUE="$(cat)"
    fi
  fi

  if [[ -z "$RUNNER_TOKEN_VALUE" ]]; then
    echo "no token provided" >&2
    exit 1
  fi

  printf '%s' "$RUNNER_TOKEN_VALUE" | gh secret set "$SECRET_NAME" --repo "$REPO" --body -
  gh secret list --repo "$REPO" | grep -E "^${SECRET_NAME}[[:space:]]" >&2
}

case "${1:-print-url}" in
  print-url)
    build_template_url
    ;;
  set-secret)
    set_secret
    ;;
  rotate)
    echo "Create the token with this template URL:" >&2
    build_template_url >&2
    echo >&2
    echo "In the GitHub UI, set repository access to only ${REPO#*/}, then rerun:" >&2
    echo "  RUNNER_ADMIN_TOKEN_VALUE=<new-token> $0 set-secret" >&2
    ;;
  *)
    echo "usage: $0 [print-url|set-secret|rotate]" >&2
    exit 1
    ;;
esac
