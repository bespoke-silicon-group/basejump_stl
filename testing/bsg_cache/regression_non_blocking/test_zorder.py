import sys
import random
from test_base import *


class TestZOrder(TestBase):

  def generate(self):
    # scrub tag and data
    self.clear_tag()
    for i in range(self.MAX_ADDR/4):
      self.send(SW, 4*i)

    for order in range(1,7):
      self.__test_zorder(order)
    
    self.tg.done()
    
  def __test_zorder(self, order):
    i_idx = []
    for y in range(2**order):
      for x in range(2**order):
        # interleave x,y bits
        idx = 0
        temp_x = x
        temp_y = y
        for o in range(order):
          xbit = temp_x & 1
          ybit = temp_y & 1
          idx = idx | (xbit << (2*o))
          idx = idx | (ybit << ((2*o)+1))
          temp_x = temp_x >> 1
          temp_y = temp_y >> 1
        i_idx.append(idx)

    z_idx = [0]*(2**(order*2))
    for i in range(2**(order*2)):
      z_idx[i_idx[i]] = i

    for z in z_idx:
      taddr = (z*4)
      self.send(SW, taddr)
    for z in z_idx:
      taddr = (z*4)
      self.send(LW, taddr)
          
#   main()
if __name__ == "__main__":
  z = TestZOrder()
  z.generate()
