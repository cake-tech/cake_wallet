#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname $0)"

CW_DOCKER_REGISTRY="${CW_DOCKER_REGISTRY:-localhost/cake-tech/cake_wallet}"
CW_DOCKER_USE_CLOUD="${CW_DOCKER_USE_CLOUD:-}"

SCRIPT_DIR="$(pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

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

build() {
  local name="$1"; shift
  local version=$1; shift
  if [[ "x$CW_DOCKER_USE_CLOUD" == "xtrue" ]]
  then
    set +e
    docker images --format "{{.Repository}}:{{.Tag}} {{.ID}}" | \
      grep "^${CW_DOCKER_REGISTRY}:ios-deps-" | \
      awk '{print $2}' | \
      xargs -r docker rmi
    docker pull "$CW_DOCKER_REGISTRY:ios-deps-${name}-$(tinysha "$SCRIPT_DIR/Dockerfile.${name}")-${version}"
    set -e
  fi
  if image_exists "$CW_DOCKER_REGISTRY:ios-deps-${name}-$(tinysha "$SCRIPT_DIR/Dockerfile.${name}")-${version}"; then
    echo "==> skipping $name (image already exists)"
    return 0
  fi
  echo "==> building $name"
  docker build \
    --platform linux/amd64 \
    --file     "$SCRIPT_DIR/Dockerfile.${name}" \
    --tag      "$CW_DOCKER_REGISTRY:ios-deps-${name}-$(tinysha "$SCRIPT_DIR/Dockerfile.${name}")-${version}" \
    "$@" \
    "$REPO_ROOT"
  if [[ "x$CW_DOCKER_USE_CLOUD" == "xtrue" ]]
  then
    docker push "$CW_DOCKER_REGISTRY:ios-deps-${name}-$(tinysha "$SCRIPT_DIR/Dockerfile.${name}")-${version}"
  fi
}

img() {
    echo "$CW_DOCKER_REGISTRY:ios-deps-${1}-$(tinysha "$SCRIPT_DIR/Dockerfile.${1}")-${2}"
}

base_ver="latest"
torch_ver="$(tinysha $SCRIPT_DIR/Dockerfile.torch $REPO_ROOT/scripts/prepare_torch.sh $REPO_ROOT/scripts/ios/build_torch.sh)"

# `./build.sh --image torch` prints the ref without touching docker, so the
# macOS runner can resolve the same tag before pulling it with crane.
if [[ "${1:-}" == "--image" ]]; then
    case "${2:-}" in
        base)  img base  "$base_ver"  ;;
        torch) img torch "$torch_ver" ;;
        *) echo "usage: $0 --image base|torch" >&2; exit 1 ;;
    esac
    exit 0
fi

build base "$base_ver"

build torch "$torch_ver" --build-arg BASE_IMAGE="$(img base "$base_ver")"

echo "done: $(img torch $torch_ver)"
echo $(img torch $torch_ver) > /tmp/cakewallet_ios_torch
