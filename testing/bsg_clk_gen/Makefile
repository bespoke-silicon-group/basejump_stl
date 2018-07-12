
export LM_LICENSE_FILE = 27000@bbfs-00.calit2.net
export SYNOPSYS_DIR=/gro/cad/synopsys
export ICC_RELEASE=icc/K-2015.06-SP5-2
export VCS_RELEASE=vcs/K-2015.09-SP2-2
export VCS_HOME = $(SYNOPSYS_DIR)/$(VCS_RELEASE)
export VCS_BIN = $(VCS_HOME)/bin
export DVE_BIN = $(VCS_HOME)/bin
export DC_RELEASE    = syn/G-2012.06-SP5-4

# Example parameter scan makefile
#
# This makefile is a skeleton that simulates a module many times
# trying out variations of a product of different command line parameters.
#
# MBT 5/12/2015
#
# Edited to test bsg_counter_clock_downsample.v
# Scott Davidson (stdavids@eng.ucsd.edu) 8/21/2016

HARDEN = 1

TOP = ../..

########################### SIMULATION PARAMETERS ###########################
# place the parameters you want to scan here.
BSG_DEFINES_FILES   = $(TOP)/bsg_misc/bsg_defines.v
BSG_TESTME_FILES    = bsg_clk_gen.v
BSG_TESTME_DIR      = $(TOP)/bsg_clk_gen
BSG_MISC_FILES      = bsg_counter_clock_downsample.v bsg_counter_clear_up.v bsg_strobe.v
BSG_MISC_HARD_FILES = bsg_dff.v bsg_dff_en.v bsg_dff_reset_en.v  bsg_nand.v bsg_reduce.v bsg_nor3.v bsg_xnor.v bsg_buf.v bsg_mux.v
BSG_ASYNC_FILES     = bsg_launch_sync_sync.v
BSG_TAG_FILES       = bsg_tag_pkg.v bsg_tag_client.v bsg_tag_master.v
BSG_COMM_LINK_FILES =
BSG_DATAFLOW_FILES  =
BSG_FSB_FILES       =
BSG_GUTS_FILES      =
BSG_CONFIG_NET_FILES= config_node.v rNandMeta.v
BSG_TEST_FILES      = bsg_nonsynth_clock_gen.v

BSG_CLK_GEN_FILES   = bsg_clk_gen_osc.v bsg_rp_clk_gen_fine_delay_tuner.v  bsg_rp_clk_gen_adg.v
BSG_CLK_GEN_GENERATED_FILES =  ./bsg_rp_clk_gen_coarse_delay_element_8_6_4_2.v ./bsg_rp_clk_gen_coarse_delay_element_6_4_2_0.v ./bsg_rp_tsmc_250_MX2X1.v ./bsg_rp_tsmc_250_DFFNRX4.v ./bsg_rp_tsmc_250_dff_s2_b7.v bsg_rp_tsmc_250_dff_s4_b8.v bsg_rp_tsmc_250_dff_en_s1_b6.v bsg_rp_tsmc_250_dff_en_s1_b9.v bsg_rp_tsmc_250_dff_nreset_en_s2_b9.v  bsg_rp_tsmc_250_dff_nreset_en_s2_b7.v  bsg_rp_tsmc_250_dff_nreset_en_s2_b6.v bsg_rp_tsmc_250_AND2X1.v bsg_rp_tsmc_250_NAND2X1.v bsg_rp_tsmc_250_XOR2X1.v  bsg_rp_tsmc_250_reduce.v bsg_rp_tsmc_250_NOR3X1.v  bsg_rp_tsmc_250_XNOR2X1.v  bsg_muxi2_gatestack.v bsg_rp_tsmc_250_EDFF.v  bsg_rp_tsmc_250_BUFX8.v  bsg_rp_tsmc_250_MXI2X1.v bsg_rp_tsmc_250_MXI4X1.v  bsg_rp_tsmc_250_MXI4X4.v bsg_rp_tsmc_250_CLKINVX16.v
ifeq ($(HARDEN),0)
BSG_CLK_GEN_DIR     = $(TOP)/bsg_clk_gen/
BSG_HARD_LIB        =
else
BSG_CLK_GEN_DIR     = $(TOP)/hard/bsg_clk_gen
BSG_CLK_GEN_GENERATED_DIR = $(TOP)/testing/bsg_clk_gen/generated
BSG_HARD_LIB        = -v /gro/cad/mosis/pdk/tsmc/cl025g/std_cells/Rev_2004q2v1/aci/sc/verilog/tsmc25.v
endif

TEST_MAIN   = test_bsg.v bsg_nonsynth_clk_gen_tester.v
TEST_MODULE = test_bsg

# this is a list of all variables you want to vary for the simulation
scan_params = WIDTH_P NUM_ADGS_P

# this is a list of all values for each variable in the scan_params list
# note; if you leave out values for a variable, then the product of the
# sets is null, and nothing will run.
WIDTH_P    = 1 2 3 4 8
NUM_ADGS_P = 1 2 4
############################################################################


############################# SIMULATOR COMMANDS ###########################

