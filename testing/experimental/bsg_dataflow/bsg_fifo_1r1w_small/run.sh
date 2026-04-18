#!/bin/bash

#  Flexible Inputs
TOP_FILE="${1:-bsg_fifo_top.sv}"
SIM_MAIN="${2:-sim_main.cpp}"
TOP_NAME=$(basename "${TOP_FILE}" .sv)
PREFIX="Vtop"

#  Path Management (Override via: export BSG_STL_PATH=/path/to/stl)
BSG_STL_PATH="${BSG_STL_PATH:-../../../../}"

INCLUDE_DIRS=(
    "${BSG_STL_PATH}/bsg_misc"
    "${BSG_STL_PATH}/bsg_dataflow"
    "${BSG_STL_PATH}/bsg_mem"
)

#  Cleanup
rm -rf obj_dir waveform.vcd

# Build Verilator Command
V_FLAGS=(
    --sv --timing --trace --coverage --cc
    "${TOP_FILE}"
    --exe "${SIM_MAIN}"
    --prefix "${PREFIX}"
    -Wno-fatal -Wno-GENUNNAMED -Wno-PINCONNECTEMPTY -Wno-DECLFILENAME
    -Wno-UNUSEDSIGNAL -Wno-WIDTHEXPAND -Wno-EOFNEWLINE -Wno-UNUSEDPARAM
)

# Append Include Directories
for dir in "${INCLUDE_DIRS[@]}"; do
    V_FLAGS+=("-I${dir}")
done

#  Execution Steps
echo "---  Verilating ${TOP_NAME} ---"
verilator "${V_FLAGS[@]}" || exit 1

echo "--- Compiling C++ Model ---"
make -j$(nproc) -C obj_dir -f "${PREFIX}.mk" || exit 1

echo "---  Running Simulation ---"
./obj_dir/"${PREFIX}"
