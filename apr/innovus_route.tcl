# =============================================================================
# innovus_route.tcl — Routing  [SCL 180nm]
# =============================================================================
restore_design out/soc_top_cts.enc

# Global + detail routing
route_design

# Post-route optimization
optDesign -postRoute
optDesign -postRoute -hold

# Filler cell insertion
add_fillers \
    -cells [get_lib_cells *FILL*] \
    -prefix FILL

file mkdir out/reports
report_timing -max_paths 10 > out/reports/postRoute_timing.rpt

save_design out/soc_top_routed.enc
puts "=== SCL180 Routing DONE ==="
