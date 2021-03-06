import sys
import random
from test_base import *

class TestAlock1(TestBase):

  def generate(self):
    self.clear_tag()
 
    locked_tag = set()

    for n in range(160000):
      tag = random.randint(0,9)
      index = 0
      block_offset = random.randint(0,self.block_size_in_words_p-1)
      taddr = self.get_addr(tag,index,block_offset)
      op = random.randint(0,3)
      if op == 0:
        self.send_sw(taddr)
      elif op == 1:
        self.send_lw(taddr)
      elif op == 2:
        if len(locked_tag) < self.ways_p-1:
          self.send_alock(taddr)
          locked_tag.add(tag)
      elif op == 3:
        self.send_aunlock(taddr)
        if tag in locked_tag:
          locked_tag.remove(tag)
        

    # done
    self.tg.done()


# main()
if __name__ == "__main__":
  t = TestAlock1()
  t.generate()
