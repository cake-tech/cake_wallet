#!/bin/bash
# Fixture tests for tool/i18n_lint.dart: missing, ph-order, ph-missing and
# baseline filtering. No network or pub deps; run with `bash tool/i18n_lint_selftest.sh`.

set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

arb="$tmp/arb"
mkdir -p "$arb"

write_en() {
  cat > "$arb/strings_en.arb" <<'JSON'
{
  "greeting": "Hello",
  "trade": "Trade ${id} of ${title} not found.",
  "both": "From ${from} to ${to}"
}
JSON
}

write_clean() {
  cat > "$arb/strings_xx.arb" <<'JSON'
{
  "greeting": "हैलो",
  "trade": "ट्रेड ${id} का ${title} नहीं मिला।",
  "both": "${from} से ${to} तक"
}
JSON
}

failures=0

check() {
  local name="$1" expected="$2" fixture="$3" baseline="${4:-}"
  local args=(--arb-dir="$arb" --lang=xx --baseline="${baseline:-$tmp/empty.json}")
  write_en
  "$fixture"
  out="$(cd "$root" && dart tool/i18n_lint.dart "${args[@]}" 2>&1)"
  actual=$?
  if [ "$actual" -eq "$expected" ]; then
    echo "ok   $name"
  else
    echo "FAIL $name (expected exit $expected, got $actual)"
    echo "$out" | tail -5
    failures=$((failures + 1))
  fi
}

clean_fixture() { write_clean; }

missing_fixture() {
  write_clean
  python3 - "$arb/strings_xx.arb" <<'PY'
import json, sys
p = sys.argv[1]
d = json.load(open(p))
del d["greeting"]
json.dump(d, open(p, "w"), ensure_ascii=False)
PY
}

order_fixture() {
  write_clean
  python3 - "$arb/strings_xx.arb" <<'PY'
import json, sys
p = sys.argv[1]
d = json.load(open(p))
d["trade"] = "ट्रेड ${title} का ${id} नहीं मिला।"
json.dump(d, open(p, "w"), ensure_ascii=False)
PY
}

dropped_fixture() {
  write_clean
  python3 - "$arb/strings_xx.arb" <<'PY'
import json, sys
p = sys.argv[1]
d = json.load(open(p))
d["both"] = "${from} से"
json.dump(d, open(p, "w"), ensure_ascii=False)
PY
}

check "clean locale passes" 0 clean_fixture
check "missing key warns" 0 missing_fixture
check "placeholder reorder fails" 1 order_fixture
check "dropped placeholder fails" 1 dropped_fixture

# baseline filtering: accept the reorder, then it must pass
write_en
order_fixture
baseline="$tmp/baseline.json"
(cd "$root" && dart tool/i18n_lint.dart --arb-dir="$arb" --lang=xx --baseline="$baseline" --update-baseline >/dev/null 2>&1)
check "baselined reorder passes" 0 order_fixture "$baseline"

# strict mode promotes the missing warning to a failure
write_en
missing_fixture
out="$(cd "$root" && dart tool/i18n_lint.dart --arb-dir="$arb" --lang=xx --baseline="$tmp/empty2.json" --strict 2>&1)"
if [ $? -eq 1 ]; then echo "ok   missing key fails under --strict"; else echo "FAIL --strict"; echo "$out" | tail -3; failures=$((failures + 1)); fi

if [ "$failures" -ne 0 ]; then
  echo "$failures fixture(s) failed"
  exit 1
fi

echo "all i18n_lint fixtures passed"
