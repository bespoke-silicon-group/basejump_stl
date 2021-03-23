import random
from test_base import *

class TestAalloc1(TestBase):
  # These test make sure cache_line allocation works with either cache miss or cache hit
  # 0   <= index <= 127: cache miss and allocate
  # 128 <= index <= 255: cache hit 
  def generate(self):
    self.clear_tag()
 
    for index_n in range(256):
      for tag_n in range(8):
        tag = tag_n
        index = index_n % 128
        taddr = self.get_addr(tag, index)
        self.send_aalloc(taddr)

    # done
    self.tg.done()


# main()
if __name__ == "__main__":
  t = TestAalloc1()
  t.generate()