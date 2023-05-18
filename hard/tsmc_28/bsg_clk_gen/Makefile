
PYTHON ?= python

all:
	$(PYTHON) bsg_rp_clk_gen_osc_unit_v3.py 8 8 8 > bsg_rp_clk_gen_osc_unit_v3.v
	$(PYTHON) bsg_rp_clk_gen_osc_v3.py      8 8 8 > bsg_rp_clk_gen_osc_v3.v

clean:
	rm -f bsg_rp_clk_gen_osc_unit_v3.v
	rm -f bsg_rp_clk_gen_osc_v3.v
