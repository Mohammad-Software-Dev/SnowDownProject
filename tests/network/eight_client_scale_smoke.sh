#!/usr/bin/env bash
set -uo pipefail

GODOT_BIN="${GODOT_BIN:-godot}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PORT="${SNOWDOWN_SCALE_TEST_PORT:-7030}"
TMP="$(mktemp -d)"
SERVER_LOG="$TMP/server.log"
SERVER_PID=""
CLIENT_PIDS=()
CLIENT_LOGS=()
NAMES=(A B C D E F G H)

cleanup() {
  for pid in "${CLIENT_PIDS[@]}"; do
    if kill -0 "$pid" 2>/dev/null; then kill "$pid" 2>/dev/null || true; wait "$pid" 2>/dev/null || true; fi
  done
  if [[ -n "$SERVER_PID" ]] && kill -0 "$SERVER_PID" 2>/dev/null; then kill "$SERVER_PID" 2>/dev/null || true; wait "$SERVER_PID" 2>/dev/null || true; fi
  rm -rf "$TMP"
}
trap cleanup EXIT

cd "$ROOT"
timeout 18s "$GODOT_BIN" --headless --path "$ROOT" -- \
  --server --world=glacier_valley --port="$PORT" \
  --network-smoke-layout=scale_4v4 --network-smoke-expected=8 >"$SERVER_LOG" 2>&1 &
SERVER_PID=$!

for _ in $(seq 1 50); do
  if grep -q "SNOWDOWN_NETWORK_SERVER_READY" "$SERVER_LOG"; then break; fi
  if ! kill -0 "$SERVER_PID" 2>/dev/null; then cat "$SERVER_LOG"; exit 1; fi
  sleep 0.1
done
if ! grep -q "SNOWDOWN_NETWORK_SERVER_READY" "$SERVER_LOG"; then
  cat "$SERVER_LOG"
  echo "4v4 scale server did not become ready" >&2
  exit 1
fi

for name in "${NAMES[@]}"; do
  log="$TMP/client_${name}.log"
  CLIENT_LOGS+=("$log")
  timeout 12s "$GODOT_BIN" --headless --path "$ROOT" -- \
    --connect=127.0.0.1 --port="$PORT" \
    --network-smoke-layout=scale_4v4 \
    --network-smoke-name="$name" --network-smoke-expected=8 \
    --network-smoke-action=pack_throw >"$log" 2>&1 &
  CLIENT_PIDS+=("$!")
  sleep 0.04
done

STATUS=0
for pid in "${CLIENT_PIDS[@]}"; do
  wait "$pid" || STATUS=$?
done

if [[ "$STATUS" -ne 0 ]]; then
  echo "--- server ---"; cat "$SERVER_LOG"
  for i in "${!NAMES[@]}"; do echo "--- client ${NAMES[$i]} ---"; cat "${CLIENT_LOGS[$i]}"; done
  exit "$STATUS"
fi

FAIL=0
[[ $(grep -c "peer joined" "$SERVER_LOG") -ge 8 ]] || FAIL=1
[[ $(grep -c "peer joined.*team=0" "$SERVER_LOG") -eq 4 ]] || FAIL=1
[[ $(grep -c "peer joined.*team=1" "$SERVER_LOG") -eq 4 ]] || FAIL=1
[[ $(grep -c "SNOWDOWN_NETWORK_THROW_ACCEPTED" "$SERVER_LOG") -ge 8 ]] || FAIL=1
grep -q "SNOWDOWN_MATCH_PHASE from=waiting to=countdown.*round=1" "$SERVER_LOG" || FAIL=1
grep -q "SNOWDOWN_MATCH_PHASE from=countdown to=active.*round=1" "$SERVER_LOG" || FAIL=1
grep -q "SNOWDOWN_SCALE_4V4_OK .*roster_peak=8 .*teams=4-4 .*throws=4-4 .*rejected=0" "$SERVER_LOG" || FAIL=1

for i in "${!NAMES[@]}"; do
  name="${NAMES[$i]}"
  log="${CLIENT_LOGS[$i]}"
  grep -q "SNOWDOWN_NETWORK_SNOWBALL_OK name=${name} authoritative_seen=1" "$log" || FAIL=1
  grep -q "SNOWDOWN_NETWORK_CLIENT_READY name=${name} .*roster=8" "$log" || FAIL=1
done

if [[ "$FAIL" -ne 0 ]]; then
  echo "--- server ---"; cat "$SERVER_LOG"
  for i in "${!NAMES[@]}"; do echo "--- client ${NAMES[$i]} ---"; cat "${CLIENT_LOGS[$i]}"; done
  echo "4v4 scale assertions failed" >&2
  exit 1
fi

echo "SNOWDOWN_EIGHT_CLIENT_SCALE_OK"
