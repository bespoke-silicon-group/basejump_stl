#
#   bsg_tag_trace_gen.py
#
#
#   example usage:
#   tg = TagTraceGen(num_masters_p=2, num_clients_p=4, max_payload_width_p=6)
#   tg.send(masters=0b10,client_id=0b01,data_not_reset=0b0,length=3,data=0b111)
#   tg.send(masters=0b01,client_id=0b00,data_not_reset=0b1,length=6,data=0b111000)
#   tg.wait(31)
#   tg.done()
#
#   output:
#   0001_10_01_0_011_000111
#   0001_01_00_1_110_111000
#   0110_00000000011111
#   0101_00000000000000
#   0011_00_00_0_000_000000


import math

SEND_OP       = 0b0001
DONE_OP       = 0b0011
COUNT_INIT_OP = 0b0110
COUNT_WAIT_OP = 0b0101

class TagTraceGen:

  # Constructor
  def __init__(self, num_masters_p, num_clients_p, max_payload_width_p):
    self.num_masters_p = num_masters_p
    self.num_clients_p = num_clients_p
    self.max_payload_width_p = max_payload_width_p
    self.client_id_width_lp = self.safe_clog2(num_clients_p)
    self.length_width_lp = self.safe_clog2(max_payload_width_p+1)

  # BSG_SAFE_CLOG2(x)
  def safe_clog2(self, x):
    if x == 1:
      return 1
    else:
      return int(math.ceil(math.log(x,2)))
  
  # Get binary string
  def get_bin_str(self, val, width):
    return format(val, "0" + str(width) + "b")

  # Print trace.
  def get_trace(self, opcode, masters, client_id, data_not_reset, length, data):
    trace = self.get_bin_str(opcode, 4) + "_"
    trace += self.get_bin_str(masters, self.num_masters_p) + "_"
    trace += self.get_bin_str(client_id, self.client_id_width_lp) + "_"
    trace += self.get_bin_str(data_not_reset, 1) + "_"
    trace += self.get_bin_str(length, self.length_width_lp) + "_"
    trace += self.get_bin_str(data, self.max_payload_width_p)
    return trace

  # Send trace
  def send(self, masters, client_id, data_not_reset, length, data):
    print(self.get_trace(SEND_OP, masters, client_id, data_not_reset, length, data))

  # Wait cycles.
  def wait(self, cycles):
    count_width = self.num_masters_p + self.client_id_width_lp + 1 + self.length_width_lp + self.max_payload_width_p
    trace = self.get_bin_str(COUNT_INIT_OP, 4) + "_" 
    trace += self.get_bin_str(cycles, count_width)
    print(trace)
    trace = self.get_bin_str(COUNT_WAIT_OP, 4) + "_"
    trace += self.get_bin_str(0, count_width)
    print(trace)

  # done
  def done(self):
    trace = self.get_trace(DONE_OP, 0,0,0,0,0)
    print(trace)
