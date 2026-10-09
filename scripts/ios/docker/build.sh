#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname $0)"

CW_DOCKER_REGISTRY="${CW_DOCKER_REGISTRY:-localhost/cake-tech/cake_wallet}"
CW_DOCKER_USE_CLOUD="${CW_DOCKER_USE_CLOUD:-}"
IMAGE_PREFIX="ios-deps"

SCRIPT_DIR="$(pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

ONLY=""
TARGET=""
COIN=""
MERGE=false
IMAGE=""

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
    --image)
      IMAGE="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [--only base|torch|monero] [--coin COIN] [--target TRIPLE] [--merge] [--image base|torch|monero]"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

MONERO_COINS=(monero)
# simulator builds omitted for build time, add aarch64-apple-ios-simulator here if you need them
MONERO_TARGETS=(aarch64-apple-ios)

image_exists() {
  docker image inspect "$1" &>/dev/null
}

tinysha() {
  if command -v sha256sum >/dev/null 2>&1; then
    cat "$@" | sha256sum | cut -c1-6
  else
    cat "$@" | shasum -a 256 | cut -c1-6
  fi
}

monero_assembled_extra() {
  local tmp coin t
  tmp="$(mktemp)"
  for coin in "${MONERO_COINS[@]}"; do
    for t in "${MONERO_TARGETS[@]}"; do
      echo "-${coin}-${t}" >> "$tmp"
    done
  done
  echo "-merged-$(tinysha "$tmp")"
  rm -f "$tmp"
}

img() {
  local name="$1"
  local version="$2"
  local extra="${3:-}"
  echo "$CW_DOCKER_REGISTRY:${IMAGE_PREFIX}-${name}-$(tinysha "$SCRIPT_DIR/Dockerfile.${name}")-${version}${extra}"
}

remote_exists() {
  local tag="$1"
  if docker buildx version >/dev/null 2>&1; then
    docker buildx imagetools inspect "$tag" >/dev/null 2>&1
    return
  fi
  DOCKER_CLI_EXPERIMENTAL=enabled docker manifest inspect "$tag" >/dev/null 2>&1
}

cached() {
  local tag="$1"
  if image_exists "$tag"; then
    return 0
  fi
  if [[ "x$CW_DOCKER_USE_CLOUD" == "xtrue" ]] && remote_exists "$tag"; then
    return 0
  fi
  return 1
}

maybe_push() {
  local tag="$1"
  if [[ "x$CW_DOCKER_USE_CLOUD" == "xtrue" ]]; then
    docker push "$tag"
  fi
}

build() {
  local name="$1"; shift
  local version="$1"; shift
  local extra="$1"; shift
  local tag
  tag="$(img "$name" "$version" "$extra")"
  if cached "$tag"; then
    echo "==> skipping $name${extra} (cached: $tag)"
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
  if cached "$dest"; then
    echo "==> skipping merge $name (cached: $dest)"
    return 0
  fi

  local slices=("$@")
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
    if ! cached "$slice"; then
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
torch_ver="$(tinysha $SCRIPT_DIR/Dockerfile.torch $REPO_ROOT/scripts/prepare_torch.sh $REPO_ROOT/scripts/ios/build_torch.sh)"
monero_ver="$(tinysha $SCRIPT_DIR/Dockerfile.monero $REPO_ROOT/scripts/functions.sh $REPO_ROOT/scripts/prepare_moneroc.sh $REPO_ROOT/scripts/ios/build_monero_all.sh)"

# `./build.sh --image torch` prints the ref without touching docker, so the
# macOS runner can resolve the same tag before pulling it with crane.
if [[ -n "$IMAGE" ]]; then
  case "$IMAGE" in
    base)   img base   "$base_ver" ;;
    torch)  img torch  "$torch_ver" ;;
    monero) img monero "$monero_ver" "$(monero_assembled_extra)" ;;
    *) echo "usage: $0 --image base|torch|monero" >&2; exit 1 ;;
  esac
  exit 0
fi

build_base() {
  build base "$base_ver" ""
}

build_torch() {
  build torch "$torch_ver" "" --build-arg BASE_IMAGE="$(img base "$base_ver")"
  echo "done: $(img torch $torch_ver)"
  echo $(img torch $torch_ver) > /tmp/cakewallet_ios_torch
}

build_monero_slice() {
  local coin="$1"
  local target="$2"
  build monero "$monero_ver" "-${coin}-${target}" \
    --build-arg BASE_IMAGE="$(img base "$base_ver")" \
    --build-arg COIN="$coin" \
    --build-arg TARGET="$target"
}

build_monero() {
  local coins=("${MONERO_COINS[@]}")
  local targets=("${MONERO_TARGETS[@]}")
  local coin t
  [[ -n "$COIN" ]] && coins=("$COIN")
  [[ -n "$TARGET" ]] && targets=("$TARGET")
  for coin in "${coins[@]}"; do
    for t in "${targets[@]}"; do
      build_monero_slice "$coin" "$t"
    done
  done
}

merge_monero() {
  local slices=()
  local coin t
  for coin in "${MONERO_COINS[@]}"; do
    for t in "${MONERO_TARGETS[@]}"; do
      slices+=("$(img monero "$monero_ver" "-${coin}-${t}")")
    done
  done
  merge_slices monero "$monero_ver" "$(monero_assembled_extra)" "${slices[@]}"
  echo "done: $(img monero "$monero_ver" "$(monero_assembled_extra)")"
}

case "$ONLY" in
  "")
    build_base
    build_torch
    build_monero
    merge_monero
    ;;
  base)
    build_base
    ;;
  torch)
    build_base
    build_torch
    ;;
  monero)
    if [[ "$MERGE" == true ]]; then
      merge_monero
    else
      build_base
      build_monero
    fi
    ;;
  *)
    echo "Unknown component: $ONLY" >&2
    exit 1
    ;;
esac
