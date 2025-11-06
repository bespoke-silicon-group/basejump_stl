import sys
import random
from test_base import *

class TestStoreBuffer1(TestBase):
  
  def generate(self):
    self.clear_tag()
  
    for iteration in range(10):
      for n in range(10000):
        tag0 = 0
        tag1 = random.randint(1,3)
        index = 0
        block_offset = random.randint(0,1)
        byte_offset = random.randint(0,3)
        taddr0 = self.get_addr(tag0,index,block_offset,byte_offset)
        taddr1 = self.get_addr(tag1,index,block_offset,byte_offset)
        op = random.randint(0,9)
        if op == 0:
          self.send_sw(taddr0)
        elif op == 1:
          self.send_lw(taddr0)
        elif op == 2:
          self.send_amoswap_w(taddr0)
        elif op == 3:
          self.send_amoor_w(taddr0)
        elif op == 4:
          self.send_sh(taddr0)
        elif op == 5:
          self.send_sb(taddr0)
        elif op == 6:
          self.send_lhu(taddr0)
        elif op == 6:
          self.send_lbu(taddr0)
        elif op == 8:
          self.send_io_sw(taddr1)
        elif op == 9:
          self.send_io_lw(taddr1)
        

    self.tg.done()


# main()
if __name__ == "__main__":
  t = TestStoreBuffer1()
  t.generate()
    
