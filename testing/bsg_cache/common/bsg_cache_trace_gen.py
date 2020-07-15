#
#   bsg_cache_trace_gen.py
#
#   @author tommy
#

LB = 0b000000
LH = 0b000001
LW = 0b000010
LD = 0b000011

LBU = 0b000100
LHU = 0b000101
LWU = 0b000110
LDU = 0b000111

SB = 0b001000
SH = 0b001001
SW = 0b001010
SD = 0b001011

LM = 0b001100
SM = 0b001101

TAGST = 0b010000
TAGFL = 0b010001
TAGLV = 0b010010
TAGLA = 0b010011

AFL = 0b011000
AFLINV = 0b011001
AINV = 0b011010

ALOCK = 0b011011
AUNLOCK = 0b011100

AMOSWAP_W = 0b100000
AMOADD_W = 0b100001
AMOXOR_W = 0b100010
AMOAND_W = 0b100011
AMOOR_W = 0b100100
AMOMIN_W = 0b100101
AMOMAX_W = 0b100110
AMOMINU_W = 0b100111
AMOMAXU_W = 0b101000

AMOSWAP_D = 0b110000
AMOADD_D = 0b110001
AMOXOR_D = 0b110010
AMOAND_D = 0b110011
AMOOR_D = 0b110100
AMOMIN_D = 0b110101
AMOMAX_D = 0b110110
AMOMINU_D = 0b110111
AMOMAXU_D = 0b111000

class BsgCacheTraceGen:

  # constructor
  def __init__(self, addr_width_p, data_width_p):
    self.addr_width_p = addr_width_p
    self.data_width_p = data_width_p
    self.data_mask_width_lp = (data_width_p>>3)
    self.packet_len = addr_width_p + data_width_p + 6 + self.data_mask_width_lp


  # send packet
  def send(self, opcode, addr, data=0, mask=0):
    trace = "0001_"
    trace += self.get_bin_str(opcode, 6) + "_"
    trace += self.get_bin_str(addr, self.addr_width_p) + "_"
    trace += self.get_bin_str(data, self.data_width_p) + "_"
    trace += self.get_bin_str(mask, self.data_mask_width_lp)
    print(trace)

  
  # recv data
  def recv(self, data):
    trace = "0010_"
    trace += self.get_bin_str(0, self.packet_len-self.data_width_p)
    trace += self.get_bin_str(data, self.data_width_p)
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


