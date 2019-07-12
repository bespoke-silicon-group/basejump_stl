/**
 *  cmp_32.c
 *
 *  @author tommy
 *
 *  - input vector (0001)
 *    - 000 (filler)
 *    - a_i
 *    - b_i
 *
 *  - output vector (0010)
 *    - eq_o
 *    - lt_o
 *    - le_o
 *    - min_o
 *    - max_o
 *
 */

#define RING_WIDTH_P 67 // 32+32+3
#define DATA_WIDTH_P 32

#include <stdbool.h>
#include <stdio.h>
#include <fenv.h>
#include <time.h>
#include <stdlib.h>
#include "fpu_common.h"


void test_cmp_32(float a_i, float b_i)
{
  // send trace
  printf("0001_");   
  printf("000_");   
  print_float_in_binary(a_i);
  printf("_");
  print_float_in_binary(b_i);
  printf("\n");

  // recv trace  
  printf("0010_");   
  printf("%d", a_i == b_i);   // eq
  printf("%d", a_i < b_i);   // lt
  printf("%d", a_i <= b_i);   // le
  printf("_");   

  float min_o;
  float max_o;
  if (is_nan(a_i) && is_nan(b_i))
  {
    min_o = NAN;
    max_o = NAN;
  }
  else if (is_nan(a_i) && !is_nan(b_i))
  {
    min_o = b_i;
    max_o = b_i;
  }
  else if (!is_nan(a_i) && is_nan(b_i))
  {
    min_o = a_i;
    max_o = a_i;
  }
  else if (is_zero(a_i) && is_zero(b_i))
  {
    min_o = 0;
    max_o = 0;
  }
  else
  {
    min_o = a_i < b_i ? a_i : b_i;
    max_o = a_i < b_i ? b_i : a_i;
  }

  print_float_in_binary(min_o); // min
  printf("_");   
  print_float_in_binary(max_o); // min

  printf("\n");
}


int main()
{
  srand(time(NULL));

  test_cmp_32(2.718281, 3.141592); // e, pi
  test_cmp_32(2.718281, -3.141592); // e, -pi
  test_cmp_32(-2.718281, 3.141592); // -e, pi
  test_cmp_32(-2.718281, -3.141592); // -e, -pi

  test_cmp_32(3.141592, 2.718281); // pi, e
  test_cmp_32(3.141592, -2.718281); // pi, -e
  test_cmp_32(-3.141592, 2.718281); // -pi, e
  test_cmp_32(-3.141592, -2.718281); // -pi, -e

  test_cmp_32(-3.141592, -3.141592); // -pi, -e
  test_cmp_32(3.141592, 3.141592); // pi, e
  test_cmp_32(-3.141592, 3.141592); // -pi, e
  test_cmp_32(3.141592, -3.141592); // pi, -e

  test_cmp_32(0.0, 0.0);
  test_cmp_32(0.0, -0.0);
  test_cmp_32(-0.0, 0.0);
  test_cmp_32(-0.0, -0.0);

  test_cmp_32(NAN, 1000.99999);
  test_cmp_32(1000.99999, NAN);
  test_cmp_32(NAN, NAN);

  test_cmp_32(NAN, -1000.99999);
  test_cmp_32(-1000.99999, NAN);
  test_cmp_32(-NAN, -NAN);

  test_cmp_32(snanf(), 123.123);
  test_cmp_32(123.123, snanf());
  test_cmp_32(snanf(), snanf());

  test_cmp_32(snanf(), -123.123);
  test_cmp_32(-123.123, snanf());
  test_cmp_32(snanf(), snanf());

  test_cmp_32(NAN, snanf());
  test_cmp_32(snanf(), NAN);

  test_cmp_32(-NAN, snanf());
  test_cmp_32(snanf(), -NAN);

  test_cmp_32(NAN, -snanf());
  test_cmp_32(-snanf(), NAN);

  test_cmp_32(0, NAN);
  test_cmp_32(NAN, 0);
  test_cmp_32(0, snanf());
  test_cmp_32(snanf(), 0);
  test_cmp_32(0, -NAN);
  test_cmp_32(-NAN, 0);
  test_cmp_32(0, -snanf());
  test_cmp_32(-snanf(), 0);

  test_cmp_32(-0, NAN);
  test_cmp_32(NAN, -0);
  test_cmp_32(-0, snanf());
  test_cmp_32(snanf(), -0);
  test_cmp_32(0, -NAN);
  test_cmp_32(-NAN, 0);
  test_cmp_32(0, -snanf());
  test_cmp_32(-snanf(), 0);

  test_cmp_32(infty(), 3.141592);
  test_cmp_32(3.141592, infty());

  test_cmp_32(-infty(), 3.141592);
  test_cmp_32(3.141592, -infty());

  test_cmp_32(-infty(), infty());
  test_cmp_32(infty(), -infty());

  test_cmp_32(infty(), NAN);
  test_cmp_32(NAN, infty());

  test_cmp_32(infty(), snanf());
  test_cmp_32(snanf(), infty());

  for (int i = 0; i < 500; i++)
  {
    float a = randf();
    test_cmp_32(a,a);
  }


  for (int i = 0; i < 5000; i++)
  {
    float a = randf();
    float b = randf();
    test_cmp_32(a,b);
  }

  print_done(RING_WIDTH_P);

  return 0;
}
