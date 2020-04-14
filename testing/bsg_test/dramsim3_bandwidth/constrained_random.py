from trace_gen_base import TraceGenBase
import random

class ConstrainedRandom(TraceGenBase):

  def generate(self):

    addrs = []

    # 32KB range
    for bg in range(4):
      for ba in range(4):
        for ro in range(2):
          for co in range(32):
            addr = self.get_ch_addr(ro,bg,ba,co)
            addrs.append(addr)

    random.shuffle(addrs)

    # total 1MB
    for i in range(32):
      for addr in addrs:
        write_not_read = random.randint(0,1)
        if write_not_read == 1:
          self.send_write(addr)
        else:
          self.send_read(addr)
    
  
    self.done()



# main()
if __name__ == "__main__":
  tg = ConstrainedRandom()
  tg.generate()