#VCS_FLAGS  = -PP -notice -full64 +lint=all,noVCDE,noNS +v2k -sverilog -timescale=100ps/10ps  +vcs+loopreport +notimingchecks
VCS_FLAGS  = -PP -notice -full64 +lint=all,noVCDE,noNS +v2k -sverilog -timescale=1ns/1ps  +vcs+loopreport +notimingchecks
VCS_FLAGS += +incdir+$(TOP)/bsg_tag +incdir+$(TOP)/bsg_clk_gen

############################################################################


ALL_FILES =   $(BSG_DEFINES_FILES) $(foreach x,$(BSG_TAG_FILES),$(TOP)/bsg_tag/$(x)) \
              $(foreach x,$(BSG_TESTME_FILES),$(BSG_TESTME_DIR)/$(x)) \
              $(foreach x,$(BSG_MISC_FILES),$(TOP)/bsg_misc/$(x)) \
              $(foreach x,$(BSG_MISC_HARD_FILES),$(TOP)/hard/bsg_misc/$(x)) \
              $(foreach x,$(BSG_CLK_GEN_GENERATED_FILES),$(BSG_CLK_GEN_GENERATED_DIR)/$(x)) \
              $(foreach x,$(BSG_ASYNC_FILES),$(TOP)/bsg_async/$(x)) \
              $(foreach x,$(BSG_COMM_LINK_FILES),$(TOP)/bsg_comm_link/$(x)) \
              $(foreach x,$(BSG_DATAFLOW_FILES),$(TOP)/bsg_dataflow/$(x)) \
              $(foreach x,$(BSG_FSB_FILES),$(TOP)/bsg_fsb/$(x)) \
              $(foreach x,$(BSG_GUTS_FILES),$(TOP)/bsg_guts/$(x)) \
              $(foreach x,$(BSG_TEST_FILES),$(TOP)/bsg_test/$(x)) \
              $(foreach x,$(BSG_CLK_GEN_FILES),$(BSG_CLK_GEN_DIR)/$(x)) \
              $(TEST_MAIN)

# function that generates a string for each combination of the parameters;
# spaces separated by "@" signs.
bsg_param_scan = $(if $(1),$(foreach v__,$($(firstword $(1))),\
                    $(call bsg_param_scan,$(filter-out $(firstword $(1)),\
                    $(1)),$(2),$(3),$(4)@$(2)$(firstword $(1))$(3)$(v__))),\
                    $(4))


# this takes the parameters and creates a set of make targets, one for every
# combination of the parameters
commands = $(call bsg_param_scan,$(scan_params),+define+,=)

$(warning bsg_param_scan: $(commands))

# default rule: run all of the targets.
all: gen_verilog $(foreach x,$(commands),run.$(x))

