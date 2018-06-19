#include <stdint.h>
#include <math.h>
#include <stdio.h>
#include <fenv.h>
#include <stdlib.h>
#include <time.h>
#include "util.h"
#include "float_result_t.h"

#pragma STDC FENV_ACCESS ON

void test(int i);
void arrange(int i);
void act(int i, float_result_t *fres);
uint32_t calculate_sign(float a, float b);

int main()
{
  print_reset();
  srand(time(0));
  printf("#### TEST BEGIN ####\n");

  // test cases
  test(0);
  test(1);
  test(-1);
  test(3);
  test(-3);
  test(123);
  test(-123);
  test(8888);
  test(-8888);
  test(88153);
  test(-88153);
  test(96638153);
  test(-96638153);
  test(96638153);
  test(-96638153);
  test(133355537);
  test(-133355537);
  test(2147483647);
  test(-2147483648);

  // DONE
  print_done(); 
  return 0;
}

void test(int i)
{
  float_result_t fres;
  arrange(i);
  act(i, &fres);
  assert(&fres);
}

void arrange(int i)
{
  // header
  printf("00010_");

  // padding = 75 - 64  = 11
  printf("00000000000_");

  // padding #2
  printf("00000000000000000000000000000000_");
  
  // print a
  print_int_in_binary(i);
  printf("\n");
}

void act(int i, float_result_t *fres)
{
  fres->unimplemented = 0;
  fres->invalid = 0;
  fres->overflow = 0;
  fres->underflow = 0;
  fres->z = (float) i;
}
