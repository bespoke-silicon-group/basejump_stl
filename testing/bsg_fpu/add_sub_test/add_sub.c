#include <stdint.h>
#include <float.h>
#include <math.h>
#include <stdio.h>
#include <fenv.h>
#include <stdlib.h>
#include <time.h>
#include "util.h"
#include "float_result_t.h"

#pragma STDC FENV_ACCESS ON

void arrange(float a, float b, int sub_i);
void act(float a, float b, int sub_i, float_result_t *fres);
void assert(float_result_t *fres); 
uint32_t calculate_sign(float a, float b, int sub_i);
void test(float a, float b, int sub_i);

int main()
{
    srand(time(0)); // set random seed
    print_reset();  // print reset trace

    
    for (int i = 0; i < 1000; i++)
    {
        float a = randf();
        float b = randf();
        int sub_i = rand() % 2;
        test(a, b, sub_i);
    } 

    test(itof(0x7fa21dff), itof(0x66f2c522), 1);
    test(itof(0x01a2ec9a), itof(0x01b60418), 1);
    test(itof(0x34561fff), itof(0x34560f00), 0);
    print_done();
    return 0;
}

void test(float a, float b, int sub_i)
{
    float_result_t fres;
    arrange(a, b, sub_i);
    act(a, b, sub_i, &fres);
    assert(&fres);
}

void arrange(float a, float b, int sub_i)
{
    // header
    printf("00010_");

    // padding = 75 - 64 - 1 = 10
    printf("0000000000_");

    //sub_i
    printf("%d_", sub_i);
    // print a
    print_float_in_binary(a);
    printf("_");

    // print b
    print_float_in_binary(b);
    printf("\n");
}


void act(float a, float b, int sub_i, float_result_t *fres)
{
    int sign = calculate_sign(a, b, sub_i);
    int sub_mag = (ftoi(a) & 0x80000000) ^ (ftoi(a) & 0x80000000) ^ (sub_i << 31);

    if (is_sig_nan(a) || is_sig_nan(b))
    {
        fres->unimplemented = 0; 
        fres->invalid = 1; 
        fres->overflow = 0;
        fres->underflow = 0;
        fres->z = itof(sign | 0x7fbfffff); // signan
    }
    else if (isnan(a) || isnan(b))
    {
        fres->unimplemented = 0; 
        fres->invalid = 0; 
        fres->overflow = 0;
        fres->underflow = 0;
        fres->z = itof(sign | 0x7fffffff); // quiet nan
    }
    else if (is_infty(a) && is_infty(b))
    {
        fres->unimplemented = 0; 
        fres->invalid = 0; 
        fres->overflow = 0;
        fres->underflow = 0;
        fres->z = (sub_mag == 0)
            ? itof(sign | 0x7f800000)  // infinite
            : itof(sign | 0x7fffffff); // quiet NaN
    }
    else if (is_infty(a) && !is_infty(b))
    {
        fres->unimplemented = 0; 
        fres->invalid = 0; 
        fres->overflow = 0;
        fres->underflow = 0;
        fres->z = itof(sign | 0x7f800000);
    }
    else if (!is_infty(a) && is_infty(b))
    {
        fres->unimplemented = 0; 
        fres->invalid = 0; 
        fres->overflow = 0;
        fres->underflow = 0;
        fres->z = itof(sign | 0x7f800000);
    }
    else if (is_denormal(a) || is_denormal(b))
    {
        
        fres->unimplemented = 1; 
        fres->invalid = 0; 
        fres->overflow = 0;
        fres->underflow = 0;
        fres->z = itof(sign | 0x7fffffff);
    }
    else
    {
        // clear exception flags. 
        if (feclearexcept(FE_ALL_EXCEPT) != 0)
        {
            printf("failed to clear floating point exception.\n");
        }

        float z = (sub_i == 1)
            ? a - b
            : a + b;
        
        int invalid = 0;
        int overflow = 0;
        int underflow = 0;

        // grab exception flags
        checkError(fegetexceptflag((fexcept_t *) &invalid, FE_INVALID));
        checkError(fegetexceptflag((fexcept_t *) &overflow, FE_OVERFLOW));
        checkError(fegetexceptflag((fexcept_t *) &underflow, FE_UNDERFLOW));
       
        if (is_denormal(z)) 
        {
            fres->unimplemented = 0;
            fres->invalid = 0; 
            fres->overflow = 0;
            fres->underflow = 1;
            fres->z = itof(sign | 0);
        }
        else if (underflow != 0)
        {
            fres->unimplemented = 0;
            fres->invalid = 0; 
            fres->overflow = 0;
            fres->underflow = 1;
            fres->z = itof(sign | 0);
        }
        else if (overflow != 0)
        {
            fres->unimplemented = 0;
            fres->invalid = 0; 
            fres->overflow = 1;
            fres->underflow = 0;
            fres->z = itof(sign | 0x7f800000);
        }
        else
        {
            fres->unimplemented = 0;
            fres->invalid = invalid; 
            fres->overflow = overflow;
            fres->underflow = underflow;
            fres->z = z;
        }
    }
}



uint32_t calculate_sign(float a, float b, int sub_i)
{
    // calculate sign
    uint32_t sign = 0;
    uint32_t hex_a = hex(a);
    uint32_t hex_b = hex(b);
    uint32_t a_sign = hex_a & 0x80000000;
    uint32_t b_sign = hex_b & 0x80000000;
    uint32_t a_abs = hex_a & 0x7fffffff;
    uint32_t b_abs = hex_b & 0x7fffffff;

    if (a_sign == 0 && b_sign == 0)
    {
        if (a_abs >= b_abs) 
            sign = 0;
        else
            sign = sub_i == 0 ? 0 : 0x80000000;
    }
    else if (a_sign == 0 && b_sign == 0x80000000)
    {
        if (a_abs >= b_abs)
            sign = 0;
        else
            sign = sub_i == 0 ? 0x80000000 : 0;
    }
    else if (a_sign == 0x80000000 && b_sign == 0)
    {
        if (a_abs >= b_abs)
            sign = 0x80000000;
        else
            sign = sub_i == 0 ? 0 : 0x80000000;
    }
    else
    {
        if (a_abs >= b_abs)
            sign = 0x80000000;
        else
            sign = sub_i == 0 ? 0x80000000 : 0;
    }
    
    return sign;
}
