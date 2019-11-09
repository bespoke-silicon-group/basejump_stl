import sys
import random
from test_base import *


class TestALOCK(TestBase):

  def generate(self):
    random.seed(0)
    
    # scrub tag
    self.clear_tag()

    locked_tags = [set()]*self.sets_p

    for iteration in range(300):
      
      # lock some sets
      for n in range(25):
        index = random.randint(0, 1)
        #index = 0
        if len(locked_tags[index]) < 6:
          tag = random.randint(0,15)
          taddr = self.get_addr(tag, index)
          self.send_alock(taddr)
          locked_tags[index].add(tag)
          print("//" + str(locked_tags[index]))

      # random lw/sw
      for n in range(0):
        tag = random.randint(0,15)
        index = random.randint(0, 1)
        #index = 0
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
        index = random.randint(0, 1)
        #index = 0
        taddr = self.get_addr(tag, index)
        self.send_aunlock(taddr)
        if tag in locked_tags[index]:
          locked_tags[index].remove(tag)
        print("//" + str(locked_tags[index]))


    # done
    self.tg.done()
          
#   main()
if __name__ == "__main__":
  t = TestALOCK()
  t.generate()
