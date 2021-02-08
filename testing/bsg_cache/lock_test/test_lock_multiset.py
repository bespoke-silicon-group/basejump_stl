import sys
import random
from test_base import *

class TestLock1(TestBase):

  def generate(self):
    self.clear_tag()

    # lock one way x of each set
    for set_index in range(0, self.sets_p):
      tag = random.randint(0,15) # set a specific tag will not be accessed later
      taddr = self.get_addr(tag,set_index)
      self.send_alock(taddr)

    # Acces other ways in a random set
    for iteration in range(50000): 
      tag = random.randint(0,15)
      set_index =  random.randint(0,self.sets_p-1)
      taddr = self.get_addr(tag,set_index)
      op = random.randint(0,1)
      if op == 0:
        self.send_sw(taddr)
      elif op == 1:
        self.send_lw(taddr)
         
    # done
    self.tg.done()


# main()
if __name__ == "__main__":
  t = TestLock1()
  t.generate()
