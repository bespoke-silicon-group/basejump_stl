import sys
import random
from test_base import *

class TestStoreBuffer3(TestBase):

  def get_random_addr0(self):
    tag = random.randint(0,8)
    taddr = self.get_addr(tag,0,0,0)
    return taddr
  
  def get_random_addr1(self):
    tag = random.randint(9,15)
    taddr = self.get_addr(tag,0,0,0)
    return taddr

  def generate(self):
    self.clear_tag()
  
    for n in range(30000):
      taddr0 = self.get_random_addr0()
      taddr1 = self.get_random_addr1()
      repeat = random.randint(1,4)
      for i in range(repeat):
        self.send_nop(random.randint(0,3))
        op = random.randint(0,4)
        if op == 0:
          self.send_sw(taddr0)
        elif op == 1:
          self.send_lw(taddr0)
        elif op == 2:
          self.send_io_sw(taddr1)
        elif op == 3:
          self.send_io_lw(taddr1)
        elif op == 4:
          self.send_amoswap_w(taddr0)

    self.tg.done()


# main()
if __name__ == "__main__":
  t = TestStoreBuffer3()
  t.generate()
    
