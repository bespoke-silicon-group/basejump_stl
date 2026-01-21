import sys
import random
from test_base import *

class TestByte2(TestBase):
  
  def generate(self):
    self.clear_tag()
  
    for iteration in range(10):
      for n in range(1600):
        tag0 = random.randint(0,1)
        tag1 = random.randint(2,3)
        index = random.randint(0,0)
        block_offset = random.randint(0,0)
        byte_offset = random.randint(0,3)
        taddr0 = self.get_addr(tag0, index, block_offset, byte_offset)
        taddr1 = self.get_addr(tag1, index, block_offset, byte_offset)
        store_op = random.randint(0,3)
        if store_op == 0:
          self.send_sw(taddr0)
        elif store_op == 1:
          self.send_sh(taddr0)
        elif store_op == 2:
          self.send_sb(taddr0)
        elif store_op == 3:
          self.send_io_sw(taddr1)

      for n in range(1600):
        tag0 = random.randint(0,1)
        tag1 = random.randint(2,3)
        index = random.randint(0,0)
        block_offset = random.randint(0,0)
        byte_offset = random.randint(0,3)
        taddr0 = self.get_addr(tag0, index, block_offset, byte_offset)
        taddr1 = self.get_addr(tag1, index, block_offset, byte_offset)
        load_op = random.randint(0,5)
        if load_op == 0:
          self.send_lw(taddr0)
        elif load_op == 1:
          self.send_lh(taddr0)
        elif load_op == 2:
          self.send_lb(taddr0)
        elif load_op == 3:
          self.send_lhu(taddr0)
        elif load_op == 4:
          self.send_lbu(taddr0)
        elif load_op == 5:
          self.send_io_lw(taddr1)
          

    self.tg.done()


# main()
if __name__ == "__main__":
  t = TestByte2()
  t.generate()
    
