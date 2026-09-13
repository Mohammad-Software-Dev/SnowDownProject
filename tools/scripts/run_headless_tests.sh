#!/usr/bin/env bash
set -euo pipefail

GODOT_BIN="${GODOT_BIN:-godot}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

run_godot() {
  timeout --kill-after=2s 30s "$GODOT_BIN" "$@"
}

echo "== Snowdown: Godot project parse/import =="
run_godot --headless --editor --path "$ROOT" --quit

echo "== Snowdown: config smoke =="
run_godot --headless --path "$ROOT" -s tests/smoke/config_smoke.gd

echo "== Snowdown: projectile math =="
run_godot --headless --path "$ROOT" -s tests/unit/snowball_math_test.gd

echo "== Snowdown: catch validation =="
run_godot --headless --path "$ROOT" -s tests/unit/catch_validation_test.gd

echo "== Snowdown: Match flow =="
run_godot --headless --path "$ROOT" -s tests/unit/match_flow_test.gd

echo "== Snowdown: network telemetry =="
run_godot --headless --path "$ROOT" -s tests/unit/network_telemetry_test.gd

echo "== Snowdown: snowball presentation =="
run_godot --headless --path "$ROOT" -s tests/unit/snowball_presentation_test.gd

echo "== Snowdown: first-person arms poses =="
run_godot --headless --path "$ROOT" -s tests/unit/first_person_arms_pose_test.gd

echo "== Snowdown: third-person poses =="
run_godot --headless --path "$ROOT" -s tests/unit/third_person_pose_test.gd

echo "== Snowdown: winter character palette =="
run_godot --headless --path "$ROOT" -s tests/unit/winter_character_palette_test.gd

echo "== Snowdown: controller input =="
run_godot --headless --path "$ROOT" -s tests/unit/controller_input_test.gd

echo "== Snowdown: session addressing =="
run_godot --headless --path "$ROOT" -s tests/unit/session_address_test.gd

echo "== Snowdown: session recovery =="
run_godot --headless --path "$ROOT" -s tests/unit/session_recovery_test.gd

echo "== Snowdown: session UI =="
run_godot --headless --path "$ROOT" -s tests/smoke/session_ui_smoke.gd

echo "== Snowdown: Map 01 layout =="
run_godot --headless --path "$ROOT" -s tests/unit/map01_layout_test.gd

echo "== Snowdown: Glacier Valley visual spec =="
run_godot --headless --path "$ROOT" -s tests/unit/glacier_valley_visual_spec_test.gd

echo "== Snowdown: boot TestArena =="
timeout --kill-after=2s 10s "$GODOT_BIN" --headless --path "$ROOT" --quit-after 3 -- --scenario=test_arena_origin

echo "== Snowdown: boot Glacier Valley =="
timeout --kill-after=2s 10s "$GODOT_BIN" --headless --path "$ROOT" --quit-after 3 -- --scenario=map01_center_arch

echo "== Snowdown: authoritative catch latency matrix =="
timeout --kill-after=3s 120s tests/network/latency_matrix.sh

echo "== Snowdown: server-owned match loop =="
timeout --kill-after=3s 20s bash tests/network/match_loop_smoke.sh

echo "== Snowdown: real 4v4 scale smoke =="
timeout --kill-after=3s 25s bash tests/network/eight_client_scale_smoke.sh

echo "SNOWDOWN_HEADLESS_VERIFICATION_OK"
