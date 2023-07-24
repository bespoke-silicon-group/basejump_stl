# High Level Makefile
# 
# This makefile runs all other makefiles within one level of
# scope of itself
#
# Brenden Page 11/19/2022

TEST_DIRS = $(filter-out %common/,$(wildcard ./*/))

all:
	$(foreach x,$(TEST_DIRS), $(MAKE) -C $(x); if [ -f $(x)/app ]; then ./$(x)/app; fi;)

clean:
	$(foreach x,$(TEST_DIRS), $(MAKE) -C $(x) clean;)
