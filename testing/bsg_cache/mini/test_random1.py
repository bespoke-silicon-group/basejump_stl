import sys
import random
from test_base import *

class TestRandom1(TestBase):
  
  def generate(self):
    self.clear_tag()
  
    for iteration in range(10):
      for n in range(1600):
        tag0 = random.randint(0,15)
        tag1 = random.randint(16,31)
        index = random.randint(0,3)
        block_offset = random.randint(0,self.block_size_in_words_p-1)
        taddr0 = self.get_addr(tag0,index,block_offset)
        taddr1 = self.get_addr(tag1,index,block_offset)
        self.send_sw(taddr0)
        self.send_io_sw(taddr1)
      for n in range(1600):
        tag0 = random.randint(0,15)
        tag1 = random.randint(16,31)
        index = random.randint(0,3)
        block_offset = random.randint(0,self.block_size_in_words_p-1)
        taddr0 = self.get_addr(tag0,index,block_offset)
        taddr1 = self.get_addr(tag1,index,block_offset)
        self.send_lw(taddr0)
        self.send_io_lw(taddr1)

    self.tg.done()


# main()
if __name__ == "__main__":
  t = TestRandom1()
  t.generate()
    
