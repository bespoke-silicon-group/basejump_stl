
# Workspace directory
dir = ../../../../..

export BSG_CADENV_DIR = $(dir)/bsg_cadenv
export BASEJUMP_STL_DIR = $(dir)/basejump_stl

# Environment
include $(BSG_CADENV_DIR)/cadenv.mk

HISTO = | grep -E "[0-9]  CYCLE" | awk -v size=1 'BEGIN{bmin=10000000}{ b=int($$8/size); a[b]++; bmax=b>bmax?b:bmax; bmin=b<bmin?b:bmin } END { for(i=bmin;i<=bmax;++i) print i*size,(i+1)*size,a[i] }'
#HISTO=

run:
	$(VCS_BIN)/vcs -full64 -sverilog -timescale=1ps/1ps -assert svaext -f ./filelist -debug_pp -R -top bsg_router_crossbar_o_by_i_tester +vcs+vcdpluson $(HISTO)

view:
	$(VCS_BIN)/dve -full64 -vpd vcdplus.vpd &

junk = csrc DVEfiles simv.daidir *.old *.vpd simv *.key vc_hdrs.h

clean:
	rm -rf $(junk)

