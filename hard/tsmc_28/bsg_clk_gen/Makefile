
PYTHON ?= python

all:
	$(PYTHON) bsg_rp_clk_gen_osc_unit_v3.py 8 8 8 > bsg_rp_clk_gen_osc_unit_v3.sv
	$(PYTHON) bsg_rp_clk_gen_osc_v3.py      8 8 8 > bsg_rp_clk_gen_osc_v3.sv

clean:
	rm -f bsg_rp_clk_gen_osc_unit_v3.sv
	rm -f bsg_rp_clk_gen_osc_v3.sv
