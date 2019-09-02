#
#   bsg_cache_trace_gen.py
#
#   @author tommy
#

LB = 0b00000
LH = 0b00001
LW = 0b00010
LD = 0b00011

LBU = 0b00100
LHU = 0b00101
LWU = 0b00110
LDU = 0b00111

SB = 0b01000
SH = 0b01001
SW = 0b01010
SD = 0b01011

LM = 0b01100
SM = 0b01101

TAGST = 0b10000
TAGFL = 0b10001
TAGLV = 0b10010
TAGLA = 0b10011

AFL = 0b11000
AFLINV = 0b11001
AINV = 0b11010

ALOCK = 0b11011
AUNLOCK = 0b11100


class BsgCacheTraceGen:

  # constructor
  def __init__(self, addr_width_p, data_width_p):
    self.addr_width_p = addr_width_p
    self.data_width_p = data_width_p
    self.data_mask_width_lp = (data_width_p>>3)
    self.packet_len = addr_width_p + data_width_p + 5 + self.data_mask_width_lp


  # send packet
  def send(self, opcode, addr, data=0, mask=0):
    trace = "0001_"
    trace += format(opcode, "05b") + "_"
    trace += format(addr, "0" + str(self.addr_width_p) + "b") + "_"
    trace += format(data, "0" + str(self.data_width_p) + "b") + "_"
    trace += format(mask, "0" + str(self.data_mask_width_lp) + "b")
    print(trace)

  
  # recv data
  def recv(self, data):
    trace = "0010_"
    trace += format(0, "0" + str(self.packet_len-self.data_width_p) + "b") + "_"
    trace += format(data, "0" + str(self.data_width_p) + "b")
    print(trace)

  # done
  def done(self):
    trace = "0100_"
    trace += format(0, "0" + str(self.packet_len) + "b")
    print(trace)

  # wait
  def wait(self, cycle):
    trace = "0110_"
    trace += self.get_bin_str(cycle, self.packet_len)
    print(trace)
    
    trace = "0101_"
    trace += self.get_bin_str(0, self.packet_len)
    print(trace)

  # get binary string (helper).
  def get_bin_str(self, val, width):
    return format(val, "0" + str(width) + "b")
