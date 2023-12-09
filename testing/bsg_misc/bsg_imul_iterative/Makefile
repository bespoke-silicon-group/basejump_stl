# # FIXME:  set up VCS, should modified for different users.
# TOP ?= $(shell git rev-parse --show-toplevel)
# BSG_CADENV_DIR ?= $(TOP)/../bsg_cadenv

# include $(BSG_CADENV_DIR)/cadenv.mk

# VCS_OP     +=  +vcs+vcdpluson -debug_access+all

# vcs:
# 	$(VCS) -full64 -sverilog  -Mupdate -f filelist.f $(VCS_OP)
# 	#./simv +vcs+stop+232100
# 	./simv

# xvcs:
# 	$(VCS) -full64 -sverilog -Mupdate -RI -line -f filelist.f

# clean:
# 	$(RM) -r csrc simv.daidir vcs.key simv  ucli.key  vcdplus.vpd
# dve64:
# 	$(VCS_BIN)/dve -full64

# Example parameter scan makefile
# 
# This makefile is a skeleton that simulates a module many times
# trying out variations of a product of different command line parameters.
#
# MBT 5/12/2015
#
# Edited to test bsg_gray_to_binary.sv
# Bandhav Veluri 5/18/2015

TOP = ../../..

##########################################################################
# place the parameters you want to scan here.
BSG_TESTME_FILES    =   bsg_imul_iterative.sv
BSG_TESTME_DIR      =   $(TOP)/bsg_misc
BSG_MISC_FILES      =   bsg_defines.sv
BSG_ASYNC_FILES     = 
BSG_COMM_LINK_FILES =
BSG_DATAFLOW_FILES  = 
BSG_FSB_FILES       =
BSG_GUTS_FILES      =

BSG_TEST_FILES =  bsg_nonsynth_reset_gen.sv \
                  bsg_nonsynth_clock_gen.sv \
                  bsg_nonsynth_ascii_writer.sv

TEST_MODULE = test_bsg
TEST_MAIN   = test_bsg.sv


# this is a list of all variables you want to vary for the simulation
scan_params = DUMMY

# this is a list of all values for each variable in the scan_params list
# note; if you leave out values for a variable, then the product of the
# sets is null, and nothing will run.

DUMMY = 0
############################################################################

include ../../Makefile.sim
