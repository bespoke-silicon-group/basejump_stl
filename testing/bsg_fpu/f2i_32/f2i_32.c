/**
 *  f2i_32.c
 *
 *  @author tommy
 *
 *  - input vector (0001)
 *    - signed_i (1-bit)
 *    - a_i
 *
 *  - output vector (0010)
 *    - invalid_o
 *    - z_o
 *
 */

#define RING_WIDTH_P 33 // 32+1
#define DATA_WIDTH_P 32

#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <fenv.h>
#include <limits.h>
#include <time.h>
#include "fpu_common.h"


void test_signed_f2i_32(float a_i)
{
  // send trace
  printf("0001_1_");   
  print_float_in_binary(a_i);
  printf("\n");

  // recv trace  
  int z_lo;
  int invalid;

  if (is_nan(a_i))
  {
    z_lo = 0;
    invalid = 1;
  }
  else if (a_i > (float) INT_MAX)
  {
    z_lo = 0x7fffffff;
    invalid = 1;
  }
  else if (a_i < (float) INT_MIN)
  {
    z_lo = 0x80000000;
    invalid = 1;
  }
  else
  {
    z_lo = (int) a_i;
    invalid = 0;
  }

  printf("0010_");
  printf("%d_", invalid);   
  print_int_in_binary(z_lo);
  printf("\n");
}

void test_unsigned_f2i_32(float a_i)
{
  // send trace
  printf("0001_0_");   
  print_float_in_binary(a_i);
  printf("\n");

  // recv trace  
  uint32_t z_lo;
  int invalid;

  if (a_i < 0.0)
  {
    z_lo = 0;
    invalid = 1;
  }
  else if (is_nan(a_i))
  {
    z_lo = 0;
    invalid = 1;
  }
  else if (a_i > (float) UINT_MAX)
  {
    z_lo = 0x7fffffff;
    invalid = 1;
  }
  else
  {
    z_lo = (uint32_t) a_i;
    invalid = 0;
  }

  printf("0010_");   
  printf("%d_", invalid);
  print_uint_in_binary(z_lo);
  printf("\n");
}

int main()
{
  test_signed_f2i_32(0);
  test_unsigned_f2i_32(0);
  test_signed_f2i_32(-0);
  test_unsigned_f2i_32(-0);

  test_signed_f2i_32(infty());
  test_unsigned_f2i_32(infty());
  test_signed_f2i_32(-infty());
  test_unsigned_f2i_32(-infty());

  test_signed_f2i_32(infty());
  test_unsigned_f2i_32(infty());
  test_signed_f2i_32(-infty());
  test_unsigned_f2i_32(-infty());

  test_signed_f2i_32(NAN);
  test_unsigned_f2i_32(NAN);
  test_signed_f2i_32(-NAN);
  test_unsigned_f2i_32(-NAN);

  test_signed_f2i_32(3.141592);
  test_unsigned_f2i_32(3.141592);
  test_signed_f2i_32(-3.141592);
  test_unsigned_f2i_32(-3.141592);

  test_signed_f2i_32(100.141592);
  test_unsigned_f2i_32(100.141592);
  test_signed_f2i_32(-100.141592);
  test_unsigned_f2i_32(100.141592);

  test_signed_f2i_32(1.5);
  test_unsigned_f2i_32(1.5);
  test_signed_f2i_32(-1.5);
  test_unsigned_f2i_32(-1.5);

  test_signed_f2i_32(0.5);
  test_unsigned_f2i_32(0.5);
  test_signed_f2i_32(-0.5);
  test_unsigned_f2i_32(-0.5);

  test_signed_f2i_32(14.5);
  test_unsigned_f2i_32(14.5);
  test_signed_f2i_32(-14.5);
  test_unsigned_f2i_32(-14.5);

  test_signed_f2i_32(0.99);
  test_unsigned_f2i_32(0.99);
  test_signed_f2i_32(-0.99);
  test_unsigned_f2i_32(-0.99);
  
  test_signed_f2i_32(1111.5);
  test_unsigned_f2i_32(1111.5);
  test_signed_f2i_32(-1111.5);
  test_unsigned_f2i_32(-1111.5);

  test_signed_f2i_32(5235346.577);
  test_unsigned_f2i_32(5235346.577);
  test_signed_f2i_32(-5235346.577);
  test_unsigned_f2i_32(-5235346.577);

  test_signed_f2i_32  ( 95831300.0577);
  test_unsigned_f2i_32( 95831300.0577);
  test_signed_f2i_32  (-95831300.0577);
  test_unsigned_f2i_32(-95831300.0577);

  test_signed_f2i_32  ( 595831300.0577);
  test_unsigned_f2i_32( 595831300.0577);
  test_signed_f2i_32  (-595831300.0577);
  test_unsigned_f2i_32(-595831300.0577);

  test_signed_f2i_32  (2.22007);
  test_unsigned_f2i_32(2.22007);
  test_signed_f2i_32  (-2.22007);
  test_unsigned_f2i_32(-2.22007);

  test_signed_f2i_32  (12.52017);
  test_unsigned_f2i_32(12.52017);
  test_signed_f2i_32  (-12.52017);
  test_unsigned_f2i_32(-12.52017);

  test_signed_f2i_32  (1.0001);
  test_unsigned_f2i_32(1.0001);
  test_signed_f2i_32  (-1.0001);
  test_unsigned_f2i_32(-1.0001);

  test_signed_f2i_32(i2f(0x612782ef));
  test_signed_f2i_32(i2f(0xe12782ef));
  test_signed_f2i_32(i2f(0x7f7fc2ef));
  test_signed_f2i_32(i2f(0xff7fc2ef));
  test_unsigned_f2i_32(i2f(0x612782ef));
  test_unsigned_f2i_32(i2f(0x612782ef));
  test_unsigned_f2i_32(i2f(0x7f7fc2ef));
  test_unsigned_f2i_32(i2f(0xff7fc2ef));

  test_signed_f2i_32(i2f(0x0ff9579f));
  test_unsigned_f2i_32(i2f(0x0ff9579f));
  test_unsigned_f2i_32(i2f(0x4f5079fa));

  srand(time(NULL));
  for (int i = 0; i < 5000; i++)
  {
    test_signed_f2i_32(randf());
    test_unsigned_f2i_32(randf());
  }

  print_done(RING_WIDTH_P);
  return 0;
}
