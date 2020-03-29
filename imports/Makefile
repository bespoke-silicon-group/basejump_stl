IMPORTS := ramulator DRAMSim3

.PHONY: help $(IMPORTS)

help:
	@echo "usage: make {$(strip $(foreach import, $(IMPORTS), $(import),))}"

DRAMSim3: UPDATE_FLAGS+=--rebase
$(IMPORTS):
	git submodule init && git submodule update $(UPDATE_FLAGS) $@
