import sys
import random
from test_base import *

class TestTagfl1(TestBase):

  def generate(self):
    self.clear_tag()

    for iteration in range(1000): 
      for n in range(80):
        tag0 = random.randint(0,9)
        tag1 = random.randint(10,15)
        index = 0
        block_offset = random.randint(0,self.block_size_in_words_p-1)
        taddr0 = self.get_addr(tag0,index,block_offset)
        taddr1 = self.get_addr(tag1,index,block_offset)
        op = random.randint(0,3)
        if op == 0:
         self.send_sw(taddr0)
        elif op == 1:
         self.send_lw(taddr0)
        elif op == 2:
         self.send_io_sw(taddr1)
        elif op == 3:
         self.send_io_lw(taddr1)
      for n in range(4):
        tag0 = random.randint(0,7)
        index = 0
        block_offset = 0
        taddr0 = self.get_addr(tag0,index,block_offset)
        self.send_tagfl(taddr0)

        

    # done
    self.tg.done()


# main()
if __name__ == "__main__":
  t = TestTagfl1()
  t.generate()
