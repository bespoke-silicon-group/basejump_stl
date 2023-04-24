# High Level Makefile
# 
# This makefile runs all other makefiles within one level of
# scope of itself
#
# Brenden Page 11/19/2022

TEST_DIRS = ./axe_test/ ./axi_test/ ./regression_64/ ./regression_v2/ ./wormhole/

all:
	$(foreach x,$(TEST_DIRS), $(MAKE) -C $(x);)

clean:
	$(foreach x,$(TEST_DIRS), $(MAKE) -C $(x) clean;)
