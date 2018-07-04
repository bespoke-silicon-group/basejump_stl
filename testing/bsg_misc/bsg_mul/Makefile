
export LM_LICENSE_FILE = 27000@bbfs-00.calit2.net
export SYNOPSYS_DIR=/gro/cad/synopsys
export VCS_RELEASE=vcs/G-2012.09-SP1
export VCS_HOME = $(SYNOPSYS_DIR)/$(VCS_RELEASE)
export VCS_BIN = $(VCS_HOME)/bin
export DVE_BIN = $(VCS_HOME)/bin
export DC_RELEASE    = syn/G-2012.06-SP5-4

VCS_FLAGS =  $(DESIGNWARE_FLAGS) -PP -notice -full64 +lint=all,noVCDE +v2k -sverilog -timescale=100ps/10ps  +vcs+loopreport +define+BSG_IP_CORES_UNIT_TEST

TOP = ../../..

DESIGNWARE_DIR = $(SYNOPSYS_DIR)/$(DC_RELEASE)/dw/sim_ver
DESIGNWARE_FLAGS = -y $(DESIGNWARE_DIR) +incdir+$(DESIGNWARE_DIR) +incdir+$(TOP)/bsg_test +incdir+$(TOP)/bsg_misc +libext+.v

BSG_TESTME_FILES    = bsg_mul.v
BSG_TESTME_DIR      = $(TOP)/bsg_misc
BSG_MISC_FILES      =   bsg_cycle_counter.v bsg_defines.v bsg_lfsr.v bsg_and.v bsg_dff_en.v bsg_transpose.v
BSG_HARD_MISC_MUL_FILES      = bsg_mul_comp42_block_hard.v bsg_mul_booth_4_block_hard.v
BSG_HARD_MISC_MUL_DIR        = ~/raw/bsg_ip_cores/hard/bsg_misc/bsg_mul
BSG_HARD_MISC_FILES =
BSG_HARD_MISC_DIR   = ~/raw/bsg_ip_cores/hard/bsg_misc/
BSG_HARD_IP_DIR = ~/raw/chip/bsg_one_1x1/sources/ip/bsg/mul/

BSG_HARD_IP_FILES = bsg_rp_tsmc_250_comp42_block_hard_b8.v bsg_rp_tsmc_250_comp42_block_hard_b7.v bsg_rp_tsmc_250_comp42_block_hard_b5.v bsg_rp_tsmc_250_comp42_block_hard_b6.v bsg_rp_tsmc_250_booth_4_block_hard_b5.v bsg_rp_tsmc_250_booth_4_block_hard_b6.v bsg_rp_tsmc_250_booth_4_block_hard_b8.v bsg_rp_tsmc_250_and_csa_block_hard_b7.v bsg_rp_tsmc_250_and_csa_block_hard_b6.v bsg_rp_tsmc_250_and_csa_block_hard_b8.v bsg_rp_tsmc_250_booth_4_block_cornice_end_hard_b7.v bsg_rp_tsmc_250_booth_4_block_cornice_end_hard_b8.v bsg_rp_tsmc_250_booth_4_block_cornice_hard_b8.v bsg_rp_tsmc_250_booth_4_block_cornice_hard_b6.v
BSG_HARD_LIB =  -v /gro/cad/mosis/pdk/tsmc/cl025g/std_cells/Rev_2004q2v1/aci/sc/verilog/tsmc25.v


BSG_TEST_FILES =  bsg_nonsynth_reset_gen.v bsg_nonsynth_clock_gen.v # bsg_nonsynth_ascii_writer.v

TEST_MAIN=test_bsg.v


ALL_FILES =   $(foreach x,$(BSG_MISC_FILES),$(TOP)/bsg_misc/$(x)) $(foreach x,$(BSG_TEST_FILES),$(TOP)/bsg_test/$(x)) $(foreach x,$(BSG_TESTME_FILES),$(BSG_TESTME_DIR)/$(x)) $(TEST_MAIN) $(foreach x,$(BSG_HARD_MISC_MUL_FILES),$(BSG_HARD_MISC_MUL_DIR)/$(x))  $(foreach x,$(BSG_HARD_MISC_FILES),$(BSG_HARD_MISC_DIR)/$(x)) $(foreach x,$(BSG_HARD_IP_FILES),$(BSG_HARD_IP_DIR)/$(x))

modulo_val_p = 1 2 3 4 5 6 7 8 9
#modulo_val_p = 10 11 12 13 14 15 0
signed_p = 0 1
in_width_p = 16 32
pipeline_p = 0 1

#signed_p=1
#scan_params = modulo_val_p signed_p
scan_params = signed_p in_width_p pipeline_p
bsg_param_scan = $(if $(1),$(foreach v__,$($(firstword $(1))),$(call bsg_param_scan,$(filter-out $(firstword $(1)),$(1)),$(2),$(3),$(4)@$(2)$(firstword $(1))$(3)$(v__))),$(4))
commands=$(call bsg_param_scan,$(scan_params),+,=)

$(warning bsg_param_scan: $(commands))

# default rule: run all of the targets.
all: $(foreach x,$(commands),run.$(x))

run.%: ./simv
	./simv  $(subst @, ,$*) | tee $@.log

simv: $(ALL_FILES)
	$(VCS_BIN)/vcs $(VCS_FLAGS) $(filter-out small-clean,$^) $(subst @, ,$*) -o simv  $(BSG_HARD_LIB)

all.log: $(ALL_FILES)
	@echo $*
	- rm -rf simv csrc simv.daidir
	$(VCS_BIN)/vcs $(DESIGNWARE_FLAGS) -PP -notice -full64 +lint=all,noVCDE +v2k -sverilog -timescale=100ps/10ps $(filter-out small-clean,$^) $(subst @, ,$*) +vcs+loopreport +define+BSG_IP_CORES_UNIT_TEST
	./simv # | tee $@

dve:
	$(DVE_BIN)/dve -full64 -vpd vcdplus.vpd &

%.echo:
	echo $($*)

clean:
	-rm run*.log output.log
	- rm -rf simv csrc simv.daidir DVEfiles vcdplus.vpd ucli.key

small-clean:
	- rm -rf simv csrc simv.daidir
