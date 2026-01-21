import sys
import random
from test_base import *

class TestBlock1(TestBase):

  def generate(self):
    self.clear_tag()
 
    for n in range(25000):
      tag0 = random.randint(0,3)
      tag1 = random.randint(4,7)
      index = random.randint(0,7)
      store_not_load = random.randint(0,1)
      if store_not_load == 1:
        for b in range(self.block_size_in_words_p):
          taddr0 = self.get_addr(tag0,index,b)
          taddr1 = self.get_addr(tag1,index,b)
          self.send_sw(taddr0)
          self.send_io_sw(taddr1)
      else:
        for b in range(self.block_size_in_words_p):
          taddr0 = self.get_addr(tag0,index,b)
          taddr1 = self.get_addr(tag1,index,b)
          self.send_lw(taddr0)
          self.send_io_lw(taddr1)

    # done
    self.tg.done()


# main()
if __name__ == "__main__":
  t = TestBlock1()
  t.generate()
