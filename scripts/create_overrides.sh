#!/bin/bash

# Hello! o/
# If you are think there's a chance that you
# 1) want to update flutter sdk
# 2) want to update some dependency
# 3) want to add some dependency
# 4) are forking a dependency
# 5) something in the build process broke and you want to blame dependency pinning
# 6) the script is failing
#
#   In cases 1, 2, 3 you don't need to edit this script at all. Just add the dependency
# to either pubspec_base.yaml or cw_*/pubspec.yaml. and re-run this script.
#   In case 4 (or 6), do the same and add the dependency to
# package_repo_redirects - to redirect the dependency to your fork.
# repo_redirects - if the dependency was moved between git repos.
# version_ref_maps / dart_sdk_packages - if the dependency cannot be found upstream.
#   In case 5 remove pubspec_overrides.yaml, and just build the app. There is a non-zero
# chance that it won't work. And if it works look for the diff between whatever is on git
# and whatever is published on pub.dev tarball.
#   The script is designed in a way in which it is optional (so not using it should
# still result in a working build).
# In case of doubt git blame and ask the author ^^

set -e

cd "$(dirname "$0")/.."

yq() {
  go run github.com/mikefarah/yq/v4@latest "$@"
}

lockfile="$(pwd)/pubspec.lock"
pubspec_base="$(pwd)/pubspec_base.yaml"
overrides_file="$(pwd)/pubspec_overrides.yaml"
sdk_git_url=https://github.com/dart-lang/sdk

resolved_git_path=""
resolved_ref=""
git_url=""
override_url=""
override_path=""
version_ref_map_skip_verify=0

# old git url|new git url
repo_redirects=(
  "https://github.com/cmdrootaccess/another-flushbar|https://github.com/ideployed/another-flushbar"
  "https://github.com/anicdh|https://github.com/MrCyjaneK/bs58check.git"
  "https://github.com/MedzikUser/libcrypto-dart|https://github.com/MrCyjaneK/libcrypto.git"
  "https://github.com/rive-app/rive-flutter|https://github.com/MrCyjaneK/rive-flutter-no-lfs"
  "https://github.com/dart-lang/ffi|https://github.com/dart-lang/native"
)

# package|old git url|new git url (to move only one package out of a shared repo)
package_repo_redirects=(
  "rive_common|https://github.com/rive-app/rive-flutter|https://github.com/MrCyjaneK/rive_common"
  "fixnum_nanodart|https://github.com/dart-lang/fixnum|https://github.com/MrCyjaneK/fixnum_nanodart"
)

# package-version|git hash (exact match, or package-* to skip version check)
version_ref_maps=(
  "ffi-2.1.0|6bd0935f29c7294ebb9aab21c06b47b513def933"
  "flutter_rust_bridge-2.11.1|f19087cd0cac019b82d52cfa5153ce81b1b6e902"
)

dart_sdk_ref=$(cat $(dirname $(dirname $(which flutter)))/bin/cache/dart-sdk/revision)
dart_sdk_packages=(
  js vm_service
)

# Kept on pub.dev
skip_git_pin_packages=(
  _fe_analyzer_shared
  analyzer
  meta
)

lookup_version_ref_map() {
  local pkg=$1 ver=$2 entry key ref sdk_pkg
  version_ref_map_skip_verify=0
  for sdk_pkg in "${dart_sdk_packages[@]}"; do
    [[ "$pkg" == "$sdk_pkg" ]] || continue
    version_ref_map_skip_verify=1
    echo "$dart_sdk_ref"
    return 0
  done
  for entry in "${version_ref_maps[@]}"; do
    key="${entry%%|*}"
    ref="${entry#*|}"
    if [[ "$key" == "${pkg}-${ver}" ]]; then
      echo "$ref"
      return 0
    fi
    if [[ "$key" == "${pkg}-*" ]]; then
      version_ref_map_skip_verify=1
      echo "$ref"
      return 0
    fi
  done
  return 1
}

is_dart_sdk_package() {
  local pkg=$1 sdk_pkg
  for sdk_pkg in "${dart_sdk_packages[@]}"; do
    [[ "$pkg" == "$sdk_pkg" ]] && return 0
  done
  return 1
}

is_skip_git_pin_package() {
  local pkg=$1 skip_pkg
  for skip_pkg in "${skip_git_pin_packages[@]}"; do
    [[ "$pkg" == "$skip_pkg" ]] && return 0
  done
  return 1
}

