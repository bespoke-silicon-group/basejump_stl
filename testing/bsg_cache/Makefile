# High Level Makefile
# 
# This makefile runs all other makefiles within one level of
# scope of itself
#
# Brenden Page 11/19/2022

TEST_DIRS = ./axe_test/ ./axi_test/ ./regression_64/ ./regression_v2/

# Directed tests built on ../Makefile.sim. They do not need bsg_cadenv.
TEST_DIRS += ./tagst_dirty/ ./tagst_during_miss/ ./tagst_interlock/
TEST_DIRS += ./tagst_track_clear/ ./word_tracking_dirty/

# Uncached requests through bsg_cache_dma_to_wormhole. Also on ../Makefile.sim.
TEST_DIRS += ./uncached/ ./uncached_random/

all:
	$(foreach x,$(TEST_DIRS), $(MAKE) -C $(x);)

clean:
	$(foreach x,$(TEST_DIRS), $(MAKE) -C $(x) clean;)
