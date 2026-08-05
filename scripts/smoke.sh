#!/usr/bin/env bash
# Smoke test for index.html — run after ANY edit to it.
#
# Why this exists: index.html is hand-maintained and is its own source of truth.
# Its worst historical failure was silent: a JS edit put `__archive` in the
# temporal dead zone, the whole script aborted, and every .reveal element stayed
# at opacity 0 — the page LOOKED blank while curl saw perfectly fine HTML. These
# checks are structure-level (not copy-level, copy changes often) so they survive
# wording edits but catch that class of breakage.
#
# Usage:  scripts/smoke.sh          (needs the gstack browse daemon binary)
set -uo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
B="${BROWSE_BIN:-$HOME/.claude/skills/gstack/browse/dist/browse}"
[ -x "$B" ] || { echo "smoke: browse binary not found at $B"; exit 2; }
PORT="${SMOKE_PORT:-8907}"

(cd "$ROOT" && exec python3 -m http.server "$PORT") >/dev/null 2>&1 &
SRV=$!
trap 'kill "$SRV" 2>/dev/null' EXIT
sleep 1

fail=0
expect() { # expect <desc> <js-expr> <want>
  local got
  got=$("$B" js "$2" 2>/dev/null)
  if [ "$got" = "$3" ]; then
    echo "  ok  $1"
  else
    echo "FAIL  $1   (got '$got', want '$3')"
    fail=1
  fi
}

"$B" viewport 1280x800 >/dev/null 2>&1
"$B" goto "http://localhost:$PORT/index.html" >/dev/null || { echo "smoke: goto failed"; exit 1; }
sleep 1.5

# The two silent killers seen in production: missing doctype (quirks mode) and
# missing charset (mojibake off GitHub Pages).
expect "standards mode (doctype present)"  "document.compatMode" "CSS1Compat"
expect "charset is UTF-8"                  "document.characterSet" "UTF-8"

# TDZ-class guard: if the script aborts, .reveal never gains .in and opacity stays 0.
expect "hero h1 present and non-empty" "!!document.querySelector('.hero h1')&&document.querySelector('.hero h1').textContent.trim().length>3" "true"
expect "hero reveal reached opacity 1" "getComputedStyle(document.querySelector('.hero .reveal')).opacity" "1"

# Live-data path: archive.json fetched, capped list rendered, view-more wired.
expect "archive list populated (1..10 rows)" "(n=>n>=1&&n<=10)(document.querySelectorAll('#archiveList a').length)" "true"

# Footer contract (kept in sync with publish_public.py::footer_html).
expect "footer has both RSS feed links" "document.querySelectorAll('footer a[href^=\"/feed-\"]').length" "2"

if "$B" console --errors 2>/dev/null | grep -q "(no console errors)"; then
  echo "  ok  no console errors"
else
  echo "FAIL  console has errors:"
  "$B" console --errors 2>/dev/null
  fail=1
fi

# Language switch round-trip.
"$B" js "localStorage.setItem('cr-lang','en')" >/dev/null 2>&1
"$B" reload >/dev/null 2>&1; sleep 1
expect "EN switch takes (html lang)" "document.documentElement.lang" "en"
expect "EN view-more points at EN archive" "document.getElementById('archiveMore').getAttribute('href')" "/archive-en.html"
"$B" js "localStorage.setItem('cr-lang','zh')" >/dev/null 2>&1
"$B" reload >/dev/null 2>&1; sleep 1
expect "ZH switch back (html lang)" "document.documentElement.lang" "zh"

if [ "$fail" = 0 ]; then echo "SMOKE PASS"; else echo "SMOKE FAIL"; exit 1; fi
