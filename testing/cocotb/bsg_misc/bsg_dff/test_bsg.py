#===============================================================================
# test_bsg.py
#

import random
import cocotb
from bsg_cocotb_lib import bsg_assert
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge,FallingEdge,Timer
from cocotb.result import TestFailure

from bsg_cocotb_lib import bsg_top_params

@cocotb.test()
def test_random (dut):

  p = bsg_top_params()

  num_test_inputs = 1000  ;# The number of random test vectors to try
  clock_period    = 778   ;# The clock period of the clock object

  # Create a clock object
  cocotb.fork(Clock(dut.clk_i, clock_period).start())

  # Start by putting the dff into a known state
  dut.data_i = 0
  yield RisingEdge(dut.clk_i)
  yield Timer(1)
  bsg_assert( int(dut.data_o), 0 )

  # Test several random inputs, making sure that on the negative edge the
  # output has not changed, and after the rising edge it gets updated.
  prev_val = 0
  for i in range(num_test_inputs):
    val = random.randint(0,(2**int(p['width_p']))-1)
    dut.data_i = val

    # Check no change on the negative edge
    yield FallingEdge(dut.clk_i)
    yield Timer(1)
    bsg_assert( int(dut.data_o), prev_val )

    # Check change on the positive edge
    yield RisingEdge(dut.clk_i)
    yield Timer(1)
    bsg_assert( int(dut.data_o), val )

    prev_val = val

