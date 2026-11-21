#!/usr/bin/env bash
# Tests the reviewer view of scripts/admit for both entry kinds and for an
# archive whose tables do not match the entry kind (the view must fail closed).
#
#   tests/admit-reviewer-view.sh        needs bash, zstd, tar and python3 >= 3.11
set -Eeuo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
scratch="$(mktemp -d)"
trap 'rm -rf -- "$scratch"' EXIT

# scripts/admit reads these at load time; the reviewer view uses WORK and SUMMARY only.
export CORE_DIR="$scratch/core" BASE_REF="HEAD" WORK="$scratch/work" SUMMARY="$scratch/summary.md" GH_TOKEN="unused"
mkdir -p "$WORK"
# shellcheck source=../scripts/admit
source "$here/../scripts/admit"
# The sourced file installs an ERR trap that calls fail(); a case reports its own result.
trap - ERR

failures=0

# run_case <name> <entry kind> <fixture dir> <expect: ok|fail> <detect.toml expected in the view: yes|no>
run_case() {
  local name="$1" kind="$2" fixture="$3" expect="$4" detect="$5" rc=0 view
  archive="$scratch/$name.tar.zst"
  # Members are stored without a leading "./", as `xtask plugin build` writes them.
  (cd "$here/fixtures/$fixture" && tar -cf - -- *) | zstd -q -f -o "$archive"
  : >"$SUMMARY"
  rm -rf -- "$WORK/existing" "$WORK/unpacked"
  entry_kind="$kind"
  package_id="pohunek.fixture"
  # reviewer_view() calls fail(), which exits: run it in a subshell.
  (reviewer_view) >/dev/null || rc=$?
  view="$(cat -- "$SUMMARY")"
  if [ "$expect" = "ok" ]; then
    [ "$rc" -eq 0 ] || { echo "FAIL $name: expected success, rc=$rc"; failures=$((failures + 1)); return; }
    case "$view" in *"### runtime.toml"*) ;; *) echo "FAIL $name: runtime.toml missing from the view"; failures=$((failures + 1)); return ;; esac
    case "$view" in
      *"### detect.toml"*) [ "$detect" = "yes" ] || { echo "FAIL $name: unexpected detect.toml in the view"; failures=$((failures + 1)); return; } ;;
      *) [ "$detect" = "no" ] || { echo "FAIL $name: detect.toml missing from the view"; failures=$((failures + 1)); return; } ;;
    esac
  else
    [ "$rc" -ne 0 ] || { echo "FAIL $name: expected a refusal, rc=0"; failures=$((failures + 1)); return; }
    case "$view" in *"reviewer view"*"fail"*) ;; *) echo "FAIL $name: no failure row in the summary"; failures=$((failures + 1)); return ;; esac
  fi
  echo "ok   $name"
}

run_case context-entry-context-archive context context ok no
run_case runtime-entry-runtime-archive runtime runtime ok yes
run_case context-entry-runtime-archive context runtime fail no
run_case runtime-entry-context-archive runtime context fail no
run_case context-entry-both-tables context both-tables fail no
run_case runtime-entry-both-tables runtime both-tables fail no
run_case runtime-entry-no-detect-manifest runtime runtime-no-manifest fail no

if [ "$failures" -ne 0 ]; then
  echo "$failures case(s) failed" >&2
  exit 1
fi
echo "all cases passed"
