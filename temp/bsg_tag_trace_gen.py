#
#   bsg_tag_trace_gen.py
#

import math

NOP_OP        = 0b0000
SEND_OP       = 0b0001
RECV_OP       = 0b0010
DONE_OP       = 0b0011
FINISH_OP     = 0b0100
COUNT_WAIT_OP = 0b0101
COUNT_INIT_OP = 0b0110

class TagTraceGen:

  # Constructor
  def __init__(self, num_masters_p=2, num_clients_p=1024, max_payload_width_p=12):
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
    print(f"// SEND {client_id} {data_not_reset} {data}")
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

