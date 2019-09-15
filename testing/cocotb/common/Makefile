THIS_DIR := $(realpath $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST)))))

COCOTB_BUILD_DIR     := $(THIS_DIR)/cocotb
VIRTUALENV_BUILD_DIR := $(THIS_DIR)/cocotb_venv

build_tools: $(COCOTB_BUILD_DIR) $(VIRTUALENV_BUILD_DIR)

clean_tools:
	rm -rf $(COCOTB_BUILD_DIR)
	rm -rf $(VIRTUALENV_BUILD_DIR)

$(COCOTB_BUILD_DIR):
	mkdir -p $(@D)
	git clone https://github.com/cocotb/cocotb.git $@
	cd $@ ; git checkout v1.2.0rc1

$(VIRTUALENV_BUILD_DIR): $(COCOTB_BUILD_DIR)
	mkdir -p $(@D)
	virtualenv -p /usr/bin/python2.7 $@
	source $@/bin/activate ; pip install $^

