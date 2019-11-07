import sys
import random
from test_base import *


class TestLinear(TestBase):
  
  def generate(self):
    self.clear_tag()

    for iteration in range(5000):
      length = random.randint(1,32)
      store_not_load = random.randint(0,1)
     
      tag = random.randint(0,15)
      index = random.randint(0,127)
      block_offset = random.randint(0,7) 
      base_addr = self.get_addr(tag, index, block_offset)

      if store_not_load:
        for i in range(length):
          self.wait(random.randint(0,7))
          taddr = base_addr + (4*i)
          if taddr < self.MAX_ADDR:
            self.send(SW, taddr)
      else:
        for i in range(length):
          self.wait(random.randint(0,7))
          taddr = base_addr + (4*i)
          if taddr < self.MAX_ADDR:
            self.send(SW, taddr)
      

    self.tg.done()
      
      

#   main()
if __name__ == "__main__":
  st = TestLinear()
  st.generate()
