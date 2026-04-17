#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname $0)"

CW_DOCKER_REGISTRY="${CW_DOCKER_REGISTRY:-localhost/cake-tech/cake_wallet}"
CW_DOCKER_FALLBACK_REGISTRY="${CW_DOCKER_FALLBACK_REGISTRY:-}"
CW_DOCKER_PUSH_REGISTRY="${CW_DOCKER_PUSH_REGISTRY:-$CW_DOCKER_REGISTRY}"
CW_DOCKER_USE_CLOUD="${CW_DOCKER_USE_CLOUD:-}"
CW_DOCKER_PULL_FROM_CLOUD="${CW_DOCKER_PULL_FROM_CLOUD:-$CW_DOCKER_USE_CLOUD}"
CW_DOCKER_PUSH_TO_CLOUD="${CW_DOCKER_PUSH_TO_CLOUD:-$CW_DOCKER_USE_CLOUD}"

SCRIPT_DIR="$(pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

image_exists() {
  docker image inspect "$1" &>/dev/null
}

tinysha() {
    cat "$@" | sha256sum | cut -c1-6
}

tag_suffix() {
  echo "android-deps-${1}-$(tinysha "$SCRIPT_DIR/Dockerfile.${1}")-${2}"
}

# Ensure an image exists locally under $CW_DOCKER_REGISTRY:<suffix>, by pull
# from primary, push, or fallback registry. Returns 0 on success, 1 on miss.
ensure_image() {
  local suffix="$1"
  local primary_tag="$CW_DOCKER_REGISTRY:$suffix"
  if image_exists "$primary_tag"; then
    return 0
  fi
  if [[ "x$CW_DOCKER_PULL_FROM_CLOUD" != "xtrue" ]]; then
    return 1
  fi
  set +e
  docker pull "$primary_tag" && { set -e; return 0; }
  if [[ "$CW_DOCKER_PUSH_REGISTRY" != "$CW_DOCKER_REGISTRY" ]]; then
    if docker pull "$CW_DOCKER_PUSH_REGISTRY:$suffix"; then
      docker tag "$CW_DOCKER_PUSH_REGISTRY:$suffix" "$primary_tag"
      set -e
      return 0
    fi
  fi
  if [[ -n "$CW_DOCKER_FALLBACK_REGISTRY" ]]; then
    if docker pull "$CW_DOCKER_FALLBACK_REGISTRY:$suffix"; then
      docker tag "$CW_DOCKER_FALLBACK_REGISTRY:$suffix" "$primary_tag"
      set -e
      return 0
    fi
  fi
  set -e
  return 1
}

build() {
  local name="$1"; shift
  local version=$1; shift
  local suffix="$(tag_suffix "$name" "$version")"
  local primary_tag="$CW_DOCKER_REGISTRY:$suffix"
  if ensure_image "$suffix"; then
    echo "==> skipping $name (image already exists)"
    return 0
  fi
  echo "==> building $name"
  docker build \
    --platform linux/amd64 \
    --file     "$SCRIPT_DIR/Dockerfile.${name}" \
    --tag      "$primary_tag" \
    "$@" \
    "$REPO_ROOT"
  if [[ "x$CW_DOCKER_PUSH_TO_CLOUD" == "xtrue" ]]; then
    local push_tag="$CW_DOCKER_PUSH_REGISTRY:$suffix"
    if [[ "$push_tag" != "$primary_tag" ]]; then
      docker tag "$primary_tag" "$push_tag"
    fi
    docker push "$push_tag"
  fi
}

img() {
    echo "$CW_DOCKER_REGISTRY:$(tag_suffix "$1" "$2")"
}

base_ver="latest"
torch_ver="$(tinysha $SCRIPT_DIR/Dockerfile.torch $REPO_ROOT/scripts/prepare_torch.sh $REPO_ROOT/scripts/android/build_torch.sh)"
reown_ver=$(tinysha $SCRIPT_DIR/Dockerfile.reown $REPO_ROOT/scripts/prepare_reown.sh $REPO_ROOT/scripts/android/build_reown_deps.sh)
bitbox_ver=$(tinysha $SCRIPT_DIR/Dockerfile.bitbox $REPO_ROOT/scripts/build_bitbox_flutter.sh)
monero_ver=$(tinysha $SCRIPT_DIR/Dockerfile.monero $REPO_ROOT/scripts/prepare_moneroc.sh $REPO_ROOT/scripts/android/build_monero_all.sh)
mwebd_ver=$(tinysha $SCRIPT_DIR/Dockerfile.mwebd $(find $REPO_ROOT/cw_mweb/go -type f))
zcash_ver=$(tinysha $SCRIPT_DIR/Dockerfile.zcash $REPO_ROOT/scripts/prepare_zcash.sh $REPO_ROOT/scripts/android/build_zcash.sh)
decred_ver=$(tinysha $SCRIPT_DIR/Dockerfile.torch $SCRIPT_DIR/Dockerfile.decred $REPO_ROOT/scripts/android/build_decred.sh)
echo $base_ver $torch_ver $reown_ver $bitbox_ver $monero_ver $mwebd_ver $zcash_ver $decred_ver > /tmp/docker_build_versions
final_ver=$(tinysha /tmp/docker_build_versions)

ensure_image "$(tag_suffix final "$final_ver")" || true

docker create --name temp_extract $(img final $final_ver) \
&& cd $REPO_ROOT \
&& docker cp temp_extract:/w.top w.top \
&& rsync -av w.top/ . \
&& rm -rf w.top \
&& docker rm temp_extract \
&& echo "cache ok" \
&& exit 0 \
|| echo "cache miss oh"

docker rm temp_extract || true

build base "$base_ver"

build bitbox "$bitbox_ver" --build-arg BASE_IMAGE="$(img base "$base_ver")"

build mwebd "$mwebd_ver" --build-arg BASE_IMAGE="$(img base "$base_ver")"

build reown "$reown_ver" --build-arg BASE_IMAGE="$(img base "$base_ver")"

build monero "$monero_ver" --build-arg BASE_IMAGE="$(img base "$base_ver")"

build zcash "$zcash_ver" --build-arg BASE_IMAGE="$(img base "$base_ver")"

build torch "$torch_ver" \
  --build-arg BASE_IMAGE="$(img base "$base_ver")"

build decred "$decred_ver" \
  --build-arg BASE_IMAGE="$(img base "$base_ver")" \
  --build-arg TORCH_IMAGE="$(img torch "$torch_ver")"

build final $final_ver \
  --build-arg BASE_IMAGE="$(img base $base_ver)" \
  --build-arg TORCH_IMAGE="$(img torch $torch_ver)" \
  --build-arg REOWN_IMAGE="$(img reown $reown_ver)" \
  --build-arg BITBOX_IMAGE="$(img bitbox $bitbox_ver)" \
  --build-arg MONERO_IMAGE="$(img monero $monero_ver)" \
  --build-arg DECRED_IMAGE="$(img decred $decred_ver)" \
  --build-arg MWEBD_IMAGE="$(img mwebd $mwebd_ver)" \
  --build-arg ZCASH_IMAGE="$(img zcash $zcash_ver)"

echo "done: $(img final $final_ver)"
echo $(img final $final_ver) > /tmp/cakewallet_docker


docker create --name temp_extract $(img final $final_ver) \
&& cd $REPO_ROOT \
&& docker cp temp_extract:/w.top w.top \
&& rsync -av w.top/ . \
&& rm -rf w.top \
&& docker rm temp_extract \
&& echo "cache ok" \
&& exit 0

echo idk.
exit 1
