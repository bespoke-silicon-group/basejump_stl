from random import randrange
import sys

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

  dram = sys.argv[1]
  addr_width_p = {
    'hbm2_8gb_x128' : 30,
    'hbm2_4gb_x128' : 29,
    'gddr5x_8gb_x32' : 33,
  } [dram]

  tg = HBMTraceGen(addr_width_p)
  for i in range(1024):
    # stride is by column
    tg.send(READ, i * 32)
    # stride is by row
    #tg.send(READ, i * 2048)
    # only using 1/4 banks (1 bank group)
    #tg.send(READ, i * 4 * 2048)
    # only using 1/16 banks (1 bank group)
    #tg.send(READ, i * 16 * 2048)
    tg.wait_cycles(500)
    #tg.wait_cycles(0)

  tg.done()
