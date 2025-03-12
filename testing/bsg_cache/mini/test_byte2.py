import sys
import random
from test_base import *

class TestByte2(TestBase):
  
  def generate(self):
    self.clear_tag()
  
    for iteration in range(10):
      for n in range(1000):
        tag = random.randint(0,1)
        index = random.randint(0,0)
        block_offset = random.randint(0,0)
        byte_offset = random.randint(0,3)
        taddr = self.get_addr(tag, index, block_offset, byte_offset)
        store_op = random.randint(0,2)
        if store_op == 0:
          self.send_sw(taddr)
        elif store_op == 1:
          self.send_sh(taddr)
        elif store_op == 2:
          self.send_sb(taddr)

      for n in range(1000):
        tag = random.randint(0,1)
        index = random.randint(0,0)
        block_offset = random.randint(0,0)
        byte_offset = random.randint(0,3)
        taddr = self.get_addr(tag, index, block_offset, byte_offset)
        load_op = random.randint(0,4)
        if load_op == 0:
          self.send_lw(taddr)
        elif load_op == 1:
          self.send_lh(taddr)
        elif load_op == 2:
          self.send_lb(taddr)
        elif load_op == 3:
          self.send_lhu(taddr)
        elif load_op == 4:
          self.send_lbu(taddr)
          

    self.tg.done()


# main()
if __name__ == "__main__":
  t = TestByte2()
  t.generate()
    
