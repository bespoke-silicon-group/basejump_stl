TESTING_COCOTB_COMMON_DIR := $(realpath $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST)))))

COCOTB_BUILD_DIR      := $(TESTING_COCOTB_COMMON_DIR)/cocotb
COCOTB_VENV_BUILD_DIR := $(TESTING_COCOTB_COMMON_DIR)/cocotb_venv

COCOTB_VENV_ACTIVATE := source $(COCOTB_VENV_BUILD_DIR)/bin/activate

build_tools: $(COCOTB_BUILD_DIR) $(COCOTB_VENV_BUILD_DIR)

clean_tools:
	rm -rf $(COCOTB_BUILD_DIR)
	rm -rf $(COCOTB_VENV_BUILD_DIR)

$(COCOTB_BUILD_DIR):
	mkdir -p $(@D)
	git clone https://github.com/cocotb/cocotb.git $@
	cd $@ ; git checkout v1.2.0rc1

$(COCOTB_VENV_BUILD_DIR): $(COCOTB_BUILD_DIR)
	mkdir -p $(@D)
	virtualenv -p /usr/bin/python2.7 $@
	$(COCOTB_VENV_ACTIVATE) ; pip install $^

