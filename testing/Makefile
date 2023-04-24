# High Level Makefile
# 
# This makefile runs all other makefiles within one level of
# scope of itself
#
# Brenden Page 11/19/2022

TEST_DIRS = $(filter-out %common/,$(wildcard ./*/))

clean:
	$(foreach x,$(TEST_DIRS), if [ -f $(x)/Makefile ]; then $(MAKE) -C $(x) clean; fi;)
