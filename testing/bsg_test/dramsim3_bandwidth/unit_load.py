from trace_gen_base import TraceGenBase

class UnitLoad(TraceGenBase):

  def generate(self):
    # load 1MB
    for ro in range(2**5):
      for co in range(2**6):
        for ba in range(2**2):
          for bg in range(2**2):
            ch_addr = self.get_ch_addr(ro, bg, ba, co)
            self.send_read(ch_addr)
  
    self.done()



# main()
if __name__ == "__main__":
  tg = UnitLoad()
  tg.generate()
