#!/usr/bin/env bash
set -euo pipefail

test_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
src_dir=$(cd "${test_dir}/../src" && pwd)
output=$(mktemp "${TMPDIR:-/tmp}/timestamp-check-pipeline.XXXXXX")
trap 'rm -f "${output}"' EXIT

iverilog -g2012 -s timestamp_check_pipeline_tb -o "${output}" \
  "${test_dir}/xpm_fifo_async_stub.v" \
  "${src_dir}/binary_to_grey.v" \
  "${src_dir}/grey_to_binary.v" \
  "${src_dir}/cdc_sync_bits.v" \
  "${src_dir}/fifo_reset_sync.v" \
  "${src_dir}/tx_pipeline_debug.v" \
  "${src_dir}/util_upack2_timestamp.v" \
  "${test_dir}/timestamp_check_pipeline_tb.v"

vvp "${output}"
