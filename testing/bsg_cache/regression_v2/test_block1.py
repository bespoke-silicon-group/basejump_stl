import sys
import random
from test_base import *

class TestBlock1(TestBase):

  def generate(self):
    self.clear_tag()
 
    for n in range(25000):
      tag = random.randint(0,3)
      index = random.randint(0,7)
      store_not_load = random.randint(0,1)
      if store_not_load == 1:
        for b in range(self.block_size_in_words_p):
          taddr = self.get_addr(tag,index,b)
          self.send_sw(taddr)
      else:
        for b in range(self.block_size_in_words_p):
          taddr = self.get_addr(tag,index,b)
          self.send_lw(taddr)

    # done
    self.tg.done()


# main()
if __name__ == "__main__":
  t = TestBlock1()
  t.generate()
