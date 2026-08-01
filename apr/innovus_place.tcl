# =============================================================================
# innovus_place.tcl — Placement  [SCL 180nm]
# =============================================================================
restore_design out/soc_top_init.enc

# Standard cell placement
place_design

# Pre-CTS timing optimization
optDesign -preCTS
optDesign -preCTS -hold

file mkdir out/reports
report_timing -max_paths 10 > out/reports/preCTS_timing.rpt

save_design out/soc_top_placed.enc
puts "=== SCL180 Placement DONE ==="
