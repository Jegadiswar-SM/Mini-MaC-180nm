# =============================================================================
# innovus_cts.tcl — Clock Tree Synthesis  [SCL 180nm]
# =============================================================================
restore_design out/soc_top_placed.enc

# CCOpt-based clock tree synthesis
# SCL 180nm: lower frequency target allows relaxed skew budget
create_clock_tree_spec \
    -output out/clock_tree.ctstch \
    -exceptions {                   \
        -no_boundary_cell           \
    }

set_ccopt_property buffer_cells   [get_lib_cells *BUF*]
set_ccopt_property inverter_cells [get_lib_cells *INV*]
set_ccopt_property target_skew    0.3   ;# 300 ps — 180nm achievable

ccopt_design

# Post-CTS optimization
optDesign -postCTS
optDesign -postCTS -hold

file mkdir out/reports
report_timing       -max_paths 10    > out/reports/postCTS_timing.rpt
report_clock_timing -type summary    > out/reports/clock_summary.rpt

save_design out/soc_top_cts.enc
puts "=== SCL180 CTS DONE ==="
