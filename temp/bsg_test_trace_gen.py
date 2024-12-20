
class TestTraceGen:
  # constructor
  def __init__(self, payload_width_p=192):
    self.payload_width_p = payload_width_p
    self.data_width_p = payload_width_p+4

  # send packet
  def send(self, data):
    trace = "0001_"
    trace += self.get_bin_str(data, self.payload_width_p)
    print(trace)

  # recv packet
  def recv(self, data):
    trace = "0010_"
    trace += self.get_bin_str(data, self.payload_width_p)
    print(trace)

  # done
  def done(self):
    trace = "0011_"
    trace += self.get_bin_str(0, self.payload_width_p)
    print(trace)

  def finish(self):
    trace = "0100_"
    trace += self.get_bin_str(0, self.payload_width_p)
    print(trace)

  # wait
  def wait(self, cycle):
    trace = "0110_"
    trace += self.get_bin_str(cycle, self.payload_width_p)
    print(trace)

    trace = "0101_"
    trace += self.get_bin_str(0, self.payload_width_p)
    print(trace)

  # nop
  def nop(self):
    trace = "0000_"
    trace += self.get_bin_str(0, self.payload_width_p)
    print(trace)

  # get binary string (helper)
  def get_bin_str(self, val, width):
    return format(val, "0" + str(width) + "b")

