#!/usr/bin/env bash
set -uo pipefail

GODOT_BIN="${GODOT_BIN:-godot}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PORT="${SNOWDOWN_DISCONNECT_TEST_PORT:-7061}"
TMP="$(mktemp -d)"
SERVER_LOG="$TMP/server.log"
DROP_LOG="$TMP/drop.log"
REJOIN_LOG="$TMP/rejoin.log"
SERVER_PID=""
DROP_PID=""
REJOIN_PID=""

cleanup() {
  for pid in "$REJOIN_PID" "$DROP_PID" "$SERVER_PID"; do
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
      kill -KILL "$pid" 2>/dev/null || true
      wait "$pid" 2>/dev/null || true
    fi
  done
  rm -rf "$TMP"
}
trap cleanup EXIT

cd "$ROOT"
timeout --kill-after=2s 18s "$GODOT_BIN" --headless --path "$ROOT" -- --server --world=glacier_valley --port="$PORT" >"$SERVER_LOG" 2>&1 &
SERVER_PID=$!

for _ in $(seq 1 40); do
  if grep -q "SNOWDOWN_NETWORK_SERVER_READY" "$SERVER_LOG"; then break; fi
  if ! kill -0 "$SERVER_PID" 2>/dev/null; then cat "$SERVER_LOG"; exit 1; fi
  sleep 0.1
done
if ! grep -q "SNOWDOWN_NETWORK_SERVER_READY" "$SERVER_LOG"; then
  cat "$SERVER_LOG"
  echo "disconnect/rejoin server did not become ready" >&2
  exit 1
fi

# This client begins the deterministic pack->throw smoke action immediately after its
# network player exists. Killing it well before pack completion exercises disconnect
# cleanup while an authoritative hand action is in progress, before any throw can score.
timeout --kill-after=2s 12s "$GODOT_BIN" --headless --path "$ROOT" -- --connect=127.0.0.1 --port="$PORT" --network-smoke-name=DROP --network-smoke-expected=1 --network-smoke-action=pack_throw >"$DROP_LOG" 2>&1 &
DROP_PID=$!

for _ in $(seq 1 50); do
  if grep -q "\[Snowdown\]\[net\] connected peer=" "$DROP_LOG" && grep -q "peer joined" "$SERVER_LOG"; then break; fi
  if ! kill -0 "$DROP_PID" 2>/dev/null; then
    echo "--- server ---"; cat "$SERVER_LOG"; echo "--- dropped client ---"; cat "$DROP_LOG"; exit 1
  fi
  sleep 0.1
done
if ! grep -q "\[Snowdown\]\[net\] connected peer=" "$DROP_LOG"; then
  echo "--- server ---"; cat "$SERVER_LOG"; echo "--- dropped client ---"; cat "$DROP_LOG"
  echo "disconnect test client never connected" >&2
  exit 1
fi

sleep 0.45
kill -KILL "$DROP_PID" 2>/dev/null || true
wait "$DROP_PID" 2>/dev/null || true
DROP_PID=""

for _ in $(seq 1 40); do
  if grep -q "peer left .*roster=0" "$SERVER_LOG"; then break; fi
  if ! kill -0 "$SERVER_PID" 2>/dev/null; then cat "$SERVER_LOG"; exit 1; fi
  sleep 0.1
done
if ! grep -q "peer left .*roster=0" "$SERVER_LOG"; then
  echo "--- server ---"; cat "$SERVER_LOG"
  echo "server did not clean disconnected in-progress player" >&2
  exit 1
fi
if grep -q "SNOWDOWN_NETWORK_THROW_ACCEPTED" "$SERVER_LOG"; then
  echo "--- server ---"; cat "$SERVER_LOG"
  echo "disconnecting mid-pack unexpectedly completed a throw" >&2
  exit 1
fi

# A fresh client must still be able to join the same authoritative server after cleanup.
timeout --kill-after=2s 10s "$GODOT_BIN" --headless --path "$ROOT" -- --connect=127.0.0.1 --port="$PORT" --network-smoke-name=REJOIN --network-smoke-expected=1 >"$REJOIN_LOG" 2>&1 &
REJOIN_PID=$!
STATUS=0
wait "$REJOIN_PID" || STATUS=$?
REJOIN_PID=""
if [[ "$STATUS" -ne 0 ]]; then
  echo "--- server ---"; cat "$SERVER_LOG"; echo "--- rejoin client ---"; cat "$REJOIN_LOG"
  exit "$STATUS"
fi

if [[ $(grep -c "peer joined" "$SERVER_LOG") -lt 2 ]] || \
   ! grep -q "SNOWDOWN_NETWORK_CLIENT_READY name=REJOIN" "$REJOIN_LOG" || \
   ! kill -0 "$SERVER_PID" 2>/dev/null; then
  echo "--- server ---"; cat "$SERVER_LOG"; echo "--- rejoin client ---"; cat "$REJOIN_LOG"
  echo "disconnect/rejoin assertions failed" >&2
  exit 1
fi

echo "SNOWDOWN_DISCONNECT_REJOIN_OK"
