#include <stdint.h>
#include <math.h>
#include <stdio.h>
#include <fenv.h>
#include <stdlib.h>
#include <time.h>
#include "util.h"
#include "float_result_t.h"

#pragma STDC FENV_ACCESS ON

void arrange(float a, float b);
void act(float a, float b, float_result_t *fres);
void assert(float_result_t *fres); 
uint32_t calculate_sign(float a, float b);
void test(float a, float b);


int main()
{
    // RESET
    print_reset();

    srand(time(0));
    printf("#### TEST BEGIN ####\n");

    int i;
    for (i = 0; i < 1000; i++)
    {
        test(randf(), randf());
    }

    // DONE
    print_done(); 
    return 0;
}

void test(float a, float b)
{
    float_result_t fres;
    arrange(a, b);
    act(a, b, &fres);
    assert(&fres);
}


void arrange(float a, float b)
{
    // header
    printf("00010_");

    // padding = 75 - 64  = 11
    printf("00000000000_");

    // print a
    print_float_in_binary(a);
    printf("_");

    // print b
    print_float_in_binary(b);
    printf("\n");
}

void act(float a, float b, float_result_t *fres)
{
    int sign = calculate_sign(a, b);
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
    else if (is_infty(a))
    {
        fres->unimplemented = 0; 
        fres->invalid = (b == 0) ? 1 : 0; 
        fres->overflow = 0;
        fres->underflow = 0;
        fres->z = (b == 0)
            ? itof(sign | 0x7fffffff)
            : itof(sign | 0x7f800000); // quiet nan
    }
    else if (is_infty(b))
    {
        fres->unimplemented = 0; 
        fres->invalid = (a == 0) ? 1 : 0; 
        fres->overflow = 0;
        fres->underflow = 0;
        fres->z = (a == 0)
            ? itof(sign | 0x7fffffff)
            : itof(sign | 0x7f800000); // quiet nan
    }
    else if (a == 0 || b == 0)
    {
        fres->unimplemented = 0; 
        fres->invalid = 0; 
        fres->overflow = 0;
        fres->underflow = 0;
        fres->z = 0;
    }
    else if (is_denormal(a) && is_denormal(b))
    {
        fres->unimplemented = 0; 
        fres->invalid = 0; 
        fres->overflow = 0;
        fres->underflow = 1;
        fres->z = 0;
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

        float z = a * b;
        
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

uint32_t calculate_sign(float a, float b)
{
    return (ftoi(a) & 0x80000000) ^ (ftoi(b) & 0x80000000);
}


