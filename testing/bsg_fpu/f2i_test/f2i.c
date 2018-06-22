#include <stdint.h>
#include <math.h>
#include <stdio.h>
#include <fenv.h>
#include <stdlib.h>
#include <time.h>
#include "util.h"
#include <float.h>
#include "int_result_t.h"

#pragma STDC FENV_ACCESS ON

void test(float f);
void arrange(float f);
void act(float f, int_result_t *ires);

int main()
{
  print_reset();
  srand(time(0));
  printf("#### TEST BEGIN ####\n");
  
  // test cases
  test(12.3);
  test(-12.3);

  int r = round(12.3);
  printf("%d\n",r );
  r = round(12.7);
  printf("%d\n",r );
  r = round(13.4);
  printf("%d\n",r );
  r = round(13.5);
  printf("%d\n",r );
  r = round(12.5);
  printf("%d\n",r );

  // DONE
  print_done(); 
  return 0;
}

void test(float f)
{
  int_result_t ires;
  arrange(f);
  act(f, &ires);
  assert_int(&ires);
}

void arrange(float f)
{
  // header
  printf("00010_");

  // padding = 75 - 64  = 11
  printf("00000000000_");

  // padding #2
  printf("00000000000000000000000000000000_");
  
  // print a
  print_float_in_binary(f);
  printf("\n");
}

void act(float f, int_result_t *ires)
{
  ires->unimplemented = 0;
  ires->invalid = 0;
  ires->overflow = 0;
  ires->underflow = 0;
  ires->z = (int) f;
}
