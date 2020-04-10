class TraceGenBase:

  # config: HBM2_8Gb_x128
  # addr mapping: ro_ra_bg_ba_ch_co
  RO_POS = 15
  BG_POS = 13
  BA_POS = 11
  CO_POS = 5


  # default constructor
  def __init__(self):
    self.addr_width_p = 30
    self.data_width_p = 32 # data width is 256, but only write 32-bit of column to save space.
    self.curr_data = 1

  # send read
  def send_read(self, addr):
    trace = "0001_0_"
    trace += self.get_bin_str(addr, self.addr_width_p)
    trace += "_"
    trace += self.get_bin_str(0, self.data_width_p)
    print(trace)
  
  # send write
  def send_write(self, addr):
    trace = "0001_1_"
    trace += self.get_bin_str(addr, self.addr_width_p)
    trace += "_"
    trace += self.get_bin_str(self.curr_data, self.data_width_p)
    self.curr_data += 1
    print(trace)

  # send done
  def done(self):
    trace = "0011_0_"
    trace += self.get_bin_str(0, self.addr_width_p)
    trace += "_"
    trace += self.get_bin_str(0, self.data_width_p)
    print(trace)
  
  # get bin string
  def get_bin_str(self, val, width):
    return format(val, "0" + str(width) + "b")

  # get ch addr
  def get_ch_addr(self, ro, bg, ba, co):
    return (ro << self.RO_POS) + (bg << self.BG_POS) + (ba << self.BA_POS) + (co << self.CO_POS)
