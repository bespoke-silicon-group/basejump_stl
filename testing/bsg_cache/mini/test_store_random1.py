import sys
import random
from test_base import *

class TestStoreRandom1(TestBase):
  
  def generate(self):
    self.clear_tag()
  
    for n in range(500):
      tag0 = random.randint(0,15)
      tag1 = random.randint(16,31)
      index = 0
      block_offset = 0
      byte_offset = 0
      taddr0 = self.get_addr(tag0,index,block_offset,byte_offset)
      taddr1 = self.get_addr(tag1,index,block_offset,byte_offset)
      io_op = random.randint(0,1)
      self.send_sw(taddr0)
      if io_op == 1:
        self.send_io_sw(taddr1)
      self.tg.wait(100)
        

    self.tg.done()


# main()
if __name__ == "__main__":
  t = TestStoreRandom1()
  t.generate()
    
