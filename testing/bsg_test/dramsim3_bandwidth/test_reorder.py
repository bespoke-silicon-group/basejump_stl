from trace_gen_base import TraceGenBase

class TestReorder(TraceGenBase):

  def generate(self):
    self.send_read(self.get_ch_addr(0,0,0,0))
    self.send_read(self.get_ch_addr(1,0,0,0))
    self.send_read(self.get_ch_addr(1,0,0,1))
    self.send_read(self.get_ch_addr(0,0,0,1))
  
    self.done()



# main()
if __name__ == "__main__":
  tg = TestReorder()
  tg.generate()
