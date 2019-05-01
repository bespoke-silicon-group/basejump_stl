/**
 *  add_sub_32.c
 *
 *  @author tommy
 *
 *  - input vector (0001)
 *    - sub_i
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

#define RING_WIDTH_P 65 // 32+32+1
#define DATA_WIDTH_P 32

#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <fenv.h>
#include "fpu_common.h"

uint32_t calculate_sign(bool sub_i, float a_i, float b_i)
{
  bool sign;

  uint32_t hex_a = hex(a_i);
  uint32_t hex_b = hex(b_i);
  uint32_t a_sign = hex_a & 0x80000000;
  uint32_t b_sign = hex_b & 0x80000000;
  uint32_t a_abs = hex_a & 0x7fffffff;
  uint32_t b_abs = hex_b & 0x7fffffff;

  if (a_sign == 0 && b_sign == 0)
  {
    if (a_abs >= b_abs)
      sign = false;
    else
      sign = sub_i;
  }
  else if (a_sign == 0 && b_sign == 0x80000000)
  {
    if (a_abs >= b_abs)
      sign = false;
    else
      sign = !sub_i;
  }
  else if (a_sign == 0x80000000 && b_sign == 0)
  {
    if (a_abs >= b_abs)
      sign = true;
    else
      sign = sub_i;
  }
  else
  {
    if (a_abs >= b_abs)
      sign = true;
    else
      sign = !sub_i;
  }

  return (sign ? 0x80000000 : 0x00000000);
}

void test_add_sub_32(uint32_t sub_i, float a_i, float b_i)
{
  // send trace
  printf("0001_");   
  printf("%d_", sub_i ? 1 : 0);
  print_float_in_binary(a_i);
  printf("_");
  print_float_in_binary(b_i);
  printf("\n");

  // recv trace  
  uint32_t hex_a = hex(a_i);
  uint32_t hex_b = hex(b_i);
  uint32_t sign = calculate_sign(sub_i, a_i, b_i);
  uint32_t sub_mag = (hex_a & 0x80000000) ^ (hex_b & 0x80000000) ^ (sub_i << 31);
  bool a_infty = is_infty(a_i);  
  bool b_infty = is_infty(b_i);  
  bool a_denormal = is_denormal(a_i);
  bool b_denormal = is_denormal(b_i);
  bool a_sig_nan = is_sig_nan(a_i);
  bool b_sig_nan = is_sig_nan(b_i);
  bool a_nan = is_nan(a_i);
  bool b_nan = is_nan(b_i);


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
  else if (a_infty && b_infty)
  {
    z_o = (sub_mag == 0) 
      ? i2f(0x7fc00000)
      : i2f(sign | 0x7fffffff);
  }
  else if (a_infty && !b_infty)
  {
    z_o = i2f(sign | 0x7f800000);
  }
  else if (!a_infty && b_infty)
  {
    z_o = i2f(sign | 0x7f800000);
  }
  else if (a_denormal || b_denormal)
  {
    unimplemented = 1;
    z_o = i2f(0x7fc00000);
  }
  else
  {
    feclearexcept(FE_ALL_EXCEPT);
    z_o = sub_i
      ? a_i - b_i
      : a_i + b_i;
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
  //srand(0);

  test_add_sub_32(0, 2.718281, 3.141592); // e + pi
  test_add_sub_32(1, 2.718281, 3.141592); // e - pi
  test_add_sub_32(0, 3.141592, 2.718281); // pi + e
  test_add_sub_32(1, 3.141592, 2.718281); // pi - e
  test_add_sub_32(0, 17.4237741, 0.009842);
  test_add_sub_32(0, 7777771.42341, 0.09842);
  test_add_sub_32(0, 14444.42341, 0.00009842);
  test_add_sub_32(0, 63751.42341, 1424.02359842);
  test_add_sub_32(0, 134.13111111, 2222.0229842);
  test_add_sub_32(0, 0.000042341, 505.0955842);

  for (int i = 0; i < 2500; i++)
  {
    int add_or_sub = rand() % 2;
    float a = randf();
    float b = randf();
    test_add_sub_32(add_or_sub, a, b); // e + pi
    
  }

  print_done(RING_WIDTH_P);

  return 0;
}
