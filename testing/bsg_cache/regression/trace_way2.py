#
#   trace_way4.py
#

import sys
sys.path.append('../common')
from bsg_cache_trace_gen import *


#   main()
if __name__ == "__main__":
  data_width_p = 32
  addr_width_p = 32
  tg = BsgCacheTraceGen(addr_width_p, data_width_p)

  #### TEST BEGIN ####
  
  # TAGST 00000000 0
  tg.send(TAGST, 0<<14, 0) 
  tg.recv(0)

  # TAGST 00004000 0
  tg.send(TAGST, 1<<14, 0) 
  tg.recv(0)

  # SW 00000000 ffffffff
  tg.send(SW, 0, 0xffffffff)
  tg.recv(0)

  # LW 0
  tg.send(LW, 0)
  tg.recv(0xffffffff)

  # TAGFL 00000000
  tg.send(TAGFL, 0)
  tg.recv(0)

  # LW 00000000
  tg.send(LW, 0)
  tg.recv(0xffffffff)

  # TAGLV 00000000
  tg.send(TAGLV, 0<<14)
  tg.recv(1)
  
  # TAGLV 00004000
  tg.send(TAGLV, 1<<14)
  tg.recv(0)

  # SB 00004000 55555555
  tg.send(SB, 1<<14, 0x55555555)
  tg.recv(0)

  # LW 00004000
  tg.send(LW, 1<<14)
  tg.recv(0x55)

  # SB 00004000 55555555
  tg.send(SB, (1<<14) + 3, 0x55555555)
  tg.recv(0)

  # LW 00004000
  tg.send(LW, 1<<14)
  tg.recv(0x55000055)

  # TAGLA 00004000
  tg.send(TAGLA, 1<<14)
  tg.recv(1<<14)

  # TAGLA
  tg.send(TAGLA, 0<<14)
  tg.recv(0)

  # TAGLV
  tg.send(TAGLV, 0<<14)
  tg.recv(1)

  # SW
  tg.send(SW, (0b1111<<28) + (0<<2), 0x00000000)
  tg.recv(0)
  tg.send(SW, (0b1111<<28) + (1<<2), 0x11111111)
  tg.recv(0)
  tg.send(SW, (0b1111<<28) + (2<<2), 0x22222222)
  tg.recv(0)
  tg.send(SW, (0b1111<<28) + (3<<2), 0x33333333)
  tg.recv(0)
  tg.send(SW, (0b1111<<28) + (4<<2), 0x44444444)
  tg.recv(0)
  tg.send(SW, (0b1111<<28) + (5<<2), 0x55555555)
  tg.recv(0)
  tg.send(SW, (0b1111<<28) + (6<<2), 0x66666666)
  tg.recv(0)
  tg.send(SW, (0b1111<<28) + (7<<2), 0x77777777)
  tg.recv(0)

  # AFL
  tg.send(AFL, 0b1111<<28)
  tg.recv(0)
  
  # SW
  tg.send(SW, (0b1111<<28) + (0<<2), 0xffffffff)
  tg.recv(0)
  tg.send(SW, (0b1111<<28) + (1<<2), 0xffffffff)
  tg.recv(0)
  tg.send(SW, (0b1111<<28) + (2<<2), 0xffffffff)
  tg.recv(0)
  tg.send(SW, (0b1111<<28) + (3<<2), 0xffffffff)
  tg.recv(0)
  tg.send(SW, (0b1111<<28) + (4<<2), 0xffffffff)
  tg.recv(0)
  tg.send(SW, (0b1111<<28) + (5<<2), 0xffffffff)
  tg.recv(0)
  tg.send(SW, (0b1111<<28) + (6<<2), 0xffffffff)
  tg.recv(0)
  tg.send(SW, (0b1111<<28) + (7<<2), 0xffffffff)
  tg.recv(0)

  # AINV
  tg.send(AINV, 0b1111<<28)
  tg.recv(0)

  # LW
  tg.send(LW, (0b1111<<28) + (4<<2))
  tg.recv(0x44444444)

  tg.send(LW, (0b1111<<28) + (0<<2))
  tg.recv(0x00000000)
  
  tg.send(LW, (0b1111<<28) + (1<<2))
  tg.recv(0x11111111)

  tg.send(LW, (0b1111<<28) + (2<<2))
  tg.recv(0x22222222)

  tg.send(LW, (0b1111<<28) + (3<<2))
  tg.recv(0x33333333)

  tg.send(LW, (0b1111<<28) + (4<<2))
  tg.recv(0x44444444)

  tg.send(LW, (0b1111<<28) + (5<<2))
  tg.recv(0x55555555)

  tg.send(LW, (0b1111<<28) + (6<<2))
  tg.recv(0x66666666)

  tg.send(LW, (0b1111<<28) + (7<<2))
  tg.recv(0x77777777)

  # SW
  for i in range(8):
    tg.send(SW, (0b1111<<28) + (i<<2), 0xffffffff)
    tg.recv(0)

  # TAGLV
  tg.send(TAGLV, 0)
  tg.recv(1)

  # TAGLA
  tg.send(TAGLA, 0)
  tg.recv(0b1111<<28)

  # AFLINV
  tg.send(AFLINV, 0b1111<<28)
  tg.recv(0)
  
  # TAGLV
  tg.send(TAGLV, 0)
  tg.recv(0)
  
  # TAGLA
  tg.send(TAGLA, 0)
  tg.recv(0b1111<<28)

  # SW
  tg.send(SW, 0b1111<<28, 0b1101)
  tg.recv(0)
  tg.send(SH, 0b1111<<28, 0b0001110001100010)
  tg.recv(0)
  tg.send(SH, (0b1111<<28) + 2, 0b0001110001100010)
  tg.recv(0)
  tg.send(SB, (0b1111<<28) + 3, 0b1111)
  tg.recv(0)

  # LW
  tg.send(LW, 0b1111<<28)
  tg.recv(0b00001111011000100001110001100010)

  # LB
  tg.send(LB, 0b1111<<28)
  tg.recv(0b1100010)

  # LB
  tg.send(LH, 0b1111<<28)
  tg.recv(0b1110001100010)



  # TAGST 00000000 0
  tg.send(TAGST, 0<<14, 0)
  tg.recv(0)

  # TAGST 00004000 0
  tg.send(TAGST, 1<<14, 0)
  tg.recv(0)

  # SW
  tg.send(SW, 0b11<<30, 0)
  tg.recv(0)

  # SW
  tg.send(SW, 0b10<<30, 0)
  tg.recv(0)

  # TAGST 00000000 0
  tg.send(TAGST, 0<<14, 0xf)
  tg.recv(0)

  # TAGST 00004000 0
  tg.send(TAGST, 1<<14, 0xf0)
  tg.recv(0)

  # TAGLV
  tg.send(TAGLV, 0<<14)
  tg.recv(0)
  tg.send(TAGLV, 1<<14)
  tg.recv(0)

  # TAGLA
  tg.send(TAGLA, 0<<14)
  tg.recv(0xf<<14)
  tg.send(TAGLA, 1<<14)
  tg.recv(0xf0<<14)

  # does it refill after evict?
  # SW a
  tg.send(SW, 3, 0xf0000000)
  tg.recv(0)

  # SW b
  tg.send(SW, (1<<14) + 5, 0xf0000000)
  tg.recv(0)

  # LW c
  tg.send(LW, (3<<14))
  tg.recv(0)

  # LW a
  tg.send(LW, 3)
  tg.recv(0b1111<<28)
  
  # LW b
  tg.send(LW, (1<<14) + 5)
  tg.recv(0b1111<<28)


  # TAGST
  tg.send(TAGST, 0, 0)
  tg.recv(0)

  # TAGST
  tg.send(TAGST, 1<<14, 0)
  tg.recv(0)

  # SW
  for i in range(8):
    tg.send(SW, i<<2, 0xcccc0000)
    tg.recv(0)
  
  tg.send(SH, 0b111<<2, 0xff0f)
  tg.recv(0)
  
  # LW
  tg.send(LW, 7<<2)
  tg.recv(0xccccff0f)
  tg.send(LW, 7<<2)
  tg.recv(0xccccff0f)
  tg.send(LW, 7<<2)
  tg.recv(0xccccff0f)
  tg.send(LW, 7<<2)
  tg.recv(0xccccff0f)
 
  # SW
  tg.send(SW, (0b110<<14) + 0b000, 0x007f0000)
  tg.recv(0)
  tg.send(SW, (0b110<<14) + 0b100, 0x01ff0000)
  tg.recv(0)
  tg.send(SW, (0b110<<14) + 0b1000, 0x07ff0000)
  tg.recv(0)
  tg.send(SW, (0b110<<14) + 0b1100, 0x1fff0000)
  tg.recv(0)

  # LW
  tg.send(LW, 0b110<<14)
  tg.recv(0x007f0000)
  
  # AFLINV
  tg.send(AFLINV, 0b110<<14)
  tg.recv(0) 

  # AFLINV
  tg.send(AFLINV, 0b1100)
  tg.recv(0) 

  # TAGLV
  tg.send(TAGLV, 0)
  tg.recv(0)

  # TAGLV
  tg.send(TAGLV, 0b110<<14)
  tg.recv(0)

  # LW
  tg.send(LW, 0b11100)
  tg.recv(0xccccff0f)
  tg.send(LW, (0b110<<14) + 0b1100)
  tg.recv(0x1fff0000)

  # SW
  tg.send(SW, (0b110<<14) + (0b1100), 0xf83f07c0)
  tg.recv(0)

  # AINV
  tg.send(AINV, (0b110<<14))
  tg.recv(0)

  # LW
  tg.send(LW, (0b110<<14) + (0b1100))
  tg.recv(0x1fff0000)

  # SW
  tg.send(SW, 0b111<<14, 0xf0e80198)
  tg.recv(0)

  # LB sigext
  tg.send(LB, (0b111<<14)+0)
  tg.recv(0xffffff98)
  tg.send(LB, (0b111<<14)+1)
  tg.recv(0x1)
  tg.send(LB, (0b111<<14)+2)
  tg.recv(0xffffffe8)
  tg.send(LB, (0b111<<14)+3)
  tg.recv(0xfffffff0)
  
  # SW
  tg.send(SW, 0x1d000000, 0xdbcd39a0)
  tg.recv(0)
  # SH
  tg.send(SH, 0x1d000000, 0xffaf00ff)
  tg.recv(0)
  # SB
  tg.send(SB, 0x1d000001, 0xd5ab00ff)
  tg.recv(0)

  # LB
  tg.send(LBU, 0x1d000000)
  tg.recv(0xff)
  tg.send(LBU, 0x1d000001)
  tg.recv(0xff)
  tg.send(LBU, 0x1d000002)
  tg.recv(0xcd)
  tg.send(LBU, 0x1d000003)
  tg.recv(0xdb)


  # TAGST
  tg.send(TAGST, 0x0340, 0)
  tg.recv(0)
  tg.send(TAGST, 0x4340, 0)
  tg.recv(0)

  # SW
  tg.send(SW, 0x0347, 0)
  tg.recv(0)

  # AINV
  tg.send(AINV, 0)
  tg.recv(0)

  # SW
  tg.send(SW, 0, 0xffff0000)
  tg.recv(0)

  # LW
  tg.send(LW, 0)
  tg.recv(0xffff0000)

  # SH
  tg.send(SH, 0, 0x0000ffff)
  tg.recv(0)

  # LW stall
  tg.send(LW, 0)
  tg.wait(1<<4)
  tg.recv(0xffffffff)

  # LW
  tg.send(LW, 0)
  tg.recv(0xffffffff)

  # LM
  tg.send(LM, 0, 0, 0b0000)
  tg.recv(0x00000000)
  tg.send(LM, 0, 0, 0b0001)
  tg.recv(0x000000ff)
  tg.send(LM, 0, 0, 0b0010)
  tg.recv(0x0000ff00)
  tg.send(LM, 0, 0, 0b0101)
  tg.recv(0x00ff00ff)
  tg.send(LM, 0, 0, 0b1000)
  tg.recv(0xff000000)
  tg.send(LM, 0, 0, 0b1001)
  tg.recv(0xff0000ff)
  tg.send(LM, 0, 0, 0b1101)
  tg.recv(0xffff00ff)
  tg.send(LM, 0, 0, 0b0110)
  tg.recv(0x00ffff00)

  # SW
  tg.send(SW, 0, 0)
  tg.recv(0)
  
  # SM
  tg.send(SM, 0, 0xffffffff, 0b1010)
  tg.recv(0)

  # LW
  tg.send(LW, 0)
  tg.recv(0xff00ff00)

  # SM
  tg.send(SM, 0, 0xffffffff, 0b0100)
  tg.recv(0)

  # LW
  tg.send(LW, 0)
  tg.recv(0xffffff00)

  # SM
  tg.send(SM, 0, 0xff00ffff, 0b0111)
  tg.recv(0)
  
  # LW
  tg.send(LW, 0)
  tg.recv(0xff00ffff)

  
  # does it evict the LRU
  # TAGST
  tg.send(TAGST, 0<<14, 0)
  tg.recv(0)
  tg.send(TAGST, 1<<14, 0)
  tg.recv(0)

  tg.send(SW, 3<<14, 0xf3ffffff)
  tg.recv(0)
  tg.send(SW, 2<<14, 0xcfffffff)
  tg.recv(0)
 
  # TAGLA
  tg.send(TAGLA, 0)
  tg.recv(0xc000) 
  tg.send(TAGLA, 1<<14)
  tg.recv(0x8000) 

  # LW
  tg.send(LW, 3<<14)
  tg.recv(0xf3ffffff)

  # SW
  tg.send(SW, 1<<14, 0xfcf00000)
  tg.recv(0)
  
  # TAGLA
  tg.send(TAGLA, 0)
  tg.recv(0xc000)

  # TAGLA
  tg.send(TAGLA, 1<<14)
  tg.recv(0x4000)

  # LW
  tg.send(LW, 3<<14)
  tg.recv(0xf3ffffff)
  
  # SW
  tg.send(SW, 1<<14, 0xfcf00000)
  tg.recv(0)

  # TAGLA
  tg.send(TAGLA, 0)
  tg.recv(0xc000)

  # TAGLA
  tg.send(TAGLA, 1<<14)
  tg.recv(0x4000)

  # LW
  tg.send(LW, 1<<14)
  tg.recv(0xfcf00000)

  # SW
  tg.send(SW, 7<<14, 0xfcf0000f)
  tg.recv(0)

  # TAGLA
  tg.send(TAGLA, 0)
  tg.recv(7<<14)
  
  tg.send(TAGLA, 1<<14)
  tg.recv(1<<14)

  # TAGLV
  tg.send(TAGLV, 0)
  tg.recv(1)
  tg.send(TAGLV, 1<<14)
  tg.recv(1)

  # wait
  tg.wait(1<<4)

  # write buffer works?
  tg.send(SW, 0, 0)
  tg.send(SB, 0, 0xff)
  tg.send(SB, 1, 0xaa)
  tg.send(LW, 0)
  tg.send(LBU, 1)
  tg.send(LHU, 0)

  tg.recv(0) 
  tg.recv(0) 
  tg.recv(0) 
  tg.recv(0xaaff)
  tg.recv(0xaa)
  tg.recv(0xaaff)
  

  # reproducing bug found from bsg_dram_loopback_cache
  #
  
  # TAGST
  tg.send(TAGST, 0, 0)
  tg.recv(0)
  tg.send(TAGST, 1<<14, 0)
  tg.recv(0)

  tg.send(TAGST, 0+(1<<5), 0)
  tg.recv(0)
  tg.send(TAGST, (1<<14) + (1<<5), 0)
  tg.recv(0)

  # store vector (stride 1)
  for i in range(8):
    tg.send(SM, i<<2, i*i, 0b1111)

  for i in range(8):
    tg.send(SM, (1<<14) + (i<<2), 0xffffffff, 0b1111)
  
  for i in range(8):
    tg.send(SM, (2<<14) + (i<<2), 0xeeeeeeee, 0b1111)

  # read
  for i in range(8):
    tg.send(LM, i<<2, 0, 0b1111)
 
  # store vector (stride 2) 
  for i in range(8):
    tg.send(SM, i<<3, i*i, 0b1111)

  for i in range(8):
    tg.send(SM, (1<<14) + (i<<3), 0xffffffff, 0b1111)
  
  for i in range(8):
    tg.send(SM, (2<<14) + (i<<3), 0xeeeeeeee, 0b1111)

  # read
  for i in range(8):
    tg.send(LM, i<<3, 0, 0b1111)
  
  for i in range(8):
    tg.recv(0)

  for i in range(8):
    tg.recv(0)

  for i in range(8):
    tg.recv(0)

  for i in range(8):
    tg.recv(i*i)

  for i in range(8):
    tg.recv(0)

  for i in range(8):
    tg.recv(0)

  for i in range(8):
    tg.recv(0)

  for i in range(8):
    tg.recv(i*i)

  # TAGST
  tg.send(TAGST, (0<<14) + (0<<5), 0)
  tg.recv(0)
  tg.send(TAGST, (1<<14) + (0<<5), 0)
  tg.recv(0)
  tg.send(TAGST, (0<<14) + (1<<5), 0)
  tg.recv(0)
  tg.send(TAGST, (1<<14) + (1<<5), 0)
  tg.recv(0)
  tg.send(TAGST, (0<<14) + (2<<5), 0)
  tg.recv(0)
  tg.send(TAGST, (1<<14) + (2<<5), 0)
  tg.recv(0)
  tg.send(TAGST, (0<<14) + (3<<5), 0)
  tg.recv(0)
  tg.send(TAGST, (1<<14) + (3<<5), 0)
  tg.recv(0)

  # store vector (stride 4)
  for i in range(8):
    tg.send(SM, i<<4, i*i, 0b1111)

  for i in range(8):
    tg.send(SM, (1<<14) + (i<<4), 0xffffffff, 0b1111)

  for i in range(8):
    tg.send(SM, (2<<14) + (i<<4), 0xeeeeeeee, 0b1111)

  for i in range(8):
    tg.send(LM, i<<4,0, 0b1111)
  
  for i in range(8):
    tg.recv(0)

  for i in range(8):
    tg.recv(0)

  for i in range(8):
    tg.recv(0)

  for i in range(8):
    tg.recv(i*i)


  # TAGFL test

  # TAGST
  tg.send(TAGST, 0, 0)
  tg.recv(0)
  tg.send(TAGST, 1<<14, 0)
  tg.recv(0)

  for i in range(8):
    tg.send(SW, i<<2, 1<<(31-i))

  for i in range(8):
    tg.send(SW, (1<<14)+(i<<2), 1<<(23-i))

  for i in range(8):
    tg.recv(0)

  for i in range(8):
    tg.recv(0)

  # TAGFL 
  tg.send(TAGFL, 0)
  tg.recv(0)
  tg.send(TAGFL, 1<<14)
  tg.recv(0)

  # TAGST
  tg.send(TAGST, 0, 0)
  tg.recv(0)
  tg.send(TAGST, 1<<14, 0)
  tg.recv(0)

  # LW
  for i in range(8):
    tg.send(LW, i<<2)

  for i in range(8):
    tg.send(LW, (1<<14)+(i<<2))

  for i in range(16):
    tg.recv(1<<(31-i))



  # AMOSWAP_W test

  # TAGST
  tg.send(TAGST, 0, 0)
  tg.recv(0)
  tg.send(TAGST, 1<<14, 0)
  tg.recv(0)

  tg.send(SW, 0, 123) 
  tg.recv(0)

  tg.send(LW, 0, 123)
  tg.recv(123)
  
  tg.send(AMOSWAP_W, 0, 456)
  tg.recv(123)

  tg.send(LW, 0)
  tg.recv(456)


  # AMOSWAP_W miss
  tg.send(AFLINV, 0)
  tg.recv(0)

  tg.send(AMOSWAP_W, 0, 789)
  tg.recv(456)

  tg.send(LW, 0)
  tg.recv(789)

  # AMOSWAP replacement
  tg.send(SW, 1<<14, 246)  
  tg.recv(0)
  
  tg.send(LW, 1<<14)
  tg.recv(246)

  tg.send(SW, 3<<14, 345)
  tg.recv(0)

  tg.send(LW, 3<<14)
  tg.recv(345)

  tg.send(AMOSWAP_W, 0, 111)
  tg.recv(789)

  tg.send(AMOSWAP_W, 1<<14, 222)
  tg.recv(246)

  tg.send(AMOSWAP_W, 3<<14, 333)
  tg.recv(345)

  tg.send(AMOSWAP_W, 0, 444)
  tg.send(AMOSWAP_W, 1<<14, 555)
  tg.send(AMOSWAP_W, 3<<14, 666)
  tg.send(AMOSWAP_W, 0, 777)
  tg.send(AMOSWAP_W, 1<<14, 888)
  tg.send(AMOSWAP_W, 3<<14, 999)
  
  tg.recv(111)
  tg.recv(222)
  tg.recv(333)
  tg.recv(444)
  tg.recv(555)
  tg.recv(666)

  tg.send(LW, 0)
  tg.send(LW, 1<<14)
  tg.send(LW, 3<<14)
  tg.recv(777)
  tg.recv(888)
  tg.recv(999)

  
  tg.send(SW, 0, 0)
  tg.send(SW, 4, 0)
  tg.recv(0)
  tg.recv(0)
  tg.wait(20)

  tg.send(AMOSWAP_W, 0, 2)
  tg.send(AMOSWAP_W, 0, 3)
  tg.send(AMOSWAP_W, 4, 5)
  tg.send(AMOSWAP_W, 0, 7)
  tg.send(AMOSWAP_W, 0, 11)
  tg.send(AMOSWAP_W, 0, 13)
  tg.send(AMOSWAP_W, 0, 17)

  tg.recv(0)
  tg.recv(2)
  tg.recv(0)
  tg.recv(3)
  tg.recv(7)
  tg.recv(11)
  tg.recv(13)

  # AMOOR
  tg.send(SW, 0, 0)
  tg.recv(0)

  tg.send(AMOOR_W, 0, 0b11)
  tg.recv(0)

  tg.send(AMOOR_W, 0, 0b11111)
  tg.recv(0b11)

  tg.send(AMOOR_W, 0, 0b0)
  tg.recv(0b11111)





  #### DONE ####
  tg.wait(16)
  tg.done()