gen_verilog:
	mkdir -p generated
	sed -e s/\<0\>/8/g -e s/\<1\>/6/g -e s/\<2\>/4/g -e s/\<3\>/2/g $(TOP)/hard/bsg_clk_gen/bsg_rp_clk_gen_coarse_delay_element.v > generated/bsg_rp_clk_gen_coarse_delay_element_8_6_4_2.v
	sed -e s/\<0\>/6/g -e s/\<1\>/4/g -e s/\<2\>/2/g -e s/\<3\>/0/g $(TOP)/hard/bsg_clk_gen/bsg_rp_clk_gen_coarse_delay_element.v > generated/bsg_rp_clk_gen_coarse_delay_element_6_4_2_0.v
	$(TOP)/hard/bsg_misc/bsg_dff_gen.py dff 7 1    > generated/bsg_rp_tsmc_250_dff_s1_b7.v
	$(TOP)/hard/bsg_misc/bsg_dff_gen.py dff 7 2    >  generated/bsg_rp_tsmc_250_dff_s2_b7.v
	$(TOP)/hard/bsg_misc/bsg_dff_gen.py dffe  9 1   >  generated/bsg_rp_tsmc_250_dff_en_s1_b9.v
	$(TOP)/hard/bsg_misc/bsg_dff_gen.py dffe  6 1   >  generated/bsg_rp_tsmc_250_dff_en_s1_b6.v
	$(TOP)/hard/bsg_misc/bsg_dff_gen.py dffre  9 1   >  generated/bsg_rp_tsmc_250_dff_nreset_en_s2_b9.v
	$(TOP)/hard/bsg_misc/bsg_dff_gen.py dffre  6 1   >  generated/bsg_rp_tsmc_250_dff_nreset_en_s2_b6.v
	$(TOP)/hard/bsg_misc/bsg_dff_gen.py dff  8 4    >  generated/bsg_rp_tsmc_250_dff_s4_b8.v
	$(TOP)/hard/bsg_misc/bsg_dff_gen.py dffre 6 2  >  generated/bsg_rp_tsmc_250_dff_nreset_en_s2_b6.v
	$(TOP)/hard/bsg_misc/bsg_dff_gen.py dffre 9 2  >  generated/bsg_rp_tsmc_250_dff_nreset_en_s2_b9.v
	$(TOP)/hard/bsg_misc/bsg_dff_gen.py dffre 7 2  >  generated/bsg_rp_tsmc_250_dff_nreset_en_s2_b7.v
	$(TOP)/hard/bsg_misc/bsg_gate_stack_gen.py MX2X1      32 "#0 (.A (#1), .B(#2), .S0(#3), .Y(#4));" >  generated/bsg_rp_tsmc_250_MX2X1.v
	$(TOP)/hard/bsg_misc/bsg_gate_stack_gen.py MXI2X1      32 "#0 (.A (#1), .B(#2), .S0(#3), .Y(#4));" >  generated/bsg_rp_tsmc_250_MXI2X1.v
	$(TOP)/hard/bsg_misc/bsg_gate_stack_gen.py DFFNRX4 32 "#0 (.D (#1), .CKN(#2), .RN(#3), .Q(#4), .QN());" >  generated/bsg_rp_tsmc_250_DFFNRX4.v
	$(TOP)/hard/bsg_misc/bsg_gate_stack_gen.py AND2X1     32 "#0 (.A (#1), .B(#2), .Y(#3));"            >  generated/bsg_rp_tsmc_250_AND2X1.v
	$(TOP)/hard/bsg_misc/bsg_gate_stack_gen.py NAND2X1    32 "#0 (.A (#1), .B(#2), .Y(#3));"            >  generated/bsg_rp_tsmc_250_NAND2X1.v
	$(TOP)/hard/bsg_misc/bsg_gate_stack_gen.py XOR2X1     32 "#0 (.A (#1), .B(#2), .Y(#3));"            >  generated/bsg_rp_tsmc_250_XOR2X1.v
	$(TOP)/hard/bsg_misc/bsg_gate_stack_gen.py XNOR2X1     32 "#0 (.A (#1), .B(#2), .Y(#3));"            >  generated/bsg_rp_tsmc_250_XNOR2X1.v
	$(TOP)/hard/bsg_misc/bsg_gate_stack_gen.py NOR3X1     32 "#0 (.A (#1), .B(#2), .C(#3), .Y(#4));"            > generated/bsg_rp_tsmc_250_NOR3X1.v
	$(TOP)/hard/bsg_misc/bsg_gate_stack_gen.py MXI4X1 32 "#0 (.A (#1), .B(#2), .C(#3), .D(#4), .S0(#5), .S1(#6), .Y(#7));" >  generated/bsg_rp_tsmc_250_MXI4X1.v
	$(TOP)/hard/bsg_misc/bsg_gate_stack_gen.py MXI4X4 32 "#0 (.A (#1), .B(#2), .C(#3), .D(#4), .S0(#5), .S1(#6), .Y(#7));" >  generated/bsg_rp_tsmc_250_MXI4X4.v
	$(TOP)/hard/bsg_misc/bsg_gate_stack_gen.py MXI2X1 32 "#0 (.A (#1), .B(#2), .S0(#3), .Y(#4));" muxi2_gatestack >  generated/bsg_muxi2_gatestack.v
	$(TOP)/hard/bsg_misc/bsg_reduce_gen.py > generated/bsg_rp_tsmc_250_reduce.v
	$(TOP)/hard/bsg_misc/bsg_gate_stack_gen.py EDFFX1     40   "#0 (.D (#1), .E(#2), .CK(#3), .Q(#4), .QN());" > generated/bsg_rp_tsmc_250_EDFF.v
	$(TOP)/hard/bsg_misc/bsg_gate_stack_gen.py EDFFX2     40   "#0 (.D (#1), .E(#2), .CK(#3), .Q(#4), .QN());" >>  generated/bsg_rp_tsmc_250_EDFF.v
	$(TOP)/hard/bsg_misc/bsg_gate_stack_gen.py EDFFX4     40   "#0 (.D (#1), .E(#2), .CK(#3), .Q(#4), .QN());" >>  generated/bsg_rp_tsmc_250_EDFF.v
	$(TOP)/hard/bsg_misc/bsg_gate_stack_gen.py BUFX8      32 "#0 (.A (#1), .Y(#2));" >  generated/bsg_rp_tsmc_250_BUFX8.v
	$(TOP)/hard/bsg_misc/bsg_gate_stack_gen.py CLKINVX8   32 "#0 (.A (#1), .Y(#2));" >  generated/bsg_rp_tsmc_250_CLKINVX8.v
	$(TOP)/hard/bsg_misc/bsg_gate_stack_gen.py CLKINVX16   32 "#0 (.A (#1), .Y(#2));" >  generated/bsg_rp_tsmc_250_CLKINVX16.v

# this runs an individual target
# we replace the @ with a space so that the parameters are used as
# command line options

run.%: $(ALL_FILES)  gen_verilog
	-rm -rf simv csrc simv.daidir
	$(VCS_BIN)/vcs $(VCS_FLAGS) $(filter-out small-clean,$(ALL_FILES)) $(subst @, ,$*) -o simv $(BSG_HARD_LIB)
	./simv $(subst @, ,$*) | tee $@.log

dve:
	$(DVE_BIN)/dve -full64 -vpd vcdplus.vpd &
%.echo:
	@echo $($*)

clean:
	- rm -rf simv csrc simv.daidir DVEfiles vcdplus.vpd ucli.key simv.log run.*.log generated
