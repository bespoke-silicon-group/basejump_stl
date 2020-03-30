import random
import math

TAGST=0b010000
LW=0b000010
SW=0b001010

class TraceGen:

  def __init__(self, num_subcache_p, block_size_in_words_p):
    # we are keeping 32KB capacity per cache group.
    self.addr_width_p = 30
    self.data_width_p = 32
    self.ways_p = 8
    self.sets_p = 1024/block_size_in_words_p/num_subcache_p
    self.num_subcache_p = num_subcache_p
    self.block_size_in_words_p = block_size_in_words_p
    self.curr_data = 1

  def send_packet(self, opcode, addr, data=0):
    trace = "0001_"
    trace += self.get_bin_str(opcode, 6) + "_"
    trace += self.get_bin_str(addr, self.addr_width_p) + "_"
    trace += self.get_bin_str(data, self.data_width_p) + "_"
    trace += "1111"
    print(trace)
    

  def send_read(self, addr):
    self.send_packet(LW,addr)

  def send_write(self, addr):
    self.send_packet(SW,addr,self.curr_data)
    self.curr_data += 1
  
  def send_tagst(self, addr):
    self.send_packet(TAGST,addr)

  def clear_tags(self):
    for i in range(self.ways_p*self.sets_p*self.num_subcache_p):
      self.send_tagst(i<<(2+int(math.log(self.block_size_in_words_p,2))))

  def done(self):
    trace = "0011_"
    trace += self.get_bin_str(0, self.addr_width_p+6+self.data_width_p+4)
    print(trace)
  
  def get_bin_str(self, val, width):
    return format(val, "0" + str(width) + "b")
