import sys
import random
from test_base import *


class TestAINV(TestBase):

  def generate(self):
    # scrub tag and data
    self.clear_tag()
  
    for iteration in range(10):
      # random SW
      for n in range(1000):
        tag = random.randint(0, self.ways_p-1)
        index = random.randint(0, self.sets_p-1)
        block_offset = random.randint(0, self.block_size_in_words_p-1)
        taddr = self.get_addr(tag,index,block_offset)
        self.send_sw(taddr)

      # ainv everything
      for tag in range(self.ways_p): 
        for index in range(self.sets_p):
          taddr = self.get_addr(tag,index)
          self.send_ainv(taddr) 

      # random LW
      for n in range(1000):
        tag = random.randint(0,self.ways_p-1)
        index = random.randint(0,self.sets_p-1)
        block_offset = random.randint(0,self.block_size_in_words_p-1)
        taddr = self.get_addr(tag,index,block_offset)
        self.send_lw(taddr)
      
    self.tg.done()
          
#   main()
if __name__ == "__main__":
  t = TestAINV()
  t.generate()
