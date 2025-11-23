import sys
import random
from test_base import *

class TestAlock1(TestBase):

  def generate(self):
    self.clear_tag()
 
    locked_tag = set()

    for n in range(300000):
      tag0 = random.randint(0,9)
      tag1 = random.randint(10,15)
      index = 0
      block_offset = random.randint(0,self.block_size_in_words_p-1)
      taddr0 = self.get_addr(tag0,index,block_offset)
      taddr1 = self.get_addr(tag1,index,block_offset)
      op = random.randint(0,5)
      if op == 0:
        self.send_sw(taddr0)
      elif op == 1:
        self.send_lw(taddr0)
      elif op == 2:
         self.send_io_sw(taddr1)
      elif op == 3:
         self.send_io_lw(taddr1)
      elif op == 4:
        if len(locked_tag) < self.ways_p-1:
          self.send_alock(taddr0)
          locked_tag.add(tag0)
      elif op == 5:
        self.send_aunlock(taddr0)
        if tag0 in locked_tag:
          locked_tag.remove(tag0)
        

    # done
    self.tg.done()


# main()
if __name__ == "__main__":
  t = TestAlock1()
  t.generate()
