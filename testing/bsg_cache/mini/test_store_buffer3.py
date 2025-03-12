import sys
import random
from test_base import *

class TestStoreBuffer3(TestBase):

  def get_random_addr(self):
    tag = random.randint(0,8)
    taddr = self.get_addr(tag,0,0,0)
    return taddr
  
  def generate(self):
    self.clear_tag()
  
    for n in range(20000):
      taddr = self.get_random_addr()
      repeat = random.randint(1,4)
      for i in range(repeat):
        self.send_nop(random.randint(0,3))
        op = random.randint(0,2)
        if op == 0:
          self.send_sw(taddr)
        elif op == 1:
          self.send_lw(taddr)
        elif op == 2:
          self.send_amoswap_w(taddr)

    self.tg.done()


# main()
if __name__ == "__main__":
  t = TestStoreBuffer3()
  t.generate()
    
