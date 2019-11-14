import sys
import random
from test_base import *


class TestALOCK(TestBase):

  def generate(self):
    random.seed(0)
    
    # scrub tag
    self.clear_tag()

    #locked_tags = [set()]*self.sets_p
    locked_tags = []
    for i in range(self.sets_p):
      locked_tags.append(set())

    for iteration in range(200):
      
      # lock some sets
      for n in range(25):
        index = random.randint(0,3)
        if len(locked_tags[index]) < 6:
          tag = random.randint(0,15)
          taddr = self.get_addr(tag, index)
          self.send_alock(taddr)
          locked_tags[index].add(tag)
          #print("// index: {}, tags: {}".format(index, str(locked_tags[index])))

      # random lw/sw
      for n in range(1000):
        tag = random.randint(0,15)
        index = random.randint(0,3)
        block_offset = random.randint(0, self.block_size_in_words_p-1)
        taddr = self.get_addr(tag,index,block_offset)

        store_not_load = random.randint(0,1)
        if store_not_load:
          self.send_sw(taddr)
        else:
          self.send_lw(taddr)

      # unlock some sets
      for n in range(25):
        tag = random.randint(0,15)
        index = random.randint(0,3)
        taddr = self.get_addr(tag, index)
        self.send_aunlock(taddr)
        if tag in locked_tags[index]:
          locked_tags[index].remove(tag)
        #print("// index: {}, tags: {}".format(index, str(locked_tags[index])))

      # random lw/sw
      for n in range(1000):
        tag = random.randint(0,15)
        index = random.randint(0,3)
        block_offset = random.randint(0, self.block_size_in_words_p-1)
        taddr = self.get_addr(tag,index,block_offset)

        store_not_load = random.randint(0,1)
        if store_not_load:
          self.send_sw(taddr)
        else:
          self.send_lw(taddr)

    # done
    self.tg.done()
          
#   main()
if __name__ == "__main__":
  t = TestALOCK()
  t.generate()
