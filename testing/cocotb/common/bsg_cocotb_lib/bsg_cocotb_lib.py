from cocotb.result import TestFailure

def bsg_assert ( actual, expected ):
  if actual != expected:
    raise TestFailure('Assertion failed - expect value: %d, actual value: %d' % (int(expected),  int(actual)))

