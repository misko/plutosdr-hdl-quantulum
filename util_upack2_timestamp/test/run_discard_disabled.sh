#!/usr/bin/env bash
set -euo pipefail

test_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
src_dir="${test_dir}/../src"
simulation_output="$(mktemp)"
trap 'rm -f "${simulation_output}"' EXIT

iverilog -g2012 -s discard_disabled_tb -o "${simulation_output}" \
    "${test_dir}/xpm_fifo_async_stub.v" \
    "${src_dir}/binary_to_grey.v" \
    "${src_dir}/grey_to_binary.v" \
    "${src_dir}/cdc_sync_bits.v" \
    "${src_dir}/fifo_reset_sync.v" \
    "${src_dir}/tx_pipeline_debug.v" \
    "${src_dir}/util_upack2_timestamp.v" \
    "${test_dir}/discard_disabled_tb.v"

vvp "${simulation_output}"
