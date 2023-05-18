# High Level Makefile
# 
# This makefile runs all other makefiles within one level of
# scope of itself
#
# Brenden Page 11/19/2022

TEST_DIRS = $(wildcard ./*/)

all:
	$(foreach x,$(TEST_DIRS), $(MAKE) -C $(x);)

clean:
	$(foreach x,$(TEST_DIRS), $(MAKE) -C $(x) clean;)
