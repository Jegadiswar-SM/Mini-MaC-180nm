# =============================================================================
# genus.tcl — Genus RTL-to-Gates Synthesis
# Design:  Mini-MaC SoC (soc_top)
# PDK:     SCL (Semiconductor Complex Limited) 180nm CMOS
# Target:  100 MHz (10.0 ns)
# Supply:  1.8 V nominal
# =============================================================================
#
# Usage: genus -files genus.tcl  (or: make synth)
#
# PDK path variables — edit these to match your SCL installation:
#   SCL 180nm library is typically located at:
#   /cadence/pdk/scl180/ or as provided by SCL/CDAC
#   Standard cell lib: sc9mc_cmos18g (9-track, multi-corner)
# =============================================================================

# -----------------------------------------------------------------------
# 0. Paths — EDIT to match your SCL 180nm PDK installation
# -----------------------------------------------------------------------
set PDK_ROOT  "/path/to/scl180"
set LIB_DIR   "$PDK_ROOT/lib"
set LEF_DIR   "$PDK_ROOT/lef"
set RTL_DIR   "../rtl"

# SCL 180nm Liberty files — typical corner (tt = typical-typical)
#   TT : 1.80 V, 25°C  → used for synthesis/mapping
#   FF : 1.98 V, -40°C → used for hold analysis (Tempus)
#   SS : 1.62 V, 125°C → used for setup analysis (Tempus)
set LIB_TT  "$LIB_DIR/sc9mc_cmos18g_tt_1v80_25C.lib"
set LIB_FF  "$LIB_DIR/sc9mc_cmos18g_ff_1v98_m40C.lib"
set LIB_SS  "$LIB_DIR/sc9mc_cmos18g_ss_1v62_125C.lib"

# SCL 180nm LEF files
set TECH_LEF "$LEF_DIR/scl18_tech.lef"
set CELL_LEF "$LEF_DIR/sc9mc_cmos18g.lef"

# -----------------------------------------------------------------------
# 1. Tool Setup
# -----------------------------------------------------------------------
set_db / .init_lib_search_path  $LIB_DIR
set_db / .init_hdl_search_path  $RTL_DIR

# Synthesis effort: medium for initial runs, high for tapeout
set_db / .syn_generic_effort    medium
set_db / .syn_map_effort        medium
set_db / .syn_opt_effort        medium

# Enable multi-threading (adjust to available CPU cores)
set_db / .max_cpus_per_server   4

# -----------------------------------------------------------------------
# 2. Read Libraries
# -----------------------------------------------------------------------
# Map using TT corner; FF/SS corners are used in Tempus STA
read_libs $LIB_TT

# SCL 180nm SRAM macro Liberty — from SCL memory compiler (placeholder)
# The behavioral sram_wrapper body is hidden behind `ifndef SYNTHESIS,
# so Genus will naturally black-box it. When you have the real SRAM macro:
# read_libs $LIB_DIR/scl180_sram_2048x32_tt.lib

# Physical LEF for P&R awareness during synthesis
read_physical -lef [list $TECH_LEF $CELL_LEF]
# read_physical -lef $LEF_DIR/scl180_sram_2048x32.lef

# -----------------------------------------------------------------------
# 3. Read RTL
# -----------------------------------------------------------------------

# --- Ibex SystemVerilog (package must compile first) ---
read_hdl -sv $RTL_DIR/core/ibex/rtl/ibex_pkg.sv

foreach ibex_file {
    ibex_pmp
    ibex_alu
    ibex_branch_predict
    ibex_compressed_decoder
    ibex_csr
    ibex_counter
    ibex_cs_registers
    ibex_decoder
    ibex_dummy_instr
    ibex_ex_block
    ibex_fetch_fifo
    ibex_id_stage
    ibex_if_stage
    ibex_load_store_unit
    ibex_multdiv_slow
    ibex_multdiv_fast
    ibex_prefetch_buffer
    ibex_register_file_ff
    ibex_wb_stage
    ibex_core
    ibex_top
} {
    read_hdl -sv $RTL_DIR/core/ibex/rtl/${ibex_file}.sv
}

# --- Project Verilog RTL ---
# SYNTHESIS define:
#   1. In mac_top.v: selects `ifdef SYNTHESIS branch → straight port mapping
#      (no Verilator column-shift workaround)
#   2. In sram_wrapper.v: `ifndef SYNTHESIS guard hides behavioral reg array
#      → Genus black-boxes the module (correct SRAM treatment)
read_hdl -define SYNTHESIS [list \
    $RTL_DIR/macros/sram_wrapper.v           \
    $RTL_DIR/bus/apb_bus.v                   \
    $RTL_DIR/bus/obi_to_apb.v               \
    $RTL_DIR/accel/pe.v                      \
    $RTL_DIR/accel/systolic_array.v          \
    $RTL_DIR/accel/mac_cfg_regs.v            \
    $RTL_DIR/accel/axi_stream_dma.v          \
    $RTL_DIR/accel/mac_core_axi.v            \
    $RTL_DIR/accel/mac_multicore.v          \
    $RTL_DIR/core/boot_rom.v                \
    $RTL_DIR/core/dma_regs.v               \
    $RTL_DIR/core/dma_master.v             \
    $RTL_DIR/core/mem_subsystem.v          \
    $RTL_DIR/core/telemetry.v              \
    $RTL_DIR/soc_top.v                     \
]

# -----------------------------------------------------------------------
# 4. Elaborate
# -----------------------------------------------------------------------
elaborate soc_top

check_design -unresolved

# -----------------------------------------------------------------------
# 5. Constraints
# -----------------------------------------------------------------------
read_sdc ../constraints/soc_top.sdc

# -----------------------------------------------------------------------
# 6. Synthesis
# -----------------------------------------------------------------------
syn_generic
syn_map
syn_opt

# -----------------------------------------------------------------------
# 7. Output Netlist & SDC
# -----------------------------------------------------------------------
file mkdir out
write_hdl  > out/soc_top_netlist.v
write_sdc  > out/soc_top_syn.sdc

# Generic (pre-mapping) netlist for LEC golden reference
write_hdl -generic > out/soc_top_generic.v

# -----------------------------------------------------------------------
# 8. Reports
# -----------------------------------------------------------------------
file mkdir out/reports

# Setup timing — worst 20 paths
report_timing -max_paths 20 -path_type full \
    > out/reports/timing_setup.rpt

# Area (hierarchical breakdown)
report_area -hier \
    > out/reports/area.rpt

# Power estimate (pre-layout)
report_power -hier \
    > out/reports/power.rpt

# Gate count
report_gates \
    > out/reports/gates.rpt

# Constraint violations
report_constraint -all_violators \
    > out/reports/violations.rpt

# QoR summary
report_qor \
    > out/reports/qor.rpt

puts "============================================"
puts "  SCL180 Genus Synthesis COMPLETE"
puts "  Netlist: out/soc_top_netlist.v"
puts "  Reports: out/reports/"
puts "============================================"
