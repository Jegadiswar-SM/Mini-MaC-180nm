# SCL 180nm CMOS PDK — Technology Files Guide

## Overview

This directory contains pointers to the SCL (Semiconductor Complex Limited)
180nm CMOS PDK files required for the Cadence Genus / Innovus / Tempus flow.

**SCL** (also known as CEDT/CDAC-Mohali) is India's government semiconductor
foundry at Chandigarh. The 180nm CMOS process is available to academic and
research institutions via the SMDP-C2SD programme.

## Required Files

### Liberty (Timing)

| Corner | Voltage | Temp | Filename |
|--------|---------|------|----------|
| TT (typical-typical) | 1.80 V | 25°C  | `sc9mc_cmos18g_tt_1v80_25C.lib` |
| FF (fast-fast)       | 1.98 V | -40°C | `sc9mc_cmos18g_ff_1v98_m40C.lib` |
| SS (slow-slow)       | 1.62 V | 125°C | `sc9mc_cmos18g_ss_1v62_125C.lib` |

The `sc9mc_cmos18g` prefix refers to the 9-track multi-corner standard cell
library for SCL's 180nm generic CMOS process.

### LEF (Physical Abstract)

| File | Purpose |
|------|---------|
| `scl18_tech.lef` | Metal stack, via rules, DRC design rules |
| `sc9mc_cmos18g.lef` | Standard cell physical abstracts |

### GDS (for Stream-Out)

| File | Purpose |
|------|---------|
| `sc9mc_cmos18g.gds` | Full-chip GDS merge at signoff |

### SRAM Macro

SCL 180nm includes an SRAM memory compiler. Request from SCL:
- Liberty timing model: `scl180_sram_2048x32_tt.lib`
- LEF physical abstract: `scl180_sram_2048x32.lef`
- GDS: `scl180_sram_2048x32.gds`

Once obtained, uncomment the `read_libs` and `read_physical -lef` lines
in `syn/genus.tcl` and `apr/innovus_init.tcl`.

## Script Configuration

In `syn/genus.tcl`, `apr/innovus_init.tcl`, and `sta/tempus.tcl`, set:
```tcl
set PDK_ROOT "/path/to/scl180"
```

All other paths are derived from `PDK_ROOT`.

## Key Parameters (SCL 180nm CMOS)

| Parameter | Value |
|-----------|-------|
| Technology node | 180nm CMOS |
| Supply voltage | 1.8 V nominal (1.62–1.98 V range) |
| Clock target | 100 MHz (10.0 ns period) |
| Metal layers | M1–M6 (standard BEOL) |
| Minimum gate length | 180 nm |
| Standard cell height | 9-track (sc9mc) |
| SRAM compiler | Available via SCL |

## SCL Programme Contact

- **Website**: https://www.csclms.com/
- **SMDP-C2SD**: http://smdp-c2sd.in/
- **CDAC Mohali**: For academic PDK access requests
