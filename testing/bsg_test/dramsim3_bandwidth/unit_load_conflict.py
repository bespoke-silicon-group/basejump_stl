from trace_gen_base import TraceGenBase

class UnitLoadConflict(TraceGenBase):

  def generate(self):
    # load 1MB
    for ro in range(2**9):
      for co in range(2**6):
        ch_addr = self.get_ch_addr(ro, 0, 0, co)
        self.send_read(ch_addr)
  
    self.done()



# main()
if __name__ == "__main__":
  tg = UnitLoadConflict()
  tg.generate()
