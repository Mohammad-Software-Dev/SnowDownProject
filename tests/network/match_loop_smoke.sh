#!/usr/bin/env bash
set -uo pipefail

GODOT_BIN="${GODOT_BIN:-godot}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PORT="${SNOWDOWN_MATCH_TEST_PORT:-7020}"
TMP="$(mktemp -d)"
SERVER_LOG="$TMP/server.log"
CLIENT_A_LOG="$TMP/client_a.log"
CLIENT_B_LOG="$TMP/client_b.log"
SERVER_PID=""
CLIENT_A_PID=""
CLIENT_B_PID=""

cleanup() {
  for pid in "$CLIENT_A_PID" "$CLIENT_B_PID" "$SERVER_PID"; do
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then kill -KILL "$pid" 2>/dev/null || true; wait "$pid" 2>/dev/null || true; fi
  done
  rm -rf "$TMP"
}
trap cleanup EXIT

cd "$ROOT"
timeout --kill-after=2s 15s "$GODOT_BIN" --headless --path "$ROOT" -- --server --world=glacier_valley --port="$PORT" --match-smoke >"$SERVER_LOG" 2>&1 &
SERVER_PID=$!
for _ in $(seq 1 40); do
  if grep -q "SNOWDOWN_NETWORK_SERVER_READY" "$SERVER_LOG"; then break; fi
  if ! kill -0 "$SERVER_PID" 2>/dev/null; then cat "$SERVER_LOG"; exit 1; fi
  sleep 0.1
done
if ! grep -q "SNOWDOWN_NETWORK_SERVER_READY" "$SERVER_LOG"; then cat "$SERVER_LOG"; echo "match smoke server did not become ready" >&2; exit 1; fi

timeout --kill-after=2s 10s "$GODOT_BIN" --headless --path "$ROOT" -- --connect=127.0.0.1 --port="$PORT" --match-smoke --network-smoke-name=A --network-smoke-expected=2 --network-smoke-action=match_observe >"$CLIENT_A_LOG" 2>&1 &
CLIENT_A_PID=$!
sleep 0.10
timeout --kill-after=2s 10s "$GODOT_BIN" --headless --path "$ROOT" -- --connect=127.0.0.1 --port="$PORT" --match-smoke --network-smoke-name=B --network-smoke-expected=2 --network-smoke-action=match_observe >"$CLIENT_B_LOG" 2>&1 &
CLIENT_B_PID=$!

STATUS=0
wait "$CLIENT_A_PID" || STATUS=$?
wait "$CLIENT_B_PID" || STATUS=$?
if [[ "$STATUS" -ne 0 ]]; then
  echo "--- server ---"; cat "$SERVER_LOG"; echo "--- client A ---"; cat "$CLIENT_A_LOG"; echo "--- client B ---"; cat "$CLIENT_B_LOG"; exit "$STATUS"
fi

if ! grep -q "SNOWDOWN_MATCH_PHASE from=waiting to=countdown" "$SERVER_LOG" || \
   ! grep -q "SNOWDOWN_MATCH_PHASE from=countdown to=active" "$SERVER_LOG" || \
   ! grep -q "SNOWDOWN_MATCH_PHASE from=active to=sudden_snow" "$SERVER_LOG" || \
   ! grep -q "SNOWDOWN_MATCH_PHASE from=sudden_snow to=results.*score=1-0 winner=0" "$SERVER_LOG" || \
   ! grep -q "SNOWDOWN_MATCH_PHASE from=results to=countdown.*round=2 score=0-0" "$SERVER_LOG" || \
   ! grep -q "SNOWDOWN_MATCH_LOOP_OK name=A" "$CLIENT_A_LOG" || \
   ! grep -q "SNOWDOWN_MATCH_LOOP_OK name=B" "$CLIENT_B_LOG"; then
  echo "--- server ---"; cat "$SERVER_LOG"; echo "--- client A ---"; cat "$CLIENT_A_LOG"; echo "--- client B ---"; cat "$CLIENT_B_LOG"; echo "server-owned match loop assertions failed" >&2; exit 1
fi

echo "SNOWDOWN_SERVER_MATCH_LOOP_OK"
