import sys
import random
from test_base import *


class TestByte(TestBase):

  def generate(self):
    self.clear_tag()

    for i in range(200000):
      op = random.randint(0,8)
      addr = random.randint(0,self.MAX_ADDR-1)
      if op == 0:
        self.send(SB, addr)
      elif op == 1:
        self.send(SH, addr)
      elif op == 2:
        self.send(SW, addr)
      elif op == 3:
        self.send(LB, addr)
      elif op == 4:
        self.send(LH, addr)
      elif op == 5:
        self.send(LW, addr)
      elif op == 6:
        self.send(LBU, addr)
      elif op == 7:
        self.send(LHU, addr)
      elif op == 8:
        mask = random.randint(0,3)
        self.send(SM, addr, mask)

    self.tg.done()
          
#   main()
if __name__ == "__main__":
  t = TestByte()
  t.generate()
