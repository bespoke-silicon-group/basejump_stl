
import random
from test_base import *

class TestStoreBlockClean(TestBase):

  def generate(self):
    self.clear_tag()

    # write some initial data from index 0 - 64,
    for index_s in range(self.sets_p):
      for tag_s in range(self.ways_p):
        taddr = self.get_addr(tag_s, index_s)
        self.send_store_block_clean(taddr)

    # read the data written by store_block_clean
    for index_l in range(self.sets_p):
      for tag_l in range(self.ways_p):
        taddr = self.get_addr(tag_l, index_l)
        self.send_load_block(taddr)

    # write some data to "evict" the cached blocks
    for index_s in range(self.sets_p):
      for tag_s in range(self.ways_p, 2*self.ways_p):
        taddr = self.get_addr(tag_s, index_s)
        self.send_store_block_clean(taddr)
    
    # the point of the evictions is to verify there is no eviction
    # because all the cache blocked "evicted" is written by store mask clean

    # done
    self.tg.done()

  # Eviction Count from store_stats should be 0

# main()
if __name__ == "__main__":
  t = TestStoreBlockClean()
  t.generate()