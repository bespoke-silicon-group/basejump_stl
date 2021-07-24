#include <verilated.h>
#include <iostream>
#include "Vbsg_mem_1rw_sync_mask_write_bit_from_1r1w.h"
#include <bits/stdc++.h>
#include <cmath>

using namespace std;

//#define ELS_P   34
#define ADDR_WIDTH_P (int)ceil(log2(ELS_P))
//#define WIDTH_P 12
//#define RUNTIME 100000

Vbsg_mem_1rw_sync_mask_write_bit_from_1r1w *top;
vluint64_t main_time = 0;

int main(int argc, char** argv) {
  Verilated::commandArgs(argc, argv);

  top = new Vbsg_mem_1rw_sync_mask_write_bit_from_1r1w;
  top->reset_i = 0;

  long int mem[ELS_P];
  for(int i = 0; i < ELS_P; i++) 
    mem[i] = 0;

  int v, w;
  long int addr, data, mask;
  long int prev_addr = 0;
  long int prev_data = 0;
  long int prev_mask = 0;
  int prev_v = 0;
  int prev_w = 0;

  long int expect = 0;
  while (main_time < RUNTIME) {
    main_time++;

    top->clk_i = ~top->clk_i;

    if(!top->clk_i) {
      if (main_time > 10) {
        if(prev_v) {
          if(prev_w) {
            mem[prev_addr] = (mem[prev_addr] & ~prev_mask) | (prev_data & prev_mask);
            printf("Writing %08lx to %08lx\n", mem[prev_addr], prev_addr);
          } else {
            expect = mem[prev_addr];
            printf("Expect to read %08lx from %08lx\n", mem[prev_addr], prev_addr);
            printf("%s", (expect != top->data_o) ? 
            "\n\n\n*****************************ERROR****************************\n\n\n" : "");
          }
        }
        top->reset_i = 1;
        //if(v) {
          printf("#%08ld: %s | %s |", main_time, top->v_i ? "v" : " ", top->w_i ? "w" : "r");
          printf(" addr_i: %08lx | data_i: %0*lx | w_mask_i: %0*lx |", (long int)(top->addr_i), WIDTH_P/4, top->data_i, WIDTH_P/4, top->w_mask_i);
          if(prev_v && !prev_w)
            printf(" data_o: %08lx | expected: %08lx\n", top->data_o, expect);
          else printf("\n");
        //}        
        int hazard = rand()%2;
        addr = hazard ? prev_addr : rand()%ELS_P;
        data = (long int)(rand())%((long int)(1) << WIDTH_P);
        mask = (long int)(rand())%((long int)(1) << WIDTH_P);
        mask = mask == 0 ? 1 : mask;
        v = rand()%2;
        w = rand()%2;
        top->v_i = v;
        top->w_i = w;
        top->addr_i = addr;
        top->data_i = data;
        top->w_mask_i = mask;
        if(v) {
          prev_addr = addr;
          prev_data = data;
          prev_mask = mask;
          prev_v = v;
          prev_w = w;
        }
      }    
    }

    top->eval();
  }
  top->final();
  delete top;
}
