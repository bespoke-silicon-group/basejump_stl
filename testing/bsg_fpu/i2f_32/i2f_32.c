/**
 *  i2f_32.c
 *
 *  @author tommy
 *
 *  - input vector (0001)
 *    - signed_i
 *    - a_i
 *
 *  - output vector (0010)
 *    - filler (1-bit)
 *    - z_o
 *
 */

#define RING_WIDTH_P 33 // 32+1
#define DATA_WIDTH_P 32

#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <fenv.h>
#include "fpu_common.h"


void test_signed_i2f_32(int a_i)
{
  // send trace
  printf("0001_1_");
  print_int_in_binary(a_i);
  printf("\n");

  // recv trace  
  printf("0010_0_");   
  float f = (float) a_i;
  print_float_in_binary(f);

  printf("\n");
}

void test_unsigned_i2f_32(uint32_t a_i)
{
  // send trace
  printf("0001_0_");
  print_uint_in_binary(a_i);
  printf("\n");

  // recv trace  
  printf("0010_0_");   
  float f = (float) a_i;
  print_float_in_binary(f);

  printf("\n");
}


int main()
{
  srand(time(NULL));

  for (int i = 0; i < 5000; i++)
  {
    test_signed_i2f_32(randf());
    test_unsigned_i2f_32(rand());
  }

  print_done(RING_WIDTH_P);

  return 0;
}
