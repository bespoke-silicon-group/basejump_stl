TOP = ../../..

BSG_TESTME_FILES    = bsg_mul.sv
BSG_TESTME_DIR      = $(TOP)/bsg_misc
BSG_MISC_FILES      =   bsg_cycle_counter.sv bsg_defines.sv bsg_lfsr.sv bsg_and.sv bsg_dff_en.sv bsg_transpose.sv bsg_mul_pipelined.sv bsg_mul/bsg_mul_booth_4_block_rep.sv bsg_mul/bsg_mul_booth_4_block.sv bsg_mul/bsg_mul_comp42_rep.sv bsg_mul/bsg_mul_comp42.sv
BSG_HARD_MISC_MUL_FILES      = bsg_mul_comp42_block_hard.v bsg_mul_booth_4_block_hard.v
BSG_HARD_MISC_MUL_DIR        = $(TOP)/bsg_misc/bsg_mul
BSG_HARD_MISC_FILES =
BSG_HARD_MISC_DIR   = ~/raw/bsg_ip_cores/hard/bsg_misc/
BSG_HARD_IP_DIR = ~/raw/chip/bsg_one_1x1/sources/ip/bsg/mul/

BSG_HARD_IP_FILES = bsg_rp_tsmc_250_comp42_block_hard_b8.v bsg_rp_tsmc_250_comp42_block_hard_b7.v bsg_rp_tsmc_250_comp42_block_hard_b5.v bsg_rp_tsmc_250_comp42_block_hard_b6.v bsg_rp_tsmc_250_booth_4_block_hard_b5.v bsg_rp_tsmc_250_booth_4_block_hard_b6.v bsg_rp_tsmc_250_booth_4_block_hard_b8.v bsg_rp_tsmc_250_and_csa_block_hard_b7.v bsg_rp_tsmc_250_and_csa_block_hard_b6.v bsg_rp_tsmc_250_and_csa_block_hard_b8.v bsg_rp_tsmc_250_booth_4_block_cornice_end_hard_b7.v bsg_rp_tsmc_250_booth_4_block_cornice_end_hard_b8.v bsg_rp_tsmc_250_booth_4_block_cornice_hard_b8.v bsg_rp_tsmc_250_booth_4_block_cornice_hard_b6.v
BSG_HARD_LIB =  -v /gro/cad/mosis/pdk/tsmc/cl025g/std_cells/Rev_2004q2v1/aci/sc/verilog/tsmc25.v


BSG_TEST_FILES =  bsg_nonsynth_reset_gen.sv bsg_nonsynth_clock_gen.sv # bsg_nonsynth_ascii_writer.sv

TEST_MAIN=test_bsg.sv
TEST_MODULE=test_bsg


ALL_FILES =   $(foreach x,$(BSG_MISC_FILES),$(TOP)/bsg_misc/$(x)) $(foreach x,$(BSG_TEST_FILES),$(TOP)/bsg_test/$(x)) $(foreach x,$(BSG_TESTME_FILES),$(BSG_TESTME_DIR)/$(x)) $(TEST_MAIN) $(foreach x,$(BSG_HARD_MISC_MUL_FILES),$(BSG_HARD_MISC_MUL_DIR)/$(x))  $(foreach x,$(BSG_HARD_MISC_FILES),$(BSG_HARD_MISC_DIR)/$(x)) $(foreach x,$(BSG_HARD_IP_FILES),$(BSG_HARD_IP_DIR)/$(x))

modulo_val_p = 1 2 3 4 5 6 7 8 9
#modulo_val_p = 10 11 12 13 14 15 0
signed_p = 0 1
in_width_p = 16 32
pipeline_p = 0 1

#signed_p=1
#scan_params = modulo_val_p signed_p
scan_params = signed_p in_width_p pipeline_p

include ../../Makefile.sim
