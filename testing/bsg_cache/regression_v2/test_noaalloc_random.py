import random
from test_base import *

class TestNoaallocRandom(TestBase):

  def generate(self):
    self.clear_tag()

    for n in range(25000):
      tag = random.randint(0,2*self.ways_p)
      index = 0
      store_not_load = random.randint(0,1)
      if store_not_load == 1:
        block_addr = self.get_addr(tag,index)
        self.send_store_block(block_addr)
      else:
        block_addr = self.get_addr(tag,index)
        self.send_load_block(block_addr)

    # done
    self.tg.done()


# main()
if __name__ == "__main__":
  t = TestNoaallocRandom()
  t.generate()