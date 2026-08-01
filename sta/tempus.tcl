# =============================================================================
# tempus.tcl — Static Timing Analysis  [SCL 180nm]
# Design:  Mini-MaC SoC  |  100 MHz  |  SCL 180nm CMOS
# Corners: TT (typical), SS (worst-case setup), FF (worst-case hold)
# =============================================================================
#
# Usage: tempus -files tempus.tcl  (or: make sta)
# Inputs: post-route netlist + SPEF from Innovus
# =============================================================================

# -----------------------------------------------------------------------
# 0. Paths — EDIT to match your SCL 180nm installation
# -----------------------------------------------------------------------
set PDK_ROOT "/path/to/scl180"
set LIB_DIR  "$PDK_ROOT/lib"

set LIB_TT  "$LIB_DIR/sc9mc_cmos18g_tt_1v80_25C.lib"
set LIB_FF  "$LIB_DIR/sc9mc_cmos18g_ff_1v98_m40C.lib"
set LIB_SS  "$LIB_DIR/sc9mc_cmos18g_ss_1v62_125C.lib"

# -----------------------------------------------------------------------
# 1. MMMC Setup — 3 corners
# -----------------------------------------------------------------------
create_library_set -name libs_tt -timing $LIB_TT
create_library_set -name libs_ff -timing $LIB_FF
create_library_set -name libs_ss -timing $LIB_SS

create_constraint_mode -name func \
    -sdc_files ../constraints/soc_top.sdc

# Delay corners
create_delay_corner -name tt_corner -library_set libs_tt
create_delay_corner -name ff_corner -library_set libs_ff
create_delay_corner -name ss_corner -library_set libs_ss

# Analysis views
# SS: slow-slow, 1.62V, 125°C — worst case for setup (cells are slow)
# FF: fast-fast, 1.98V, -40°C — worst case for hold  (cells are fast → min delay is small)
create_analysis_view -name setup_ss  \
    -constraint_mode func -delay_corner ss_corner
create_analysis_view -name hold_ff   \
    -constraint_mode func -delay_corner ff_corner
create_analysis_view -name typ_tt    \
    -constraint_mode func -delay_corner tt_corner

set_analysis_view -setup {setup_ss} -hold {hold_ff}

# -----------------------------------------------------------------------
# 2. Read Post-Route Netlist
# -----------------------------------------------------------------------
read_netlist ../apr/out/soc_top_postroute.v -top soc_top

# -----------------------------------------------------------------------
# 3. Read SPEF (parasitic RC from Innovus extractRC)
# -----------------------------------------------------------------------
read_spef -corner tt_corner ../apr/out/soc_top.spef
read_spef -corner ff_corner ../apr/out/soc_top.spef
read_spef -corner ss_corner ../apr/out/soc_top.spef

# -----------------------------------------------------------------------
# 4. Run Timing
# -----------------------------------------------------------------------
set_interactive_constraint_modes [all_constraint_modes -active]
update_timing

# -----------------------------------------------------------------------
# 5. Reports
# -----------------------------------------------------------------------
file mkdir out

# Setup timing — worst 50 paths, slow-slow corner
report_timing \
    -path_type      full_clock_expanded \
    -max_paths      50 \
    -setup          \
    -view           setup_ss \
    > out/setup_timing_ss.rpt

# Hold timing — worst 50 paths, fast-fast corner
report_timing \
    -path_type      full_clock_expanded \
    -max_paths      50 \
    -hold           \
    -view           hold_ff \
    > out/hold_timing_ff.rpt

# Typical summary
report_timing \
    -path_type      summary \
    -max_paths      20 \
    -view           typ_tt \
    > out/timing_tt_summary.rpt

# Clock timing
report_clock_timing -type summary -view setup_ss > out/clk_summary_ss.rpt
report_clock_timing -type summary -view hold_ff  > out/clk_summary_ff.rpt

# All constraint violators
report_constraint -all_violators -view setup_ss  > out/violations_ss.rpt
report_constraint -all_violators -view hold_ff   > out/violations_ff.rpt

# Power (100 MHz switching activity)
report_power \
    -view typ_tt \
    > out/power_tt.rpt

puts "============================================"
puts "  SCL180 Tempus STA COMPLETE"
puts "  Setup: out/setup_timing_ss.rpt"
puts "  Hold:  out/hold_timing_ff.rpt"
puts "  Check: out/violations_ss.rpt"
puts "============================================"
