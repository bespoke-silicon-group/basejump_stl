from trace_gen_base import TraceGenBase
import random

class RandomFull(TraceGenBase):

  def generate(self):
    for i in range(2**15):
      bg = random.randint(0,3)
      ba = random.randint(0,3)
      ro = random.randint(0,(2**15)-1)
      co = random.randint(0,63)
      write_not_read = random.randint(0,1)
      ch_addr = self.get_ch_addr(ro, bg, ba, co)
      if write_not_read == 1:
        self.send_write(ch_addr)
      else:
        self.send_read(ch_addr)
  
    self.done()



# main()
if __name__ == "__main__":
  tg = RandomFull()
  tg.generate()
