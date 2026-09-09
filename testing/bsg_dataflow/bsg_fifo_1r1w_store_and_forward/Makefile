.PHONY: all wave cov clean

export CUR_DIR := $(shell pwd)
export SRC_DIR :=
export BASEJUMP_STL_DIR :=

TOP_MODULE := wrapper

VCS ?= vcs
DVE ?= dve

VCS_OPTS := -full64
VCS_OPTS += -f flist.vcs
VCS_OPTS += -sverilog
VCS_OPTS += +lint=all +lint=noVCDE +lint=noNS
VCS_OPTS += -top $(TOP_MODULE)
VCS_OPTS += +incdir+$(BASEJUMP_STL_DIR)/bsg_misc
VCS_OPTS += +incdir+$(BASEJUMP_STL_DIR)/bsg_tag
VCS_OPTS += -assert svaext
VCS_OPTS += -debug_all


all: flist.vcs
	$(VCS) $(VCS_OPTS)
wave:
	$(DVE) -full64 -vpd dump.vpd
cov:
	$(DVE) -full64 -cov -covdir simv.vdb
flist.vcs: flist.template
	cat $^ | envsubst > $@

clean:
	rm -rf simv.daidir/ simv csrc/ flist.vcs ucli.key vc_hdrs.h
