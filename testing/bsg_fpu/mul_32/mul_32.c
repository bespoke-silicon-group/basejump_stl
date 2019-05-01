/**
 *  mul_32.c
 *
 *  @author tommy
 *
 *  - input vector (0001)
 *    - a_i
 *    - b_i
 *
 *  - output vector (0010)
 *    - unimplemented
 *    - invalid
 *    - overflow
 *    - underflow
 *    - z_o
 *
 */

#pragma STDC FENV_ACCESS_ON

#define RING_WIDTH_P 64 // 32+32
#define DATA_WIDTH_P 32

#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <fenv.h>
#include "fpu_common.h"

uint32_t calculate_sign(float a_i, float b_i)
{
  return (f2i(a_i) & 0x80000000) ^ (f2i(b_i) & 0x80000000);
}

void test_mul_32(float a_i, float b_i)
{
  // send trace
  printf("0001_");   
  print_float_in_binary(a_i);
  printf("_");
  print_float_in_binary(b_i);
  printf("\n");

  // recv trace  
  uint32_t hex_a = hex(a_i);
  uint32_t hex_b = hex(b_i);
  uint32_t sign = calculate_sign(a_i, b_i);
  bool a_infty = is_infty(a_i);  
  bool b_infty = is_infty(b_i);  
  bool a_denormal = is_denormal(a_i);
  bool b_denormal = is_denormal(b_i);
  bool a_sig_nan = is_sig_nan(a_i);
  bool b_sig_nan = is_sig_nan(b_i);
  bool a_nan = is_nan(a_i);
  bool b_nan = is_nan(b_i);
  bool a_zero = is_zero(a_i);
  bool b_zero = is_zero(b_i);


  int unimplemented = 0;
  int invalid = 0;
  int overflow = 0;
  int underflow = 0;
  float z_o;

  if (a_sig_nan || b_sig_nan)
  {
    invalid = 1;
    z_o = i2f(0x7fbfffff);
  }
  else if (a_nan || b_nan)
  {
    z_o = i2f(0x7fc00000);
  }
  else if (a_infty)
  {
    invalid = b_zero ? 1 : 0;
    z_o = b_zero
      ? i2f(0x7fc00000)
      : i2f(sign | 0x7f800000);
  }
  else if (b_infty)
  {
    invalid = a_zero ? 1 : 0;
    z_o = a_zero
      ? i2f(0x7fc00000)
      : i2f(sign | 0x7f800000);
  }
  else if (a_zero || b_zero)
  {
    z_o = i2f(sign | 0x0);
  }
  else if (a_denormal && b_denormal)
  {
    underflow = 1;
    z_o = i2f(sign | 0x0);
  }
  else if (a_denormal || b_denormal)
  {
    unimplemented = 1;
    z_o = i2f(0x7fc00000);
  }
  else
  {
    feclearexcept(FE_ALL_EXCEPT);
    z_o = a_i * b_i;
    fegetexceptflag((fexcept_t *) &invalid, FE_INVALID);
    fegetexceptflag((fexcept_t *) &overflow, FE_OVERFLOW);
    fegetexceptflag((fexcept_t *) &underflow, FE_UNDERFLOW);

    if (is_denormal(z_o))
    {
      underflow = 1;
      z_o = i2f(sign | 0);
    }
    else if (underflow != 0)
    {
      underflow = 1;
      z_o = i2f(sign | 0);
    }
    else if (overflow != 0)
    {
      overflow = 1;
      z_o = i2f(sign | 0x7f800000);
    }
    else
    {
      invalid = (invalid == 0) ? 0 : 1;
      overflow = (overflow == 0) ? 0 : 1;
      underflow = (underflow == 0) ? 0 : 1;
    }
  } 

  printf("0010_");   
  for (int i = 0; i < RING_WIDTH_P-32-4; i++)
  {
    printf("0");
  }

  printf("_");
  printf("%d", unimplemented);  
  printf("%d", invalid);  
  printf("%d", overflow);  
  printf("%d", underflow);  
  printf("_");
  print_float_in_binary(z_o);
  printf("\n");
}


int main()
{
  srand(time(NULL));

  test_mul_32(2.718281, 3.141592); // e + pi
  test_mul_32(2.718281, 3.141592); // e - pi
  test_mul_32(3.141592, 2.718281); // pi + e
  test_mul_32(3.141592, 2.718281); // pi - e
  test_mul_32(1.42341, 0.09842);

  for (int i = 0; i < 5000; i++)
  {
    float a = randf();
    float b = randf();
    test_mul_32(a,b);
  }


  print_done(RING_WIDTH_P);

  return 0;
}
