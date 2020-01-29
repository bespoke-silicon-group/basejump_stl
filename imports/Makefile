IMPORTS := ramulator DRAMSim3

.PHONY: $(IMPORTS)

DRAMSim3: UPDATE_FLAGS+=--rebase
$(IMPORTS):
	git submodule init && git submodule update $(UPDATE_FLAGS) $@
