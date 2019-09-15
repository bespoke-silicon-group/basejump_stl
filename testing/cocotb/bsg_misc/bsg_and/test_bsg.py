#===============================================================================
# test_bsg.py
#

import cocotb
from cocotb.triggers import Timer
from cocotb.result import TestFailure
import random

def model_and (a, b):
  return (a & b)

@cocotb.test()
def test_all_inputs (dut):
  for a in range(2**int(dut.width_p)):
    for b in range(2**int(dut.width_p)):
      dut.a_i = a
      dut.b_i = b

      yield Timer(1)

      if int(dut.o) != model_and(a,b):
        raise TestFailure("%d - expected %d" % (int(dut.o), model_and(a,b)))

