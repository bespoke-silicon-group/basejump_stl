import sys
import random
from test_base import *


class TestInvalidLock(TestBase):

  def generate(self):
    # scrub tag and data
    self.clear_tag()

    # lock index 0
    self.send_tagst(way=0, index=0, valid=0, lock=1)
    # lock index 1
    self.send_tagst(way=1, index=1, valid=0, lock=1)
    self.send_tagst(way=3, index=1, valid=0, lock=1)
    # lock index 2
    self.send_tagst(way=0, index=2, valid=0, lock=1)
    self.send_tagst(way=3, index=2, valid=0, lock=1)
    self.send_tagst(way=6, index=2, valid=0, lock=1)
    # lock index 3
    self.send_tagst(way=2, index=3, valid=0, lock=1)
    self.send_tagst(way=3, index=3, valid=0, lock=1)
    self.send_tagst(way=4, index=3, valid=0, lock=1)
    self.send_tagst(way=7, index=3, valid=0, lock=1)
    # lock index 4
    self.send_tagst(way=0, index=4, valid=0, lock=1)
    self.send_tagst(way=1, index=4, valid=0, lock=1)
    self.send_tagst(way=3, index=4, valid=0, lock=1)
    self.send_tagst(way=5, index=4, valid=0, lock=1)
    self.send_tagst(way=6, index=4, valid=0, lock=1)
    # lock index 5
    self.send_tagst(way=0, index=5, valid=0, lock=1)
    self.send_tagst(way=1, index=5, valid=0, lock=1)
    self.send_tagst(way=3, index=5, valid=0, lock=1)
    self.send_tagst(way=5, index=5, valid=0, lock=1)
    self.send_tagst(way=6, index=5, valid=0, lock=1)
    self.send_tagst(way=7, index=5, valid=0, lock=1)
    # lock index 6
    self.send_tagst(way=4, index=6, valid=0, lock=1)
    # lock index 7
    self.send_tagst(way=2, index=7, valid=0, lock=1)
    self.send_tagst(way=4, index=7, valid=0, lock=1)
    self.send_tagst(way=7, index=7, valid=0, lock=1)


    # random SW/LW
    for n in range(200000):
      tag = random.randint(0,9)
      index = random.randint(0,7)
      block_offset = random.randint(0,self.block_size_in_words_p-1)
      addr = self.get_addr(tag,index,block_offset)

      store_not_load = random.randint(0,1)
      if store_not_load:
        self.send(SW, addr)
      else:
        self.send(LW, addr)

    self.tg.done()
          
#   main()
if __name__ == "__main__":
  t = TestInvalidLock()
  t.generate()
