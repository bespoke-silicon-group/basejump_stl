/**
 *  util.c
 *
 *  @author Tommy Jung
 */

#include "util.h"

/**
 *  return random float.
 */
float randf()
{
    int i = rand();
    return *(float *) &i; 
}

/**
 *  print float in binary string to stdout.
 */
void print_float_in_binary(float a)
{
    int fl = *(int *)&a;
    for (int i = 0; i < 32; i++)
    {
        printf("%d", (fl >> (31-i)) & 0x1);
    }
}

void print_int_in_binary(int a)
{
  for (int i = 0; i < 32; i++)
  {
    printf("%d", (a >> (31-i)) & 0x1);
  }
}

void write_float_in_binary(FILE *fp, float a)
{
  char fs[32];
  
  for (int i = 0; i < 32; i++) 
  {
    
  }
  
  fputs(, fp);
}


/**
 *  print reset trace.
 */
void print_reset()
{
    printf("#### RESET ####\n");
    printf("00011000011000000000000000000000000000000000000000000000000000000000000000000000\n");
    printf("00011000001000000000000000000000000000000000000000000000000000000000000000000000\n");
}


/**
 *  print done trace.
 */
void print_done()
{
    printf("#### DONE ####\n");        
    printf("00110000000000000000000000000000000000000000000000000000000000000000000000000000\n");
}

/**
 *  return true if this float is denormal.
 */
bool is_denormal(float a)
{
    int aa = hex(a);
    return ((aa & 0x7f800000) == 0) && ((aa & 0x007fffff) != 0);
}

/**
 *  exit if error code returned is non-zero.
 */
void checkError(int i)
{
    if (i != 0) {
        printf("error code: %d\n", i);
        exit(i);
    }
}

/**
 *  return true if this float is signaling NaN.
 */
bool is_sig_nan(float a)
{
    int ai = hex(a);
    return isnan(a) && ((ai & 0x00400000) == 0x00000000);
}

/**
 * convert int to float (bit-wise).
 */
float itof(int a)
{
    int temp = a;
    return flt(temp);
}

/**
 *  convert float to int bit-wise).
 */
int ftoi(float a)
{
    float temp = a;
    return hex(temp);
}

/**
 *  return true if infinite.
 */
bool is_infty(float a)
{
    return (ftoi(a) & 0x7f800000) == 0x7f800000 && (ftoi(a) & 0x007fffff == 0);
}


/**
 *  linspace like from numpy. 
 */
void linspace(float *buf, float min, float max, int n)
{
    float step = (max - min) / ((float) (n - 1));
    for (int i = 0; i < n; i++)
    {
        buf[i] = min + i*step;
    }
}


