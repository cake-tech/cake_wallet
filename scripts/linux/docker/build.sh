#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname $0)"

CW_DOCKER_REGISTRY="${CW_DOCKER_REGISTRY:-localhost/cake-tech/cake_wallet}"
CW_DOCKER_USE_CLOUD="${CW_DOCKER_USE_CLOUD:-}"
IMAGE_PREFIX="linux-deps-amd64"

SCRIPT_DIR="$(pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

ONLY=""
TARGET=""
COIN=""
MERGE=false
EXTRACT=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --only)
      ONLY="$2"
      shift 2
      ;;
    --target)
      TARGET="$2"
      shift 2
      ;;
    --coin)
      COIN="$2"
      shift 2
      ;;
    --merge)
      MERGE=true
      shift
      ;;
    --extract)
      EXTRACT=true
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [--only NAME] [--target TRIPLE] [--coin COIN] [--merge] [--extract]"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

MONERO_COINS=(monero wownero)
MONERO_TARGETS=(x86_64-linux-gnu)

image_exists() {
  docker image inspect "$1" &>/dev/null
}

tinysha() {
  cat "$@" | sha256sum | cut -c1-6
}

slice_extra() {
  if [[ -n "$COIN" && -n "$TARGET" ]]; then
    echo "-${COIN}-${TARGET}"
  elif [[ -n "$TARGET" ]]; then
    echo "-${TARGET}"
  else
    echo ""
  fi
}

# Distinct from the unsuffixed all-in-one tag. The hash of slice suffixes
# invalidates the merge image if a coin or target is added or removed.
assembled_extra() {
  local tmp
  tmp="$(mktemp)"
  printf '%s\n' "$@" > "$tmp"
  echo "-merged-$(tinysha "$tmp")"
  rm -f "$tmp"
}

monero_assembled_extra() {
  local extras=()
  local coin t
  for coin in "${MONERO_COINS[@]}"; do
    for t in "${MONERO_TARGETS[@]}"; do
      extras+=("-${coin}-${t}")
    done
  done
  assembled_extra "${extras[@]}"
}

component_extra() {
  local name="$1"
  local sliced
  sliced="$(slice_extra)"
  if [[ -n "$sliced" ]]; then
    echo "$sliced"
    return
  fi
  case "$name" in
    monero) monero_assembled_extra ;;
    *) echo "" ;;
  esac
}

img() {
  local name="$1"
  local version="$2"
  local extra="${3:-}"
  echo "$CW_DOCKER_REGISTRY:${IMAGE_PREFIX}-${name}-$(tinysha "$SCRIPT_DIR/Dockerfile.${name}")-${version}${extra}"
}

maybe_pull() {
  local tag="$1"
  if [[ "x$CW_DOCKER_USE_CLOUD" == "xtrue" ]]; then
    docker pull "$tag" || true
  fi
}

maybe_push() {
  local tag="$1"
  if [[ "x$CW_DOCKER_USE_CLOUD" == "xtrue" ]]; then
    docker push "$tag"
  fi
}

build() {
  local name="$1"; shift
  local version=$1; shift
  local extra
  extra="$(component_extra "$name")"
  local tag
  tag="$(img "$name" "$version" "$extra")"
  maybe_pull "$tag"
  if image_exists "$tag"; then
    echo "==> skipping $name (image already exists: $tag)"
    return 0
  fi
  echo "==> building $name${extra}"
  docker build \
    --platform linux/amd64 \
    --file     "$SCRIPT_DIR/Dockerfile.${name}" \
    --tag      "$tag" \
    "$@" \
    "$REPO_ROOT"
  maybe_push "$tag"
}

