from trace_gen_base import TraceGenBase

class Unit(TraceGenBase):

  def generate(self):
    # load 512KB
    for ro in range(2**4):
      for co in range(2**6):
        for ba in range(2**2):
          for bg in range(2**2):
            ch_addr = self.get_ch_addr(ro, bg, ba, co)
            self.send_read(ch_addr)

    # store 512KB
    for ro in range(2**4):
      for co in range(2**6):
        for ba in range(2**2):
          for bg in range(2**2):
            ch_addr = self.get_ch_addr(ro, bg, ba, co)
            self.send_write(ch_addr)
  
    self.done()



# main()
if __name__ == "__main__":
  tg = Unit()
  tg.generate()
