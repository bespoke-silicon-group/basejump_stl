#
#   bsg_cache_trace_gen.py
#

class BsgCacheDmaTraceGen:

  # constructor
  def __init__(self, addr_width_p, data_width_p, block_width_p):
    self.addr_width_p = addr_width_p
    self.data_width_p = data_width_p
    self.block_width_p = block_width_p
    self.words = block_width_p / data_width_p
    self.packet_len = data_width_p

  def send_write(self, addr, data):
    trace = "0001_"
    trace += self.get_bin_str(0, self.packet_len-2-self.addr_width_p)
    trace += self.get_bin_str(1, 1) + "_"
    trace += self.get_bin_str(1, 1) + "_"
    trace += self.get_bin_str(addr, self.addr_width_p)
    print(trace)

    for i in range(self.words):
        mask = ((1 << (self.data_width_p*(i+1))) - 1) << (i*self.data_width_p)
        word = (mask & data) >> (i*self.data_width_p)
        word = word % self.data_width_p
        trace = "0001_"
        trace += self.get_bin_str(word, self.data_width_p)
        print(trace)

  def send_read(self, addr, data):
    trace = "0001_"
    trace += self.get_bin_str(0, self.packet_len-2-self.addr_width_p)
    trace += self.get_bin_str(1, 1) + "_"
    trace += self.get_bin_str(0, 1) + "_"
    trace += self.get_bin_str(addr, self.addr_width_p)
    print(trace)

    for i in range(self.words):
        mask = ((1 << (self.data_width_p*(i+1))) - 1) << (i*self.data_width_p)
        word = (mask & data) >> (i*self.data_width_p)
        word = word % self.data_width_p
        trace = "0010_"
        trace += self.get_bin_str(word, self.data_width_p)
        print(trace)

  # done
  def done(self):
    trace = "0011_"
    trace += self.get_bin_str(0, self.packet_len)
    print(trace)

  def finish(self):
    trace = "0100_"
    trace += self.get_bin_str(0, self.packet_len)
    print(trace)

  # wait
  def wait(self, cycle):
    trace = "0110_"
    trace += self.get_bin_str(cycle, self.packet_len)
    print(trace)
    
    trace = "0101_"
    trace += self.get_bin_str(0, self.packet_len)
    print(trace)

  # nop
  def nop(self):
    trace = "0000_"
    trace += self.get_bin_str(0, self.packet_len)
    print(trace)

  # get binary string (helper)
  def get_bin_str(self, val, width):
    return format(val, "0" + str(width) + "b")


