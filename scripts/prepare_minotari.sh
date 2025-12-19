# Intended to be sourced from any POSIX-like shell:
#   . scripts/prepare_minotari.sh

#######################################
# Safety
#######################################

# Do NOT use `set -e` in sourced scripts
set -u

#######################################
# Resolve script directory (portable)
#######################################

# $0 is reliable enough for sourced POSIX scripts when path is explicit
SCRIPT_PATH="$0"

# If sourced via relative path, normalize
case "$SCRIPT_PATH" in
  /*) ;;
  *) SCRIPT_PATH="$(pwd)/$SCRIPT_PATH" ;;
esac

SCRIPTS_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

#######################################
# Paths
#######################################

# scripts/minotari
MINOTARI_DIR="$SCRIPTS_DIR/minotari"
MINOTARI_REPO="minotari-cli"
MINOTARI_REPO_URL="git@github.com:tari-project/minotari-cli.git"

# sibling: ./cw_minotari/rust
PROJECT_ROOT="$(cd "$SCRIPTS_DIR/.." && pwd)"
CW_PARENT_DIR="$PROJECT_ROOT/cw_minotari"
CW_RUST_DIR="$CW_PARENT_DIR/rust"
CW_REPO_URL="https://github.com/tari-project/cw_tari_wallet.git"

#######################################
# Minotari setup
#######################################

mkdir -p "$MINOTARI_DIR"

if [ ! -d "$MINOTARI_DIR/$MINOTARI_REPO" ]; then
  git clone "$MINOTARI_REPO_URL" "$MINOTARI_DIR/$MINOTARI_REPO"
fi

mkdir -p "$MINOTARI_DIR/$MINOTARI_REPO/data"

DATA_DIR="$MINOTARI_DIR/$MINOTARI_REPO/data"
DATABASE_URL="sqlite://$DATA_DIR/wallet.db"
export DATABASE_URL

echo "DATABASE_URL set to:"
echo "  $DATABASE_URL"

(
  cd "$MINOTARI_DIR/$MINOTARI_REPO" || exit 1
  sqlx database create
  sqlx migrate run
)

#######################################
# cw_tari_wallet setup
#######################################

mkdir -p "$CW_PARENT_DIR"

if [ ! -d "$CW_RUST_DIR" ]; then
  git clone "$CW_REPO_URL" "$CW_RUST_DIR"
fi

(
  cd "$CW_RUST_DIR" || exit 1
  cargo build
)

#######################################
# Done
#######################################

echo "✅ Minotari prepared"
echo "✅ cw_tari_wallet built"
echo "DATABASE_URL remains exported in this shell"
