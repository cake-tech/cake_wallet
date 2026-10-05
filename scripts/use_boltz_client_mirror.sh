#!/bin/bash
# breez deleted https://github.com/breez/boltz-client. spark-sdk still depends
# on that URL at rev b5f4683aba10efd875d674f2bb9a5800b047a879... this is a temporary fix.
set -euo pipefail

git config --global \
  url."https://github.com/MrCyjaneK/boltz-client-mirror".insteadOf \
  "https://github.com/breez/boltz-client"

cargo_dir="${CARGO_HOME:-${HOME:?HOME is unset}/.cargo}"
mkdir -p "$cargo_dir"
cargo_config="${cargo_dir}/config.toml"
if [[ ! -f "$cargo_config" ]] || ! grep -q 'git-fetch-with-cli' "$cargo_config"; then
  printf '\n[net]\ngit-fetch-with-cli = true\n' >> "$cargo_config"
fi
