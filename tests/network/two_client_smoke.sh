#!/usr/bin/env bash
set -uo pipefail

GODOT_BIN="${GODOT_BIN:-godot}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PORT="${SNOWDOWN_TEST_PORT:-7011}"
TMP="$(mktemp -d)"
SERVER_LOG="$TMP/server.log"
CLIENT_A_LOG="$TMP/client_a.log"
CLIENT_B_LOG="$TMP/client_b.log"
SERVER_PID=""

cleanup() {
  if [[ -n "$SERVER_PID" ]] && kill -0 "$SERVER_PID" 2>/dev/null; then
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
  fi
  rm -rf "$TMP"
}
trap cleanup EXIT

cd "$ROOT"
timeout 15s "$GODOT_BIN" --headless --path "$ROOT" -- --server --world=glacier_valley --port="$PORT" >"$SERVER_LOG" 2>&1 &
SERVER_PID=$!

for _ in $(seq 1 40); do
  if grep -q "SNOWDOWN_NETWORK_SERVER_READY" "$SERVER_LOG"; then
    break
  fi
  if ! kill -0 "$SERVER_PID" 2>/dev/null; then
    cat "$SERVER_LOG"
    exit 1
  fi
  sleep 0.1
done

if ! grep -q "SNOWDOWN_NETWORK_SERVER_READY" "$SERVER_LOG"; then
  cat "$SERVER_LOG"
  echo "network server did not become ready" >&2
  exit 1
fi

timeout 12s "$GODOT_BIN" --headless --path "$ROOT" -- --connect=127.0.0.1 --port="$PORT" --network-smoke-name=A --network-smoke-expected=2 >"$CLIENT_A_LOG" 2>&1 &
CLIENT_A_PID=$!
sleep 0.25
timeout 12s "$GODOT_BIN" --headless --path "$ROOT" -- --connect=127.0.0.1 --port="$PORT" --network-smoke-name=B --network-smoke-expected=2 >"$CLIENT_B_LOG" 2>&1 &
CLIENT_B_PID=$!

STATUS=0
wait "$CLIENT_A_PID" || STATUS=$?
wait "$CLIENT_B_PID" || STATUS=$?

if [[ "$STATUS" -ne 0 ]]; then
  echo "--- server ---"; cat "$SERVER_LOG"
  echo "--- client A ---"; cat "$CLIENT_A_LOG"
  echo "--- client B ---"; cat "$CLIENT_B_LOG"
  exit "$STATUS"
fi

if [[ $(grep -c "peer joined" "$SERVER_LOG") -lt 2 ]] || \
   ! grep -q "SNOWDOWN_NETWORK_CLIENT_READY name=A.*roster=2" "$CLIENT_A_LOG" || \
   ! grep -q "SNOWDOWN_NETWORK_CLIENT_READY name=B.*roster=2" "$CLIENT_B_LOG"; then
  echo "--- server ---"; cat "$SERVER_LOG"
  echo "--- client A ---"; cat "$CLIENT_A_LOG"
  echo "--- client B ---"; cat "$CLIENT_B_LOG"
  echo "two-client network assertions failed" >&2
  exit 1
fi

echo "SNOWDOWN_TWO_CLIENT_NETWORK_OK"
