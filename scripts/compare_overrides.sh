#!/bin/bash

# usage:
# ./compare_overrides.sh GIT_HASH_A GIT_HASH_B

set -e
cd "$(dirname "$0")/.."

HASH_A=${1:?usage: ./compare_overrides.sh GIT_HASH_A GIT_HASH_B}
HASH_B=${2:?usage: ./compare_overrides.sh GIT_HASH_A GIT_HASH_B}

sdk_git_url=https://github.com/dart-lang/sdk

yq() {
  go run github.com/mikefarah/yq/v4@latest "$@"
}

normalize_url() {
  echo "$1" | sed 's|\.git$||'
}

repo_cache_dir() {
  echo "scripts/.cache/repos/$(normalize_url "$1" | sed 's|https://github.com/||; s|/|_|g')"
}

ensure_repo_clone() {
  local url=$1 cache_dir=$2
  if [[ -d "${cache_dir}/.git" ]]; then
    git -C "$cache_dir" fetch --quiet origin
  else
    mkdir -p "$(dirname "$cache_dir")"
    if [[ "$(normalize_url "$url")" == "$sdk_git_url" ]]; then
      git clone --quiet --filter=blob:none "$url" "$cache_dir" || return 1
    else
      git clone --quiet "$url" "$cache_dir" || return 1
    fi
  fi
}

normalize_repo_path() {
  local path=$1
  [[ -z "$path" || "$path" == "-" ]] && return 0
  echo "${path#./}"
}

ensure_ref() {
  local cache_dir=$1 ref=$2
  git -C "$cache_dir" cat-file -e "${ref}^{commit}" 2>/dev/null && return 0
  git -C "$cache_dir" fetch --quiet origin "$ref" 2>/dev/null || true
  git -C "$cache_dir" cat-file -e "${ref}^{commit}" 2>/dev/null
}

count_lines_at_ref() {
  local cache_dir=$1 ref=$2 path=$3
  local repo_path file lines total=0

  ensure_ref "$cache_dir" "$ref" || return 1
  repo_path=$(normalize_repo_path "$path")

  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    lines=$(git -C "$cache_dir" show "$ref:$file" 2>/dev/null | wc -l | tr -d ' ')
    total=$((total + lines))
  done < <(
    if [[ -n "$repo_path" ]]; then
      git -C "$cache_dir" ls-tree -r --name-only "$ref" -- "$repo_path" 2>/dev/null
    else
      git -C "$cache_dir" ls-tree -r --name-only "$ref" 2>/dev/null
    fi
  )

  echo "$total"
}