merge_slices() {
  local name="$1"
  local version="$2"
  local extra="$3"
  shift 3
  local dest
  dest="$(img "$name" "$version" "$extra")"
  maybe_pull "$dest"
  if image_exists "$dest"; then
    echo "==> skipping merge $name (image already exists: $dest)"
    return 0
  fi

  local slices=("$@")
  if [[ ${#slices[@]} -eq 0 ]]; then
    echo "merge_slices: no slice images given" >&2
    exit 1
  fi

  local dockerfile
  dockerfile="$(mktemp)"
  local build_args=()
  local i=0
  for slice in "${slices[@]}"; do
    echo "ARG SRC${i}" >> "$dockerfile"
    i=$((i + 1))
  done
  i=0
  for slice in "${slices[@]}"; do
    maybe_pull "$slice"
    if ! image_exists "$slice"; then
      echo "merge_slices: missing slice $slice" >&2
      rm -f "$dockerfile"
      exit 1
    fi
    echo "FROM --platform=linux/amd64 \${SRC${i}} AS s${i}" >> "$dockerfile"
    build_args+=(--build-arg "SRC${i}=$slice")
    i=$((i + 1))
  done
  echo "FROM --platform=linux/amd64 alpine" >> "$dockerfile"
  i=0
  for slice in "${slices[@]}"; do
    echo "COPY --from=s${i} /w /w" >> "$dockerfile"
    i=$((i + 1))
  done

  echo "==> merging $name from ${#slices[@]} slices -> $dest"
  docker build \
    --platform linux/amd64 \
    --file "$dockerfile" \
    --tag "$dest" \
    "${build_args[@]}" \
    "$SCRIPT_DIR"
  rm -f "$dockerfile"
  maybe_push "$dest"
}

base_ver="latest"
torch_ver="$(tinysha $SCRIPT_DIR/Dockerfile.torch $REPO_ROOT/scripts/prepare_torch.sh $REPO_ROOT/scripts/linux/build_torch.sh)"
reown_ver=$(tinysha $SCRIPT_DIR/Dockerfile.reown $REPO_ROOT/scripts/prepare_reown.sh $REPO_ROOT/scripts/android/build_reown_deps.sh)
bitbox_ver=$(tinysha $SCRIPT_DIR/Dockerfile.bitbox $REPO_ROOT/scripts/build_bitbox_flutter.sh)
monero_ver=$(tinysha $SCRIPT_DIR/Dockerfile.monero $REPO_ROOT/scripts/prepare_moneroc.sh $REPO_ROOT/scripts/linux/build_monero_all.sh)
mwebd_ver=$(tinysha $SCRIPT_DIR/Dockerfile.mwebd $REPO_ROOT/pubspec_overrides.yaml $(find $REPO_ROOT/cw_mweb/go -type f))
zcash_ver=$(tinysha $SCRIPT_DIR/Dockerfile.zcash $REPO_ROOT/scripts/prepare_zcash.sh $REPO_ROOT/scripts/linux/build_zcash.sh)
echo $base_ver $torch_ver $reown_ver $bitbox_ver $monero_ver $mwebd_ver $zcash_ver "$(monero_assembled_extra)" > /tmp/docker_build_versions
final_ver=$(tinysha /tmp/docker_build_versions)

extract_final() {
  local required="${1:-}"
  local tag
  tag="$(img final "$final_ver")"
  maybe_pull "$tag"
  docker rm -f temp_extract >/dev/null 2>&1 || true
  if docker create --name temp_extract "$tag"; then
    cd "$REPO_ROOT"
    docker cp temp_extract:/w.top w.top
    rsync -av w.top/ .
    rm -rf w.top
    docker rm temp_extract
    echo "cache ok"
    echo "$tag" > /tmp/cakewallet_docker
    return 0
  fi
  docker rm -f temp_extract >/dev/null 2>&1 || true
  echo "cache miss oh"
  if [[ "$required" == "required" ]]; then
    echo "final image missing: $tag" >&2
    exit 1
  fi
  return 1
}

build_base() {
  build base "$base_ver"
}

build_bitbox() {
  build bitbox "$bitbox_ver" --build-arg BASE_IMAGE="$(img base "$base_ver")"
}

build_mwebd() {
  build mwebd "$mwebd_ver" --build-arg BASE_IMAGE="$(img base "$base_ver")"
}

build_reown() {
  build reown "$reown_ver" --build-arg BASE_IMAGE="$(img base "$base_ver")"
}

build_zcash() {
  build zcash "$zcash_ver" --build-arg BASE_IMAGE="$(img base "$base_ver")"
}

build_torch() {
  build torch "$torch_ver" \
    --build-arg BASE_IMAGE="$(img base "$base_ver")" \
    --build-arg TARGET="${TARGET}"
}

build_monero() {
  if [[ "$MERGE" == true ]]; then
    local slices=()
    local coin t
    for coin in "${MONERO_COINS[@]}"; do
      for t in "${MONERO_TARGETS[@]}"; do
        slices+=("$(img monero "$monero_ver" "-${coin}-${t}")")
      done
    done
    merge_slices monero "$monero_ver" "$(monero_assembled_extra)" "${slices[@]}"
    return 0
  fi
  build monero "$monero_ver" \
    --build-arg BASE_IMAGE="$(img base "$base_ver")" \
    --build-arg COIN="${COIN}" \
    --build-arg TARGET="${TARGET}"
}

build_final() {
  build final "$final_ver" \
    --build-arg BASE_IMAGE="$(img base "$base_ver")" \
    --build-arg TORCH_IMAGE="$(img torch "$torch_ver")" \
    --build-arg REOWN_IMAGE="$(img reown "$reown_ver")" \
    --build-arg BITBOX_IMAGE="$(img bitbox "$bitbox_ver")" \
    --build-arg MONERO_IMAGE="$(img monero "$monero_ver" "$(monero_assembled_extra)")" \
    --build-arg MWEBD_IMAGE="$(img mwebd "$mwebd_ver")" \
    --build-arg ZCASH_IMAGE="$(img zcash "$zcash_ver")"
  echo "done: $(img final $final_ver)"
  echo "$(img final $final_ver)" > /tmp/cakewallet_docker
}

run_one() {
  case "$1" in
    base) build_base ;;
    bitbox) build_bitbox ;;
    mwebd) build_mwebd ;;
    reown) build_reown ;;
    zcash) build_zcash ;;
    torch) build_torch ;;
    monero) build_monero ;;
    final) build_final ;;
    *)
      echo "Unknown component: $1" >&2
      exit 1
      ;;
  esac
}

if [[ "$EXTRACT" == true ]]; then
  extract_final required
  exit 0
fi

if [[ -z "$ONLY" ]]; then
  extract_final && exit 0 || true
  ONLY=""
  TARGET=""
  COIN=""
  MERGE=false
  build_base
  build_bitbox
  build_mwebd
  build_reown
  build_monero
  build_zcash
  build_torch
  build_final
  extract_final required
  exit 0
fi

run_one "$ONLY"
