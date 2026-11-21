#===============================================================================
# test_bsg.py
#
# This is a simple test file template. Defines some common imports (not all
# used here) and two test cases, test_pass which should always pass and
# test_fail which should always fail. This file can be used as a starting point
# for real tests as well as a way to make sure that the makefile infrastructure
# is working without worrying about creating a real test script.
#

import random
import cocotb
from cocotb.triggers import Timer
from cocotb.result import TestFailure

# Test Pass -- wait 1 tick and passes
@cocotb.test()
def test_pass (dut):
  yield Timer(1)

# Test Fail -- wait 1 tick and fails
@cocotb.test()
def test_fail (dut):
  yield Timer(1)
  raise TestFailure('test_fail failed, which is correct... so maybe pass?')

