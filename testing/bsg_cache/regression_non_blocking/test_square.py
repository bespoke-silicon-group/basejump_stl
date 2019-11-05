import sys
import random
from test_base import *


class TestSquare(TestBase):

  def generate(self):
    # scrub tag and data
    self.clear_tag()
    for i in range(self.MAX_ADDR/4):
      self.send(SW, 4*i)

    for i in range(1000):
      start_addr = random.randint(0,(self.MAX_ADDR/4)-1)*4
      r = random.randint(1,8)
      c = random.randint(1,8)
      self.__test_square(start_addr, r, c)

    self.tg.done()

  def __test_square(self, start_addr, row, col):
    start_word_addr = start_addr - (start_addr%4)
    for r in range(row):
      for c in range(col):
        center_addr = start_word_addr + (c*4) + (4*col*r)
        taddrs = []
        taddrs.append(center_addr - 4 - (col*4))  # top-left
        taddrs.append(center_addr - (col*4))      # top
        taddrs.append(center_addr + 4 - (col*4))  # top-right
        taddrs.append(center_addr + 4)            # right
        taddrs.append(center_addr + 4 + (col*4))  # bot-right
        taddrs.append(center_addr + (col*4))      # bot
        taddrs.append(center_addr - 4 + (col*4))  # bot-left
        taddrs.append(center_addr + 4)            # left
        store_not_load = random.randint(0,1)
        for taddr in taddrs:
          if taddr >= 0 and taddr < self.MAX_ADDR:
            if store_not_load:
              self.send(SW, taddr)
            else:
              self.send(LW, taddr)


          
#   main()
if __name__ == "__main__":
  sq = TestSquare()
  sq.generate()
