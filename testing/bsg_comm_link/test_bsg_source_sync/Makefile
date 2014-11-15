export LM_LICENSE_FILE = 27000@bbfs-00.calit2.net
export SYNOPSYS_DIR=/gro/cad/synopsys
export VCS_RELEASE=vcs/G-2012.09-SP1
export VCS_HOME = $(SYNOPSYS_DIR)/$(VCS_RELEASE)
export VCS_BIN = $(VCS_HOME)/bin
export DVE_BIN = $(VCS_HOME)/bin


TOP = ../../..
ASYNC_FILES = bsg_async_credit_counter.v bsg_async_fifo.v bsg_async_ptr_gray.v bsg_launch_sync_sync.v bsg_sync_sync.v
SOURCE_SYNC_FILES = bsg_source_sync_input.v bsg_source_sync_output.v
TEST_FILES = test_bsg_source_sync.v
MISC_FILES = bsg_gray_to_binary.v  bsg_wait_after_reset.v  bsg_cycle_counter.v


all:  $(foreach x,$(ASYNC_FILES),$(TOP)/bsg_async/$(x)) $(foreach x,$(SOURCE_SYNC_FILES),$(TOP)/bsg_comm_link/$(x)) $(foreach x,$(MISC_FILES),$(TOP)/bsg_misc/$(x)) $(TEST_FILES)
	$(VCS_BIN)/vcs -PP -full64 +lint=all +v2k -sverilog -timescale=1ns/10ps $^

run:
	./simv

dve:
	$(DVE_BIN)/dve -full64 -vpd vcdplus.vpd &

%.echo:
	echo $($*)

clean:
	rm -rf simv csrc simv.daidir
