#
#   trace_way8.py
#

import sys
sys.path.append('../common')
from bsg_cache_trace_gen import *



#   main()
if __name__ == "__main__":
  data_width_p = 32
  addr_width_p = 32
  tg = BsgCacheTraceGen(addr_width_p, data_width_p)


  # clear tags
  for i in range(8):
    tg.send(TAGST, i << 14, 0)
    tg.recv(0) 

  # disable way 4~7
  tg.send(TAGST, 4<<14, 1<<30)
  tg.recv(0)
  tg.send(TAGST, 5<<14, 1<<30)
  tg.recv(0)
  tg.send(TAGST, 6<<14, 1<<30)
  tg.recv(0)
  tg.send(TAGST, 7<<14, 1<<30)
  tg.recv(0)

  # taglv
  tg.send(TAGLV, 4<<14)
  tg.recv(2)
  tg.send(TAGLV, 5<<14)
  tg.recv(2)
  tg.send(TAGLV, 6<<14)
  tg.recv(2)
  tg.send(TAGLV, 7<<14)
  tg.recv(2)

  # ALOCK
  tg.send(ALOCK, 0<<14)
  tg.recv(0)
  tg.send(ALOCK, 1<<14)
  tg.recv(0)
  tg.send(ALOCK, 2<<14)
  tg.recv(0)

  # store
  tg.send(SW, 3<<14, 0b1111<<3)
  tg.recv(0)
  tg.send(SW, 4<<14, 0b1111111)
  tg.recv(0)


  # tagla
  tg.send(TAGLA, 0<<14)
  tg.recv(0)
  tg.send(TAGLA, 1<<14)
  tg.recv(1<<14)
  tg.send(TAGLA, 2<<14)
  tg.recv(2<<14)
  tg.send(TAGLA, 3<<14)
  tg.recv(4<<14)

  # AUNLOCK random places
  tg.send(AUNLOCK, 1<<24)
  tg.send(AUNLOCK, 1<<25)
  tg.send(AUNLOCK, 1<<26)
  tg.send(AUNLOCK, 1<<27)
  tg.send(AUNLOCK, 1<<28)
  tg.recv(0)
  tg.recv(0)
  tg.recv(0)
  tg.recv(0)
  tg.recv(0)

  # TAGLA
  tg.send(TAGLA, 0<<14)
  tg.send(TAGLA, 1<<14)
  tg.send(TAGLA, 2<<14)
  tg.send(TAGLA, 3<<14)
  tg.recv(0<<14)
  tg.recv(1<<14)
  tg.recv(1<<15)
  tg.recv(1<<16)

  # AUNLOCK way0
  tg.send(AUNLOCK, 0)
  tg.recv(0) 

  # ALOCK way3
  tg.send(ALOCK, 1<<16)
  tg.recv(0)

  # TAGLV
  tg.send(TAGLV, 0<<14)
  tg.send(TAGLV, 1<<14)
  tg.send(TAGLV, 2<<14)
  tg.send(TAGLV, 3<<14)
  tg.recv(0b1)
  tg.recv(0b11)
  tg.recv(0b11)
  tg.recv(0b11)

  # TAGLA
  tg.send(TAGLA, 0<<14)
  tg.send(TAGLA, 1<<14)
  tg.send(TAGLA, 2<<14)
  tg.send(TAGLA, 3<<14)
  tg.recv(0)
  tg.recv(1<<14)
  tg.recv(1<<15)
  tg.recv(1<<16)

  # SW
  tg.send(SW, 1<<14, 0xff000000) 
  tg.send(SW, 1<<15, 0xf0000000) 
  tg.send(SW, 1<<16, 0xc0000000) 
  tg.recv(0)
  tg.recv(0)
  tg.recv(0)

  # AFLINV
  tg.send(AFLINV, 1<<14)
  tg.recv(0) 

  # LW
  tg.send(LW, 1<<14)
  tg.recv(0xff000000)

  # AFL
  tg.send(AFL, 1<<15)
  tg.recv(0)

  # SW
  tg.send(SW, 1<<15, 0xf1e50000)
  tg.recv(0)

  # AINV
  tg.send(AINV, 1<<15)
  tg.recv(0)

  # LW
  tg.send(LW, 1<<15)
  tg.recv(0xf0000000)

  # TAGLV
  tg.send(TAGLV, 1<<15)
  tg.recv(1)

  # TAGST 00000020 0
  tg.send(TAGST, (1<<5) + (0<<14), 0)
  for i in range(1,8):
    tg.send(TAGST, (1<<5) + (i<<14), 1<<30)

  for i in range(8):
    tg.recv(0)

  # SW
  tg.send(SW, (0<<14) + 0b100100, 0b00101001)
  tg.send(SW, (1<<14) + 0b101100, 0b01010100)
  tg.send(SW, (2<<14) + 0b111100, 0b00100101)
  tg.send(SW, (3<<14) + 0b110000, 0b10010010)
  tg.send(SW, (0<<14) + 0b110000, 0b11110010)

  # LW
  tg.send(LW, (2<<14) + 0b111100)
  tg.send(LW, (0<<14) + 0b100100)
  tg.send(LW, (0<<14) + 0b110000)
  tg.send(LW, (3<<14) + 0b110000)
  tg.send(LW, (1<<14) + 0b101100)

  tg.recv(0)
  tg.recv(0)
  tg.recv(0)
  tg.recv(0)
  tg.recv(0)
  tg.recv(0b00100101)
  tg.recv(0b00101001)
  tg.recv(0b11110010)
  tg.recv(0b10010010)
  tg.recv(0b01010100)

  # TAGST 00000040 0
  tg.send(TAGST, (0<<14) + (1<<6), 1<<30)
  tg.send(TAGST, (1<<14) + (1<<6), 0<<30)
  tg.send(TAGST, (2<<14) + (1<<6), 0<<30)
  tg.send(TAGST, (3<<14) + (1<<6), 1<<30)
  tg.send(TAGST, (4<<14) + (1<<6), 1<<30)
  tg.send(TAGST, (5<<14) + (1<<6), 1<<30)
  tg.send(TAGST, (6<<14) + (1<<6), 0<<30)
  tg.send(TAGST, (7<<14) + (1<<6), 1<<30)
  for i in range(8):
    tg.recv(0)

  # SW
  tg.send(SW, (0<<14) + 0b1000100, 0b1)
  tg.send(SW, (1<<14) + 0b1001100, 0b11)
  tg.send(SW, (2<<14) + 0b1010100, 0b111)
  tg.send(SW, (3<<14) + 0b1010100, 0b1111)
  tg.send(SW, (0<<14) + 0b1001100, 0b11111)
  tg.send(SW, (1<<14) + 0b1011000, 0b111111)
  
  tg.send(SW, (4<<14) + 0b1011000, 0b1111111)
  tg.send(SW, (5<<14) + 0b1011000, 0b11111111)
  tg.send(SW, (6<<14) + 0b1001000, 0b111111111)
  tg.send(SW, (7<<14) + 0b1001000, 0b1111111111)
  tg.send(SW, (4<<14) + 0b1010000, 0b11111111111)
  tg.send(SW, (5<<14) + 0b1001000, 0b111111111111)
  tg.send(SW, (6<<14) + 0b1010000, 0b1111111111111)
  tg.send(SW, (7<<14) + 0b1001100, 0b11111111111111)

  # LW
  tg.send(LW, (5<<14) + 0b1001000)
  tg.send(LW, (6<<14) + 0b1010000)
  tg.send(LW, (7<<14) + 0b1001100)
  tg.send(LW, (4<<14) + 0b1011000)
  tg.send(LW, (5<<14) + 0b1011000)
  tg.send(LW, (4<<14) + 0b1010000)
  tg.send(LW, (6<<14) + 0b1001000)
  tg.send(LW, (7<<14) + 0b1001000)

  tg.send(LW, (0<<14) + 0b1001100)
  tg.send(LW, (1<<14) + 0b1011000)
  tg.send(LW, (0<<14) + 0b1000100)
  tg.send(LW, (1<<14) + 0b1001100)
  tg.send(LW, (2<<14) + 0b1010100)
  tg.send(LW, (3<<14) + 0b1010100)
  

  for i in range(14):
    tg.recv(0)

  tg.recv(0b111111111111)
  tg.recv(0b1111111111111)
  tg.recv(0b11111111111111)
  tg.recv(0b1111111)
  tg.recv(0b11111111)
  tg.recv(0b11111111111)
  tg.recv(0b111111111)
  tg.recv(0b1111111111)

  tg.recv(0b11111)
  tg.recv(0b111111)
  tg.recv(0b1)
  tg.recv(0b11)
  tg.recv(0b111)
  tg.recv(0b1111)


  # done
  tg.wait(16)
  tg.done()


