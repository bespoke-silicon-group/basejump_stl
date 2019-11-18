import os
import re

import cocotb

from cocotb.result import TestFailure
from cocotb.triggers import NextTimeStep, ReadOnly

"""
For vcs, you can get params from the py obj (ie. dut.<param>); however, for
verilator if you set the parameter at compile time using -G or -pvalue then it
seems like the parameter cannot be grabbed from the py obj. So we use env vars
and create a simple dict for toplevel params.
"""
def bsg_top_params ():
  result = {}
  params = os.environ['COCOTB_PARAM_LIST']
  for param in [p for p in params.split(' ') if p != '']:
    match = re.search(r'(\w+)\s*=\s*(\w+)', param)
    if match:
      result[match.group(1)] = match.group(2)
  return result

"""
Simple assert equal statement.
"""
def bsg_assert ( actual, expected ):
  if actual != expected:
    raise TestFailure('Assertion failed - expect value: %d, actual value: %d' % (int(expected),  int(actual)))

"""
Simple single assert coroutine.
"""
@cocotb.coroutine
def bsg_assert_sig ( signal, expected ):
    yield NextTimeStep()
    yield NextTimeStep()
    yield ReadOnly()
    if int(signal.value) != expected:
        raise TestFailure('Assertion failed - expect value: %d, actual value: %d' % (int(expected), int(signal.value)))
