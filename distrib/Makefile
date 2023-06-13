# MBT 12-27-20
# This is an exploration into pickling BaseJump STL
#
# Currently, it is pickles the mesh network
# and bsg_misc, which is required by the mesh network.
#
# Some efforts are made:
#    - to reduce size (EDA Playground has 100K character limit)
#    - create a manifest
#    - remove redundant include files.
#

BSG_MESH_PKG = $(wildcard ../bsg_noc/bsg_mesh*_pkg.v ../bsg_noc/bsg_noc_pkg.sv)
BSG_FILTER = ../bsg_noc/bsg_mesh_to_ring_stitch.sv ../bsg_misc/bsg_mul_pipelined.sv ../bsg_misc/bsg_imul_iterative.sv $(wildcard ../bsg_misc/bsg_idiv_iterative*.v)
BSG_MESH_STANDARD = $(wildcard ../bsg_noc/bsg_mesh*.v)
BSG_MISC_STANDARD = $(wildcard ../bsg_misc/*.v)
BSG_FILES = $(BSG_MESH_PKG) $(filter-out $(BSG_FILTER) $(BSG_MESH_PKG),$(BSG_MESH_STANDARD) $(BSG_MISC_STANDARD))
BSG_FILE_LIST := $(shell echo $(foreach x,$(BSG_FILES),@// $(x)) | sed -e 's/\@/\\n/g')

ROUND_ROBIN_ARB_MAX=6

#
# strip out extra spaces and C++ style comments, and blank lines
# also, filter out redundant includes of bsg_defines
#

SHRINK = | tr -s '[:space:]' | sed -e 's|//.*||g' | sed '/^[[:space:]]*$$/d' | sed 's/ = /=/g' | sed 's/, /,/g' |  sed 's/`include "bsg_defines.sv"//g'

all:
	rm basejump_stl.v; make basejump_stl.v

basejump_stl.v:
	../bsg_misc/bsg_round_robin_arb.py $(ROUND_ROBIN_ARB_MAX) > ../bsg_misc/bsg_round_robin_arb.sv
	echo "/* BEGIN BaseJump STL Manifest" > $@
	echo "git HASH" `git log --pretty=format:'%H' -n 1` >> $@
	wc $(BSG_FILES) >> $@
#	echo "$(BSG_FILE_LIST)" >> $@
	echo " END BaseJump STL Manifest */" >> $@
	echo  '`include "bsg_defines.sv"' >> $@
	cat $(BSG_FILES) $(SHRINK) >> $@
