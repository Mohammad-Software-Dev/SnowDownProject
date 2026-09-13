#!/usr/bin/env bash
set -euo pipefail

GODOT_BIN="${GODOT_BIN:-godot}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

echo "== Snowdown: Godot project parse/import =="
"$GODOT_BIN" --headless --editor --path "$ROOT" --quit

echo "== Snowdown: config smoke =="
"$GODOT_BIN" --headless --path "$ROOT" -s tests/smoke/config_smoke.gd

echo "== Snowdown: projectile math =="
"$GODOT_BIN" --headless --path "$ROOT" -s tests/unit/snowball_math_test.gd

echo "== Snowdown: catch validation =="
"$GODOT_BIN" --headless --path "$ROOT" -s tests/unit/catch_validation_test.gd

echo "== Snowdown: Map 01 layout =="
"$GODOT_BIN" --headless --path "$ROOT" -s tests/unit/map01_layout_test.gd

echo "== Snowdown: boot TestArena =="
"$GODOT_BIN" --headless --path "$ROOT" --quit-after 3 -- --scenario=test_arena_origin

echo "== Snowdown: boot Glacier Valley =="
"$GODOT_BIN" --headless --path "$ROOT" --quit-after 3 -- --scenario=map01_center_arch

echo "SNOWDOWN_HEADLESS_VERIFICATION_OK"
