#!/usr/bin/env bash
set -uo pipefail

GODOT_BIN="${GODOT_BIN:-godot}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PORT="${SNOWDOWN_TEST_PORT:-7011}"
LATENCY="${SNOWDOWN_SIM_LATENCY:-0}"
JITTER="${SNOWDOWN_SIM_JITTER:-0}"
LOSS="${SNOWDOWN_SIM_LOSS:-0}"
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
timeout --kill-after=2s 22s "$GODOT_BIN" --headless --path "$ROOT" -- --server --world=glacier_valley --port="$PORT" --network-smoke-layout=catch_lane >"$SERVER_LOG" 2>&1 &
SERVER_PID=$!
for _ in $(seq 1 40); do
  if grep -q "SNOWDOWN_NETWORK_SERVER_READY" "$SERVER_LOG"; then break; fi
  if ! kill -0 "$SERVER_PID" 2>/dev/null; then cat "$SERVER_LOG"; exit 1; fi
  sleep 0.1
done
if ! grep -q "SNOWDOWN_NETWORK_SERVER_READY" "$SERVER_LOG"; then cat "$SERVER_LOG"; echo "network server did not become ready" >&2; exit 1; fi

SIM_ARGS=(--net-sim-latency-ms="$LATENCY" --net-sim-jitter-ms="$JITTER" --net-sim-loss-percent="$LOSS")
# Start the catcher first so it owns the near team-A fixture slot. The thrower then
# receives the team-B slot placed directly on the mirrored snow source at z=-14.
timeout --kill-after=2s 18s "$GODOT_BIN" --headless --path "$ROOT" -- --connect=127.0.0.1 --port="$PORT" --network-smoke-name=B --network-smoke-expected=2 --network-smoke-action=catch "${SIM_ARGS[@]}" >"$CLIENT_B_LOG" 2>&1 &
CLIENT_B_PID=$!
sleep 0.25
timeout --kill-after=2s 18s "$GODOT_BIN" --headless --path "$ROOT" -- --connect=127.0.0.1 --port="$PORT" --network-smoke-name=A --network-smoke-expected=2 --network-smoke-action=pack_throw "${SIM_ARGS[@]}" >"$CLIENT_A_LOG" 2>&1 &
CLIENT_A_PID=$!

STATUS=0
wait "$CLIENT_A_PID" || STATUS=$?
wait "$CLIENT_B_PID" || STATUS=$?
if [[ "$STATUS" -ne 0 ]]; then
  echo "--- server ---"; cat "$SERVER_LOG"; echo "--- client A ---"; cat "$CLIENT_A_LOG"; echo "--- client B ---"; cat "$CLIENT_B_LOG"; exit "$STATUS"
fi
if [[ $(grep -c "peer joined" "$SERVER_LOG") -lt 2 ]] || \
   ! grep -q "SNOWDOWN_NETWORK_THROW_ACCEPTED" "$SERVER_LOG" || \
   ! grep -q "SNOWDOWN_NETWORK_CATCH_ACCEPTED" "$SERVER_LOG" || \
   ! grep -q "SNOWDOWN_NETWORK_SNOWBALL_OK name=A" "$CLIENT_A_LOG" || \
   ! grep -q "SNOWDOWN_NETWORK_CATCH_OK name=B" "$CLIENT_B_LOG" || \
   ! grep -q "SNOWDOWN_NETWORK_CATCH_OK name=B.*score_a=0 score_b=0" "$CLIENT_B_LOG" || \
   ! grep -q "SNOWDOWN_NETWORK_CLIENT_READY name=A.*roster=2" "$CLIENT_A_LOG" || \
   ! grep -q "SNOWDOWN_NETWORK_CLIENT_READY name=B.*roster=2" "$CLIENT_B_LOG"; then
  echo "--- server ---"; cat "$SERVER_LOG"; echo "--- client A ---"; cat "$CLIENT_A_LOG"; echo "--- client B ---"; cat "$CLIENT_B_LOG"; echo "two-client catch/authority assertions failed" >&2; exit 1
fi

# Normal local conditions must prove prediction -> authority promotion. Under simulated
# latency/loss an authoritative-only fallback is legal when inventory confirmation arrives
# too late to create a cosmetic prediction, but it must still remain a single projectile.
if [[ "$LATENCY" -eq 0 ]] && ! grep -Eq "SNOWDOWN_NETWORK_SNOWBALL_OK name=A.*merges=[1-9][0-9]*" "$CLIENT_A_LOG"; then
  echo "--- client A ---"; cat "$CLIENT_A_LOG"; echo "zero-latency throw did not merge prediction" >&2; exit 1
fi

echo "SNOWDOWN_TWO_CLIENT_NETWORK_OK latency=$LATENCY jitter=$JITTER loss=$LOSS"
echo "SNOWDOWN_AUTHORITATIVE_SNOWBALL_OK"
echo "SNOWDOWN_AUTHORITATIVE_CATCH_OK"
