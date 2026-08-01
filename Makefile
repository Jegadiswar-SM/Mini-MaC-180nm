# =============================================================================
# Cadence SCL 180nm Flow — Mini-MaC SoC
# =============================================================================
#
# Directory layout:
#   cadence_scl180/
#   ├── constraints/soc_top.sdc   (100 MHz / 10.0 ns)
#   ├── syn/                      Genus synthesis
#   ├── apr/                      Innovus P&R
#   └── sta/                      Tempus STA
#
# All RTL is referenced relative to this directory: ../../rtl/
# PDK:  SCL (Semiconductor Complex Limited) 180nm CMOS
# Tool: Genus / Innovus / Tempus (Cadence suite)
# =============================================================================

.PHONY: all sim synth apr sta clean

# Ordered full-flow
all: synth apr sta

sim:
	cd ../../dv/xcelium && $(MAKE) sim

synth:
	cd syn && $(MAKE) synth

apr:
	cd apr && $(MAKE) all

sta:
	cd sta && $(MAKE) sta

clean:
	cd syn && $(MAKE) clean
	cd apr && $(MAKE) clean
	cd sta && $(MAKE) clean