print_ref_diff() {
  local cache_dir=$1 old_ref=$2 new_ref=$3 old_path=$4 new_path=$5
  local repo_path diff_paths=() path

  ensure_ref "$cache_dir" "$old_ref" || {
    echo "    diff  (old ref not found: $old_ref)"
    return 1
  }
  ensure_ref "$cache_dir" "$new_ref" || {
    echo "    diff  (new ref not found: $new_ref)"
    return 1
  }

  for path in "$old_path" "$new_path"; do
    repo_path=$(normalize_repo_path "$path")
    [[ -z "$repo_path" ]] && continue
    [[ " ${diff_paths[*]} " == *" $repo_path "* ]] && continue
    diff_paths+=("$repo_path")
  done

  if [[ ${#diff_paths[@]} -eq 0 ]]; then
    git -C "$cache_dir" diff --stat "$old_ref" "$new_ref" | sed 's/^/    /'
  else
    git -C "$cache_dir" diff --stat "$old_ref" "$new_ref" -- "${diff_paths[@]}" | sed 's/^/    /'
  fi
}

overrides_json_git() {
  git show "${1}:pubspec_overrides.yaml" | yq -o=json '.dependency_overrides // {}'
}

overrides_json_worktree() {
  yq -o=json '.dependency_overrides // {}' pubspec_overrides.yaml
}

print_git_fields() {
  local pkg=$1 old_url=$2 new_url=$3 old_ref=$4 new_ref=$5 old_path=$6 new_path=$7
  echo "  $pkg"
  echo "    url   $old_url -> $new_url"
  echo "    ref   $old_ref -> $new_ref"
  echo "    path  $old_path -> $new_path"
}

print_new_repo_stats() {
  local new_url=$1 new_ref=$2 new_path=$3 cache_dir loc

  [[ "$new_url" == "-" || "$new_ref" == "-" ]] && return 0

  cache_dir=$(repo_cache_dir "$new_url")
  if ! ensure_repo_clone "$new_url" "$cache_dir"; then
    echo "    loc   (clone failed)"
    return 0
  fi

  if loc=$(count_lines_at_ref "$cache_dir" "$new_ref" "$new_path"); then
    echo "    loc   $loc lines"
  else
    echo "    loc   (ref not found: $new_ref)"
  fi
}

print_changed_ref_stats() {
  local url=$1 old_ref=$2 new_ref=$3 old_path=$4 new_path=$5 cache_dir

  [[ "$url" == "-" || "$old_ref" == "-" || "$new_ref" == "-" ]] && return 0

  cache_dir=$(repo_cache_dir "$url")
  if ! ensure_repo_clone "$url" "$cache_dir"; then
    echo "    diff  (clone failed)"
    return 0
  fi

  print_ref_diff "$cache_dir" "$old_ref" "$new_ref" "$old_path" "$new_path"
}

compare_overrides_jq='
  def git($obj; $pkg): $obj[$pkg].git // null;
  def fields($obj; $pkg):
    git($obj; $pkg) as $g |
    [($g.url // ""), ($g.ref // ""), ($g.path // "")];
  def dash($v): if $v == "" then "-" else $v end;
'

resolved_a=$(git rev-parse "$HASH_A")
resolved_b=$(git rev-parse "$HASH_B")
resolved_head=$(git rev-parse HEAD)

if [[ "$resolved_a" == "$resolved_b" ]]; then
  json_a=$(overrides_json_git "$HASH_A")
  json_b=$(overrides_json_git "$HASH_B")
elif [[ "$resolved_b" == "$resolved_head" ]]; then
  json_a=$(overrides_json_git "$HASH_A")
  json_b=$(overrides_json_worktree)
else
  json_a=$(overrides_json_git "$HASH_A")
  json_b=$(overrides_json_git "$HASH_B")
fi

new_output=$(
  jq -r -n --argjson a "$json_a" --argjson b "$json_b" "$compare_overrides_jq"'
    ($b | keys[] | select(git($b; .))) as $pkg |
    select((git($a; $pkg) | not) or git($a; $pkg).url != git($b; $pkg).url) |
    (fields($a; $pkg)) as $old |
    (fields($b; $pkg)) as $new |
    [
      $pkg,
      dash($old[0]), dash($new[0]),
      dash($old[1]), dash($new[1]),
      dash($old[2]), dash($new[2])
    ] | @tsv
  ' | while IFS=$'\t' read -r pkg old_url new_url old_ref new_ref old_path new_path; do
    print_git_fields "$pkg" "$old_url" "$new_url" "$old_ref" "$new_ref" "$old_path" "$new_path"
    print_new_repo_stats "$new_url" "$new_ref" "$new_path"
  done
)

changed_output=$(
  jq -r -n --argjson a "$json_a" --argjson b "$json_b" "$compare_overrides_jq"'
    ($b | keys[] | select(git($b; .) and git($a; .))) as $pkg |
    select(git($a; $pkg).url == git($b; $pkg).url) |
    select((git($a; $pkg).ref // "") != (git($b; $pkg).ref // "")) |
    (fields($a; $pkg)) as $old |
    (fields($b; $pkg)) as $new |
    [
      $pkg,
      dash($old[0]), dash($new[0]),
      dash($old[1]), dash($new[1]),
      dash($old[2]), dash($new[2])
    ] | @tsv
  ' | while IFS=$'\t' read -r pkg old_url new_url old_ref new_ref old_path new_path; do
    print_git_fields "$pkg" "$old_url" "$new_url" "$old_ref" "$new_ref" "$old_path" "$new_path"
    print_changed_ref_stats "$new_url" "$old_ref" "$new_ref" "$old_path" "$new_path"
  done
)

if [[ -n "$new_output" ]]; then
  echo "new git repos:"
  echo "$new_output"
fi

if [[ -n "$new_output" && -n "$changed_output" ]]; then
  echo
fi

if [[ -n "$changed_output" ]]; then
  echo "changed git refs:"
  echo "$changed_output"
fi
