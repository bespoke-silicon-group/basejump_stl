/**
 *  int_result_t.c
 *
 *  @author Tommy Jung
 */


#include <stdio.h>
#include "util.h"
#include "int_result_t.h"

void assert_int(int_result_t * ires)
{
  // header
  printf("00100_");

  // padding = 75 - 32 - 4 = 39
  int i;
  for (i = 0; i < 39; i++)
  {
    printf("0");
  }
  printf("_");

  // print exceptions
  printf("%d", ires->unimplemented);
  printf("%d", ires->invalid);
  printf("%d", ires->overflow);
  printf("%d", ires->underflow);
  printf("_");

  print_int_in_binary(ires->z);
  printf("\n");
};
