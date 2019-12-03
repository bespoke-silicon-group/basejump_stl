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


  def get_bin_str(self, val, width):
    return format(val, "0" + str(width) + "b")


if __name__ == "__main__":
  addr_width_p = 29
  
  tg = HBMTraceGen(addr_width_p)
  #tg.send(WRITE, 0)
  #tg.send(WRITE, 64)
  for i in range(16):
    tg.send(READ, 64*i)
