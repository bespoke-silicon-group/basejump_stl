import sys
import random
from test_base import *


class TestPECover(TestBase):

  def generate(self):
    # scrub tag and data
    self.clear_tag()

    for n in range(1,2**self.ways_p):
      # aflinv 
      for w in range(self.ways_p):
        taddr = self.get_addr(w,0)
        self.send_aflinv(taddr)

      #
      for w in range(self.ways_p):
        if (1<<w) & n:
          store_not_load = random.randint(0,1)
          if store_not_load:
            for b in range(self.block_size_in_words_p):
              taddr = self.get_addr(w, 0, b)
              self.send_sw(taddr)
          else:
            for b in range(self.block_size_in_words_p):
              taddr = self.get_addr(w, 0, b)
              self.send_lw(taddr)
  

    self.tg.done()
          
#   main()
if __name__ == "__main__":
  t = TestPECover()
  t.generate()
