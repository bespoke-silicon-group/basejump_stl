import sys
import random
from test_base import *

class TestAtomic2(TestBase):

  def generate(self):
    self.clear_tag()

    for n in range(10000):
      tag = random.randint(0,9)
      index = random.randint(0,1)
      block_offset = random.randint(0, self.block_size_in_words_p-1)
      byte_offset = 0
      taddr = self.get_addr(tag, index, block_offset, byte_offset)
      op = random.randint(0,2)
      if op == 0:
        self.send_amoor_w(taddr)
      elif op == 1:
        self.send_sw(taddr)
      elif op == 2:
        self.send_lw(taddr)

    self.tg.done()





# main()
if __name__ == "__main__":
  t = TestAtomic2()
  t.generate()
