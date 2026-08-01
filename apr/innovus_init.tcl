# =============================================================================
# innovus_init.tcl — Innovus Init & Floorplan  [SCL 180nm]
# Design: Mini-MaC SoC  |  100 MHz  |  SCL 180nm CMOS
# =============================================================================
#
# Assumes Genus netlist is at: ../syn/out/soc_top_netlist.v
# Run from: cadence_scl180/apr/
# =============================================================================

# -----------------------------------------------------------------------
# 0. PDK Paths — EDIT to match your SCL 180nm installation
# -----------------------------------------------------------------------
set PDK_ROOT  "/path/to/scl180"
set LIB_DIR   "$PDK_ROOT/lib"
set LEF_DIR   "$PDK_ROOT/lef"
set GDS_DIR   "$PDK_ROOT/gds"

# Liberty corners (SCL 180nm — sc9mc_cmos18g multi-corner)
set LIB_TT  "$LIB_DIR/sc9mc_cmos18g_tt_1v80_25C.lib"
set LIB_FF  "$LIB_DIR/sc9mc_cmos18g_ff_1v98_m40C.lib"
set LIB_SS  "$LIB_DIR/sc9mc_cmos18g_ss_1v62_125C.lib"

# -----------------------------------------------------------------------
# 1. MMMC (Multi-Mode Multi-Corner) View Definition
# -----------------------------------------------------------------------
create_library_set -name libs_tt -timing $LIB_TT
create_library_set -name libs_ff -timing $LIB_FF
create_library_set -name libs_ss -timing $LIB_SS

create_constraint_mode -name func \
    -sdc_files ../constraints/soc_top.sdc

create_delay_corner -name tt_corner -library_set libs_tt
create_delay_corner -name ff_corner -library_set libs_ff
create_delay_corner -name ss_corner -library_set libs_ss

create_analysis_view -name setup_view \
    -constraint_mode func \
    -delay_corner ss_corner   ;# worst-case setup (SS: slow-slow, 125C)

create_analysis_view -name hold_view \
    -constraint_mode func \
    -delay_corner ff_corner   ;# worst-case hold  (FF: fast-fast, -40C)

set_analysis_view -setup {setup_view} -hold {hold_view}

# -----------------------------------------------------------------------
# 2. Initialize Design
# -----------------------------------------------------------------------
set init_design_netlisttype  Verilog
set init_verilog             ../syn/out/soc_top_netlist.v
set init_top_cell            soc_top

set init_lef_file [list \
    $LEF_DIR/scl18_tech.lef       \
    $LEF_DIR/sc9mc_cmos18g.lef    \
]
# Uncomment when SRAM hard macro LEF is available from SCL memory compiler:
# lappend init_lef_file $LEF_DIR/scl180_sram_2048x32.lef

init_design

# -----------------------------------------------------------------------
# 3. Floorplan
# SCL 180nm — larger die than nanometer nodes
# Target 65% core utilization, 1:1 aspect ratio
# -----------------------------------------------------------------------
create_floorplan \
    -site   core          \
    -utilization  65      \
    -aspectRatio   1.0    \
    -coreSpacingBottom 30 \
    -coreSpacingTop    30 \
    -coreSpacingLeft   30 \
    -coreSpacingRight  30

fit_io

# -----------------------------------------------------------------------
# 4. Power Planning
# SCL 180nm: 1.8V supply
# Use M3 horizontal + M4 vertical for power routing (180nm has M1-M6)
# -----------------------------------------------------------------------
add_rings \
    -nets        {VDD VSS} \
    -type        core_rings \
    -follow      core \
    -layer       {top M5 bottom M5 left M4 right M4} \
    -width        4.0 \
    -spacing      2.0 \
    -offset       5.0

add_stripes \
    -nets        {VDD VSS} \
    -layer        M4 \
    -direction    vertical \
    -width        2.0 \
    -spacing      2.0 \
    -set_to_set_distance 20.0

route_special -connect {core_pin} -nets {VDD VSS}

# -----------------------------------------------------------------------
# 5. Save
# -----------------------------------------------------------------------
file mkdir out
save_design out/soc_top_init.enc

puts "=== SCL180 Floorplan DONE — out/soc_top_init.enc ==="
