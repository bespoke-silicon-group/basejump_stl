from random import randrange
import sys
import argparse

WRITE = 1
READ  = 0

class HBMTraceGen:

  def __init__(self, addr_width_p):
    self.addr_width_p = addr_width_p


  def send(self, write_not_read, addr):
    trace = "0001_"
    trace += self.get_bin_str(write_not_read, 1) + "_"
    trace += self.get_bin_str(addr, self.addr_width_p)
    print(trace)

  def wait(self):
    trace = "0000_"
    trace += self.get_bin_str(0, 1) + "_"
    trace += self.get_bin_str(0, self.addr_width_p)
    print(trace)

  def wait_cycles(self, cycles):
    for _ in range(cycles): self.wait()

  def done(self):
    trace = "0011_"
    trace += self.get_bin_str(0, 1) + "_"
    trace += self.get_bin_str(0, self.addr_width_p)
    print(trace)

  def get_bin_str(self, val, width):
    return format(val, "0" + str(width) + "b")


if __name__ == "__main__":

  addr_widths = {
    'hbm2_8gb_x128' : 30,
    'hbm2_4gb_x128' : 29,
    'gddr5x_8gb_x32' : 33,
  }

  parser = argparse.ArgumentParser()
  parser.add_argument('dram')

  parser.add_argument('--stride', default='col')
  strides = {
    'col'  : 32,
    'row'  : 2048,
    'bank' : 4 * 2048,
    'bg'   : 16 * 2048,
  }

  parser.add_argument('--start', type=int, default=0)
  parser.add_argument('--n_strides', type=int, default=1024)

  args = parser.parse_args()

  addr_width_p = addr_widths[args.dram]
  stride = strides[args.stride]
  start = args.start
  n_strides = args.n_strides

  tg = HBMTraceGen(addr_width_p)
  for i in range(n_strides):
    # stride is by column
    tg.send(READ, start + i * stride)
    tg.wait_cycles(500)

  tg.done()