apply_default_overrides() {
  [[ -f "$pubspec_base" ]] || return 0

  awk '
    /^# dependency_overrides:/ {
      in_block = 1
      print "dependency_overrides:"
      next
    }
    in_block && /^#[[:space:]]/ {
      sub(/^#[[:space:]]?/, "")
      print
      next
    }
    in_block && /^#/ {
      sub(/^#/, "")
      print
      next
    }
    in_block { exit }
  ' "$pubspec_base" > "$overrides_file"

  if [[ ! -s "$overrides_file" ]]; then
    rm -f "$overrides_file"
    return 0
  fi

  echo "applied default overrides from ${pubspec_base}"
}

normalize_url() {
  echo "$1" | sed 's|\.git$||'
}

normalize_git_path() {
  local path=$1
  [[ -z "$path" || "$path" == "." ]] && return 0
  [[ "$path" == ./* ]] && { echo "$path"; return 0; }
  echo "./${path}"
}

redirect_git_url() {
  local url=$1 package=${2:-} entry rest old new
  url=$(normalize_url "$url")

  if [[ -n "$package" ]]; then
    for entry in "${package_repo_redirects[@]}"; do
      [[ "${entry%%|*}" != "$package" ]] && continue
      rest="${entry#*|}"
      old=$(normalize_url "${rest%%|*}")
      new=$(normalize_url "${rest#*|}")
      [[ "$url" == "$old" ]] && { echo "$new"; return 0; }
    done
  fi

  for entry in "${repo_redirects[@]}"; do
    old=$(normalize_url "${entry%%|*}")
    new=$(normalize_url "${entry#*|}")
    [[ "$url" == "$old" ]] && { echo "$new"; return 0; }
  done
  echo "$1"
}

parse_github_repo_url() {
  local url=$1
  if [[ "$url" =~ github\.com/([^/]+)/([^/?#]+) ]]; then
    git_owner="${BASH_REMATCH[1]}"
    git_repo="${BASH_REMATCH[2]%.git}"
    git_url="https://github.com/${git_owner}/${git_repo}"
    if [[ "$url" =~ github\.com/[^/]+/[^/]+/(tree|blob)/[^/]+/(.+) ]]; then
      git_path="./${BASH_REMATCH[2]}"
    else
      git_path=""
    fi
    return 0
  fi
  return 1
}

pubdev_cache_file() {
  echo "$(pwd)/scripts/.cache/pubdev/${1}/${2}.json"
}

pubdev_repo_url() {
  local pkg=$1 ver=$2 cache_file
  cache_file=$(pubdev_cache_file "$pkg" "$ver")
  if [[ -f "$cache_file" ]]; then
    jq -r '.pubspec.repository // .pubspec.homepage // empty' "$cache_file"
    return 0
  fi
  mkdir -p "$(dirname "$cache_file")"
  curl -sf "https://pub.dev/api/packages/${pkg}/versions/${ver}" >"$cache_file"
  jq -r '.pubspec.repository // .pubspec.homepage // empty' "$cache_file"
}

repo_cache_dir() {
  echo "scripts/.cache/repos/$(normalize_url "$1" | sed 's|https://github.com/||; s|/|_|g')"
}

locks_dir="$(pwd)/scripts/.cache/locks"
rm -rf $locks_dir
mkdir -p $locks_dir

repo_lock_file() {
  local key=$1
  if [[ "$key" == */* || "$key" == scripts/* ]]; then
    echo "${locks_dir}/repo-$(basename "$key").lock"
  else
    echo "${locks_dir}/repo-$(normalize_url "$key" | sed 's|https://github.com/||; s|/|_|g').lock"
  fi
}

with_lock() {
  local lockpath=$1; shift
  mkdir -p "$(dirname "$lockpath")"
  while ! mkdir "$lockpath" 2>/dev/null; do
    sleep 0.05
  done
  local rc=0
  "$@" || rc=$?
  rmdir "$lockpath" 2>/dev/null || true
  return "$rc"
}

with_repo_lock() {
  with_lock "$(repo_lock_file "$1")" "${@:2}"
}

with_overrides_lock() {
  with_lock "${locks_dir}/overrides.lock" "$@"
}

_ensure_repo_clone() {
  local url=$1 cache_dir=$2
  [[ -d "${cache_dir}/.git" ]] && return 0
  mkdir -p "$(dirname "$cache_dir")"
  if [[ "$(normalize_url "$url")" == "$sdk_git_url" ]]; then
    git clone --quiet --filter=blob:none "$url" "$cache_dir" || return 1
  else
    git clone --quiet "$url" "$cache_dir" || return 1
  fi
}

ensure_repo_clone() {
  local url=$1 cache_dir=$2
  with_repo_lock "$cache_dir" _ensure_repo_clone "$url" "$cache_dir"
}

_ensure_git_ref() {
  local cache_dir=$1 ref=$2
  git -C "$cache_dir" cat-file -e "${ref}^{commit}" 2>/dev/null
}

ensure_git_ref() {
  with_repo_lock "$1" _ensure_git_ref "$@"
}

pubspec_field() {
  local content=$1 field=$2
  echo "$content" |
    grep -E "^${field}:[[:space:]]*" |
    head -1 |
    sed "s/^${field}:[[:space:]]*//" |
    tr -d "\"'" |
    sed 's/[[:space:]]*$//'
}

pubspec_matches() {
  local content=$1 package=$2 ver=${3:-}
  [[ "$(pubspec_field "$content" name)" == "$package" ]] || return 1
  [[ -z "$ver" || "$(pubspec_field "$content" version)" == "$ver" ]]
}

build_path_candidates() {
  local url=$1 package=$2 path=$3
  local candidate candidates=() seen=""

  add_candidate() {
    local c=$1
    if [[ -z "$c" ]]; then
      [[ " $seen " == *" __ROOT__ "* ]] && return
      seen="$seen __ROOT__"
      candidates+=("")
      return
    fi
    [[ " $seen " == *" $c "* ]] && return
    seen="$seen $c"
    candidates+=("$c")
  }

  if [[ -n "$path" ]]; then
    local normalized="${path#./}"
    normalized="${normalized%/}"
    if [[ "$normalized" != "packages" ]]; then
      local cache_dir content
      cache_dir=$(repo_cache_dir "$url")
      if ensure_repo_clone "$url" "$cache_dir"; then
        content=$(git -C "$cache_dir" show "HEAD:${normalized}/pubspec.yaml" 2>/dev/null) || content=""
        pubspec_matches "$content" "$package" && add_candidate "$normalized"
      fi
    fi
  fi

  local cache_dir pubspec_path dir content
  cache_dir=$(repo_cache_dir "$url")
  if ensure_repo_clone "$url" "$cache_dir"; then
    while IFS= read -r pubspec_path; do
      dir=$(dirname "$pubspec_path")
      content=$(git -C "$cache_dir" show "HEAD:${pubspec_path}" 2>/dev/null) || continue
      pubspec_matches "$content" "$package" || continue
      add_candidate "$dir"
    done < <(git -C "$cache_dir" ls-files | grep '/pubspec.yaml$')
  fi

  add_candidate "pkgs/${package}"
  add_candidate "packages/${package}"
  add_candidate "${package}"
  add_candidate ""
  printf '%s\n' "${candidates[@]}"
}

find_path_at_ref() {
  local url=$1 ref=$2 package=$3 ver=$4 hint_path=$5
  local cache_dir candidate pubspec_file content

  cache_dir=$(repo_cache_dir "$url")
  ensure_repo_clone "$url" "$cache_dir" || return 1
  ensure_git_ref "$cache_dir" "$ref" || return 1

  while IFS= read -r candidate; do
    pubspec_file=$([[ -n "$candidate" ]] && echo "${candidate}/pubspec.yaml" || echo "pubspec.yaml")
    content=$(git -C "$cache_dir" show "${ref}:${pubspec_file}" 2>/dev/null) || continue
    pubspec_matches "$content" "$package" "$ver" || continue
    [[ -n "$candidate" ]] && echo "./${candidate}"
    return 0
  done < <(build_path_candidates "$url" "$package" "$hint_path")
  return 1
}

_resolve_tag_ref() {
  local url=$1 pkg=$2 ver=$3 cache_dir ref tag

  cache_dir=$(repo_cache_dir "$url")
  _ensure_repo_clone "$url" "$cache_dir" || return 1

  for tag in "${ver}" "v${ver}" "${pkg}-${ver}" "${pkg}-v${ver}"; do
    ref=$(git -C "$cache_dir" rev-parse -q "refs/tags/${tag}^{commit}" 2>/dev/null) && {
      echo "$ref"
      return 0
    }
    ref=$(git -C "$cache_dir" rev-parse -q "refs/tags/${tag}" 2>/dev/null) && {
      echo "$ref"
      return 0
    }
  done
  return 1
}

resolve_tag_ref() {
  with_repo_lock "$1" _resolve_tag_ref "$@"
}

find_commit_for_package_version() {
  local url=$1 package=$2 ver=$3 hint_path=$4
  local cache_dir candidate pubspec_file ref content ver_try log_args
  local -a version_attempts=("$ver")

  [[ "$ver" != *-dev ]] && version_attempts+=("${ver}-dev")

  cache_dir=$(repo_cache_dir "$url")
  ensure_repo_clone "$url" "$cache_dir" || return 1

  while IFS= read -r candidate; do
    pubspec_file=$([[ -n "$candidate" ]] && echo "${candidate}/pubspec.yaml" || echo "pubspec.yaml")
    for ver_try in "${version_attempts[@]}"; do
      [[ "$ver_try" == "$ver" ]] && log_args=(--reverse) || log_args=()
      for ref in $(git -C "$cache_dir" log "${log_args[@]}" --format=%H -- "$pubspec_file" 2>/dev/null); do
        content=$(git -C "$cache_dir" show "${ref}:${pubspec_file}" 2>/dev/null) || continue
        pubspec_matches "$content" "$package" "$ver_try" || continue
        resolved_git_path=""
        [[ -n "$candidate" ]] && resolved_git_path="./${candidate}"
        resolved_ref="$ref"
        return 0
      done
    done
  done < <(build_path_candidates "$url" "$package" "$hint_path")
  return 1
}

resolve_git_override_for_package() {
  local package=$1 version=$2 repo_url=$3
  local original_git_url hint_path tag_ref path

  repo_url=$(redirect_git_url "$repo_url" "$package")
  parse_github_repo_url "$repo_url" || return 1

  original_git_url="$git_url"
  hint_path="$git_path"

  path=$(find_path_at_ref "$git_url" HEAD "$package" "" "$hint_path" || true)
  if [[ -n "$path" ]]; then
    hint_path="$path"
  elif [[ -z "$hint_path" && "$git_url" != "$original_git_url" ]]; then
    path=$(find_path_at_ref "$original_git_url" HEAD "$package" "" "" || true)
    if [[ -n "$path" ]]; then
      git_url="$original_git_url"
      hint_path="$path"
    fi
  fi

  resolved_git_path=""
  resolved_ref=""

  tag_ref=$(resolve_tag_ref "$git_url" "$package" "$version" || true)
  if [[ -n "$tag_ref" ]] &&
    path=$(find_path_at_ref "$git_url" "$tag_ref" "$package" "$version" "$hint_path"); then
    resolved_git_path="$path"
    resolved_ref="$tag_ref"
    return 0
  fi

  find_commit_for_package_version "$git_url" "$package" "$version" "$hint_path"
}

resolve_mapped_override() {
  local package=$1 version=$2 source=$3 lock_git_url=$4 lock_git_path=$5 mapped_ref=$6
  local repo_url path_ver

  if is_dart_sdk_package "$package"; then
    override_url="$sdk_git_url"
    override_path="./pkg/${package}"
    return 0
  fi

  if [[ "$source" == "git" ]]; then
    [[ -n "$lock_git_url" ]] || return 1
    override_url=$(redirect_git_url "$lock_git_url" "$package")
    override_path=$(normalize_git_path "$lock_git_path")
    return 0
  fi

  [[ "$source" == "hosted" ]] || return 1
  repo_url=$(pubdev_repo_url "$package" "$version")
  [[ -n "$repo_url" ]] || return 1
  repo_url=$(redirect_git_url "$repo_url" "$package")
  parse_github_repo_url "$repo_url" || return 1
  override_url="$git_url"
  path_ver="$version"
  [[ "$version_ref_map_skip_verify" == 1 ]] && path_ver=""
  override_path=$(find_path_at_ref "$git_url" "$mapped_ref" "$package" "$path_ver" "" || true)
  [[ -n "$override_path" ]]
}

has_git_override_in_yaml() {
  local pkg=$1
  [[ -f "$overrides_file" ]] || return 1
  yq -e ".dependency_overrides.\"${pkg}\".git" "$overrides_file" >/dev/null 2>&1
}

_add_git_override_to_yaml() {
  local pkg=$1 url=$2 path=$3 ref=$4 yq_expr

  [[ -f "$overrides_file" ]] || printf 'dependency_overrides: {}\n' > "$overrides_file"
  if has_git_override_in_yaml "$pkg"; then
    echo "$pkg: OK (default override)"
    return 0
  fi

  yq -i "del(.dependency_overrides.\"${pkg}\")" "$overrides_file"
  yq_expr=".dependency_overrides.\"${pkg}\".git.url = \"${url}\" | .dependency_overrides.\"${pkg}\".git.ref = \"${ref}\""
  [[ -n "$path" ]] && yq_expr+=" | .dependency_overrides.\"${pkg}\".git.path = \"${path}\""

  yq -i "$yq_expr" "$overrides_file" || {
    echo "$pkg: failed to update ${overrides_file}" >&2
    return 1
  }

  echo "added to ${overrides_file}:"
  echo "  ${pkg}:"
  echo "    git:"
  echo "      url: ${url}"
  [[ -n "$path" ]] && echo "      path: ${path}"
  echo "      ref: ${ref}"
}

add_git_override_to_yaml() {
  with_overrides_lock _add_git_override_to_yaml "$@"
}

sort_overrides_yaml() {
  yq -i \
    '.dependency_overrides = (.dependency_overrides | to_entries | sort_by(.key) | from_entries)' \
    "$overrides_file"
}

rm -f "$overrides_file"
apply_default_overrides
./configure_cake_wallet.sh android
flutter pub get

apply_default_overrides

mkdir -p "$locks_dir"

process_package() {
  local pkg=$1 package source version git_url git_ref git_path mapped_ref repo_url

  eval "$(jq -r '@sh "
    package=\(.package)
    source=\(.source)
    version=\(.version)
    git_url=\(.git_url)
    git_ref=\(.git_ref)
    git_path=\(.git_path)
  "' <<< "$pkg")"

  if has_git_override_in_yaml "$package"; then
    echo "$package: OK (default override)"
    return 0
  fi

  if is_skip_git_pin_package "$package"; then
    echo "$package: OK (version pinned, skipped)"
    return 0
  fi

  mapped_ref=$(lookup_version_ref_map "$package" "$version" || true)
  if [[ -n "$mapped_ref" ]]; then
    if ! resolve_mapped_override "$package" "$version" "$source" "$git_url" "$git_path" "$mapped_ref"; then
      echo "$package: NOT OK - could not apply version_ref_maps entry for ${version}" >&2
      return 1
    fi
    add_git_override_to_yaml "$package" "$override_url" "$override_path" "$mapped_ref" || return 1
    return 0
  fi

  case "$source" in
    git)
      if [[ -z "$git_url" || -z "$git_ref" ]]; then
        echo "$package: NOT OK - git dependency missing url or ref in ${lockfile}" >&2
        return 1
      fi
      add_git_override_to_yaml \
        "$package" \
        "$(redirect_git_url "$git_url" "$package")" \
        "$(normalize_git_path "$git_path")" \
        "$git_ref" || return 1
      ;;
    sdk)
      echo "$package: OK (sdk, skipped)"
      ;;
    hosted)
      repo_url=$(pubdev_repo_url "$package" "$version")
      if [[ -z "$repo_url" ]]; then
        echo "$package: NOT OK - could not find repository or homepage on pub.dev for ${version}"
        return 1
      fi
      if ! resolve_git_override_for_package "$package" "$version" "$repo_url"; then
        echo "$package: NOT OK - could not resolve git ref for version ${version} in ${git_url}"
        echo "# add manual mapping to version_ref_maps in scripts/create_overrides.sh:"
        echo "#   \"${package}-${version}|GIT_HASH\""
        echo "# repository: ${repo_url}"
        return 1
      fi
      add_git_override_to_yaml "$package" "$git_url" "$resolved_git_path" "$resolved_ref" || return 1
      ;;
    path)
      echo "$package: OK (path, skipped)"
      ;;
    *)
      echo "$package: NOT OK - source=${source} (cannot auto-generate git override)"
      return 1
      ;;
  esac
}

max_jobs=16
failed=0
batch=()
while IFS= read -r pkg; do
  process_package "$pkg" &
  batch+=($!)
  if ((${#batch[@]} >= max_jobs)); then
    for pid in "${batch[@]}"; do
      wait "$pid" || failed=1
    done
    batch=()
  fi
done < <(
  yq -o json '.packages' "$lockfile" | jq -c '
    to_entries[] | {
      package: .key,
      source: (.value.source // ""),
      version: (.value.version // ""),
      git_url: (if (.value.description | type) == "object" then .value.description.url // "" else "" end),
      git_ref: (if (.value.description | type) == "object" then (.value.description["resolved-ref"] // .value.description.ref // "") else "" end),
      git_path: (if (.value.description | type) == "object" then .value.description.path // "" else "" end)
    }
  '
)
for pid in "${batch[@]}"; do
  wait "$pid" || failed=1
done
[[ "$failed" -eq 0 ]] || exit 1

sort_overrides_yaml
