# Intended to be sourced from any POSIX-like shell:
#   . scripts/prepare_minotari.sh [--update]

#######################################
# Safety
#######################################

set -u

#######################################
# Parse arguments (portable)
#######################################

UPDATE_CW=0

for arg in "$@"; do
  case "$arg" in
    --update)
      UPDATE_CW=1
      ;;
  esac
done

#######################################
# Resolve script directory (portable)
#######################################

SCRIPT_PATH="$0"
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

if [ "$UPDATE_CW" -eq 1 ] && [ -d "$CW_RUST_DIR" ]; then
  echo "🔄 --update specified: removing cw_minotari/rust"
  rm -rf "$CW_RUST_DIR"
fi

if [ ! -d "$CW_RUST_DIR" ]; then
  git clone "$CW_REPO_URL" "$CW_RUST_DIR"
fi

#######################################
# Build Rust code
#######################################

(
  cd "$CW_RUST_DIR" || exit 1
  cargo build
)

#######################################
# Flutter Rust Bridge codegen
#######################################

(
  cd "$CW_PARENT_DIR" || exit 0
  echo "⚙️  Running flutter_rust_bridge_codegen generate"

  if ! flutter_rust_bridge_codegen generate; then
    echo "⚠️  flutter_rust_bridge_codegen failed."
    echo "⚠️  This usually means rust_input is not configured yet."
    echo "⚠️  Continuing without aborting your shell."
  fi
)


#######################################
# Done
#######################################

echo "✅ Minotari prepared"
if [ "$UPDATE_CW" -eq 1 ]; then
  echo "✅ cw_tari_wallet refreshed, codegen run, and built"
else
  echo "✅ cw_tari_wallet codegen run and built"
fi
echo "DATABASE_URL remains exported in this shell"
