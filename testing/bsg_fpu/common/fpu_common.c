/**
 *  fpu_common.c
 *
 *  @author tommy
 */

#include <stdio.h>
#include "fpu_common.h"

void print_done(int ring_width_p)
{
  printf("#### DONE ####\n");
  printf("0011_");

  for (int i = 0; i < ring_width_p; i++)
  {
    printf("0");
  }

  printf("\n");
}

void print_float_in_binary(float f)
{
  uint32_t fl = hex(f);
  for (int i = 0; i < 32; i++)
  {
    printf("%d", (fl >> (31-i)) & 0x1);
  }
}

void print_int_in_binary(int i)
{
  for (int j = 0; j < 32; j++)
  {
    printf("%d", (i >> (31-j)) & 0x1);
  }
}

void print_uint_in_binary(uint32_t i)
{
  for (int j = 0; j < 32; j++)
  {
    printf("%d", (i >> (31-j)) & 0x1);
  }
}

bool is_sig_nan(float f)
{
  uint32_t hex_f = hex(f);
  return isnan(f) && ((hex_f & 0x00400000) == 0x00000000);
}

bool is_nan(float f)
{
  return isnan(f);
} 

bool is_infty(float f)
{
  uint32_t hex_f = hex(f);
  return ((hex_f & 0x7f800000) == 0x7f800000) && ((hex_f & 0x007fffff) == 0);
}

bool is_denormal(float f)
{
  uint32_t hex_f = hex(f);
  return ((hex_f & 0x7f800000) == 0) && ((hex_f & 0x007fffff) != 0);
}

bool is_zero(float f)
{
  uint32_t hex_f = hex(f);
  return (hex_f & 0x7fffffff) == 0x0;
}

float i2f(uint32_t i)
{
  uint32_t temp = i;
  return flt(temp);
}


uint32_t f2i(float f)
{
  float temp = f;
  return hex(temp);
}

float snanf()
{
  uint32_t temp = 0x7fb00000;
  return i2f(temp);
}


float infty()
{
  uint32_t temp = 0x7f800000;
  return i2f(temp);
}

float randf()
{
  uint32_t temp = ((rand() << 16) & 0xffff0000) | (rand() & 0x0000ffff);
  return flt(temp);
}
