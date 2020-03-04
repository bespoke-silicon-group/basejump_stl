import random
import math


class TraceGen:

  def __init__(self, block_size_in_words_p):
    # we are keeping 32KB capacity per cache.
    self.addr_width_p = 29
    self.data_width_p = 32
    self.ways_p = 8
    self.sets_p = 1024/block_size_in_words_p
    self.block_size_in_words_p = block_size_in_words_p
    self.curr_data = 1

  def send_read(self, addr):
    trace = "0001_"
    trace += "00_"
    trace += self.get_bin_str(addr, self.addr_width_p) + "_"
    trace += self.get_bin_str(0, self.data_width_p) 
    print(trace)

  def send_write(self, addr):
    trace = "0001_"
    trace += "01_"
    trace += self.get_bin_str(addr, self.addr_width_p) + "_"
    trace += self.get_bin_str(self.curr_data, self.data_width_p) 
    self.curr_data += 1
    print(trace)
  
  def send_tagst(self, addr):
    trace = "0001_"
    trace += "10_"
    trace += self.get_bin_str(addr, self.addr_width_p) + "_"
    trace += self.get_bin_str(0, self.data_width_p) 
    print(trace)

  def clear_tags(self):
    for i in range(self.ways_p*self.sets_p):
      self.send_tagst(i<<(2+int(math.log(self.block_size_in_words_p,2))))
    

  def done(self):
    trace = "0011_"
    trace += self.get_bin_str(0, self.addr_width_p+2+self.data_width_p)
    print(trace)
  
  def get_bin_str(self, val, width):
    return format(val, "0" + str(width) + "b")
