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
  return ((hex_f & 0x7f800000) == 0x7f800000) && (hex_f & 0x007fffff == 0);
}

bool is_denormal(float f)
{
  uint32_t hex_f = hex(f);
  return ((hex_f & 0x7f800000) == 0) && ((hex_f & 0x007fffff) != 0);
}

float i2f(uint32_t i)
{
  uint32_t temp = i;
  return flt(temp);
}
