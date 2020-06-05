import sys
import random
from test_base import *

class TestRandom2(TestBase):

  def generate(self):
    self.clear_tag()

    for n in range(80000):
      tag = random.randint(0,15)
      index = random.randint(0,3)
      block_offset = random.randint(0, self.block_size_in_words_p-1)
      byte_offset = random.randint(0, 7)
      taddr = self.get_addr(tag, index, block_offset, byte_offset)
      op = random.randint(0,10)

      if op == 0:
        self.send_sd(taddr)
      elif op == 1:
        self.send_sw(taddr)
      elif op == 2:
        self.send_sh(taddr)
      elif op == 3:
        self.send_sb(taddr)
      elif op == 4:
        self.send_ld(taddr)
      elif op == 5:
        self.send_lw(taddr)
      elif op == 6:
        self.send_lh(taddr)
      elif op == 7:
        self.send_lb(taddr)
      elif op == 8:
        self.send_lwu(taddr)
      elif op == 9:
        self.send_lhu(taddr)
      elif op == 10:
        self.send_lbu(taddr)



    self.tg.done()





# main()
if __name__ == "__main__":
  t = TestRandom2()
  t.generate()
