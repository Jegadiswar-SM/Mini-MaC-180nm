# =============================================================================
# soc_top.sdc — Mini-MaC SoC Timing Constraints
# PDK:    SCL (Semiconductor Complex Limited) 180nm CMOS
# Target: 100 MHz  (10.0 ns period)
# Supply: 1.8 V nominal
# =============================================================================

# -----------------------------------------------------------------------------
# Primary Clock
# -----------------------------------------------------------------------------
set PERIOD 10.0

create_clock -name clk \
             -period $PERIOD \
             [get_ports clk]

# Clock quality: uncertainty = jitter (~200 ps) + skew budget (~300 ps)
set_clock_uncertainty  0.5  [get_clocks clk]
# Max slew at clock pins (SCL 180nm — slower edges than sub-100nm)
set_clock_transition   0.3  [get_clocks clk]
# Insertion delay budget for clock tree (180nm has longer wire delays)
set_clock_latency      1.0  [get_clocks clk]

# -----------------------------------------------------------------------------
# Input / Output Delays  (20% of period each side)
# SCL 180nm: external I/O environment typically 1.5–2.5 ns
# -----------------------------------------------------------------------------
set_input_delay  -clock clk  2.0 [all_inputs]
set_output_delay -clock clk  2.0 [all_outputs]

# Reset pin is asynchronous — exclude from timing analysis
set_false_path -from [get_ports rst_n]

# -----------------------------------------------------------------------------
# Drive strength & Load assumptions
# SCL 180nm standard cell library (sc9mc_cmos18g)
# Adjust cell names to match your SCL library variant
# -----------------------------------------------------------------------------
# set_driving_cell -lib_cell sc9mc_BUFX4    [all_inputs]
# set_load [load_of sc9mc_BUFX4/A]          [all_outputs]

# -----------------------------------------------------------------------------
# Physical Constraints
# SCL 180nm: higher fanout tolerance than nanometer nodes
# -----------------------------------------------------------------------------
set_max_fanout    32 [current_design]
# Max transition time — 180nm drives at slower edge rates
set_max_transition 0.8 [current_design]

# -----------------------------------------------------------------------------
# Multi-Cycle Path — Systolic Array PE Multiplier Pipeline
# The PE accumulator registers have a 2-cycle setup timing budget
# (data arrives in cycle 1, captured in cycle 2 of FEED state).
# At 100 MHz / 180nm, the multiplier can easily close in 1 cycle, but
# the multi-cycle path annotation relaxes synthesis and improves QoR.
# -----------------------------------------------------------------------------
set_multicycle_path 2 -setup \
    -from [get_pins -hierarchical -filter "NAME=~*u_array*pe*mul_reg*"] \
    -to   [get_pins -hierarchical -filter "NAME=~*u_array*pe*mul_reg*"]

set_multicycle_path 1 -hold \
    -from [get_pins -hierarchical -filter "NAME=~*u_array*pe*mul_reg*"] \
    -to   [get_pins -hierarchical -filter "NAME=~*u_array*pe*mul_reg*"]

# -----------------------------------------------------------------------------
# SRAM Black-Box — Do not optimize through the macro
# SCL 180nm SRAM hard macro from SCL memory compiler
# Register the actual macro with: read_physical -lef <sram_macro.lef>
# -----------------------------------------------------------------------------
set_dont_touch [get_cells -hierarchical -filter "REF_NAME==sram_wrapper"]

# -----------------------------------------------------------------------------
# Case Analysis — Functional mode (DFT not yet inserted)
# -----------------------------------------------------------------------------
# set_case_analysis 0 [get_ports scan_en]   ;# uncomment when DFT is added

# =============================================================================
# End of constraints
# =============================================================================
