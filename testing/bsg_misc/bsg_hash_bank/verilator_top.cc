#include <stdlib.h>
#include "Vtb.h"
#include "verilated.h"

int main(int argc, char **argv) {
  // Initialize Verilators variables
  Verilated::commandArgs(argc, argv);

  // Create an instance of our module under test
  Vtb *tb = new Vtb;

  // Tick the clock until we are done
  while(!Verilated::gotFinish()) {
    tb->clk = 1;
    tb->eval();
    tb->clk = 0;
    tb->eval();
  } exit(EXIT_SUCCESS);
}
