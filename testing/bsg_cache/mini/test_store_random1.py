import sys
import random
from test_base import *

class TestStoreRandom1(TestBase):
  
  def generate(self):
    self.clear_tag()
  
    for n in range(100):
      tag = random.randint(0,15)
      index = 0
      block_offset = 0
      byte_offset = 0
      taddr = self.get_addr(tag,index,block_offset,byte_offset)
      self.send_sw(taddr)
      self.tg.wait(100)
        

    self.tg.done()


# main()
if __name__ == "__main__":
  t = TestStoreRandom1()
  t.generate()
    
