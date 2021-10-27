IMPORTS := ramulator DRAMSim3

.PHONY: help $(IMPORTS)

help:
	@echo "usage: make {$(strip $(foreach import, $(IMPORTS), $(import),))}"

DRAMSim3: UPDATE_FLAGS+=--rebase
$(IMPORTS):
	# expanded out to support git < 1.8.4
	cd ..; git submodule init
	cd ..; git submodule update $(UPDATE_FLAGS) imports/$@
