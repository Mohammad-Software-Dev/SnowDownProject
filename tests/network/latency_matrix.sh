#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

run_case() {
  local port="$1" latency="$2" jitter="$3" loss="$4"
  echo "-- latency case: ${latency}ms jitter=${jitter}ms loss=${loss}% --"
  SNOWDOWN_TEST_PORT="$port" SNOWDOWN_SIM_LATENCY="$latency" SNOWDOWN_SIM_JITTER="$jitter" SNOWDOWN_SIM_LOSS="$loss" tests/network/two_client_smoke.sh
}

run_case 7011 0 0 0
run_case 7012 50 10 0
run_case 7013 100 20 2
run_case 7014 150 30 2
run_case 7015 200 40 5

echo "SNOWDOWN_LATENCY_MATRIX_OK"
