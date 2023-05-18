.PHONY: all view clean

export CUR_DIR := $(shell pwd)
export BASEJUMP_STL_DIR := $(CUR_DIR)/../../..

TOP_MODULE := top

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
	$(VCS) $(VCS_OPTS) -CFLAGS "$(CFLAGS)"
view:
	$(DVE) -full64 -vpd dump.vpd

flist.vcs: flist.template
	cat $^ | envsubst > $@

clean:
	rm -rf simv.daidir/ simv csrc/ flist.vcs vc_hdrs.h
