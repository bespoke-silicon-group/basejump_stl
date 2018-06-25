#pragma STDC FENV_ACCESS ON

#include <cstdint>
#include <float.h>
#include <math.h>
#include <iostream>
#include <fstream>
#include <cfenv>
#include <cstdlib>
#include "FloatResult.hpp"
#include "FPUTestUtil.hpp"
using namespace std;

#define NUM_TEST 10000

void arrange(float a, float b, int sub_i);
void act(float a, float b, int sub_i, FloatResult* fres);
void assert(FloatResult *fres); 
uint32_t calculate_sign(float a, float b, int sub_i);
void test(float a, float b, int sub_i);

ofstream inputROM;
ofstream outputROM;

int main()
{
  srand(time(0)); // set random seed
  
  inputROM.open("add_sub_32_input.rom");
  outputROM.open("add_sub_32_output.rom");  
    
  for (int i = 0; i < NUM_TEST; i++)
  {
    float a = FPUTestUtil::randf();
    float b = FPUTestUtil::randf();
    int sub_i = rand() % 2;
    test(a, b, sub_i);
  }

  inputROM.close();
  outputROM.close(); 

  return 0;
}

void test(float a, float b, int sub_i)
{
    FloatResult fres;
    arrange(a, b, sub_i);
    act(a, b, sub_i, &fres);
    assert(&fres);
}

void arrange(float a, float b, int sub_i)
{
    inputROM << sub_i << "_";
    inputROM << FPUTestUtil::ConvertToBinaryString(a) << "_";
    inputROM << FPUTestUtil::ConvertToBinaryString(b) << endl;
}


void act(float a, float b, int sub_i, FloatResult *fres)
{
    int sign = calculate_sign(a, b, sub_i);
    int hex_a = FPUTestUtil::ConvertFloatToInt(a);
    int hex_b = FPUTestUtil::ConvertFloatToInt(b);
    int sub_mag = (hex_a & 0x80000000) ^ (hex_b & 0x80000000) ^ (sub_i << 31);
    bool a_infty = FPUTestUtil::IsInfty(a);
    bool b_infty = FPUTestUtil::IsInfty(b);
    bool a_denormal = FPUTestUtil::IsDenormal(a);
    bool b_denormal = FPUTestUtil::IsDenormal(b);

    if (FPUTestUtil::IsSigNaN(a) || FPUTestUtil::IsSigNaN(b))
    {
        fres->unimplemented = 0; 
        fres->invalid = 1; 
        fres->overflow = 0;
        fres->underflow = 0;
        fres->z = FPUTestUtil::ConvertIntToFloat(sign | 0x7fbfffff); // signan
    }
    else if (isnan(a) || isnan(b))
    {
        fres->unimplemented = 0; 
        fres->invalid = 0; 
        fres->overflow = 0;
        fres->underflow = 0;
        fres->z = FPUTestUtil::ConvertIntToFloat(sign | 0x7fffffff); // quiet nan
    }
    else if (a_infty && b_infty)
    {
        fres->unimplemented = 0; 
        fres->invalid = 0; 
        fres->overflow = 0;
        fres->underflow = 0;
        fres->z = (sub_mag == 0)
            ? FPUTestUtil::ConvertIntToFloat(sign | 0x7f800000)  // infinite
            : FPUTestUtil::ConvertIntToFloat(sign | 0x7fffffff); // quiet NaN
    }
    else if (a_infty && !b_infty)
    {
        fres->unimplemented = 0; 
        fres->invalid = 0; 
        fres->overflow = 0;
        fres->underflow = 0;
        fres->z = FPUTestUtil::ConvertIntToFloat(sign | 0x7f800000);
    }
    else if (!a_infty && b_infty)
    {
        fres->unimplemented = 0; 
        fres->invalid = 0; 
        fres->overflow = 0;
        fres->underflow = 0;
        fres->z = FPUTestUtil::ConvertIntToFloat(sign | 0x7f800000);
    }
    else if (a_denormal || b_denormal)
    {
        fres->unimplemented = 1; 
        fres->invalid = 0; 
        fres->overflow = 0;
        fres->underflow = 0;
        fres->z = FPUTestUtil::ConvertIntToFloat(sign | 0x7fffffff);
    }
    else
    {
        // clear exception flags. 
        if (feclearexcept(FE_ALL_EXCEPT) != 0)
        {
            cout << "failed to clear floating point exception." << endl;
        }

        float z = (sub_i == 1)
            ? a - b
            : a + b;
        
        int invalid = 0;
        int overflow = 0;
        int underflow = 0;

        // grab exception flags
        FPUTestUtil::CheckError(fegetexceptflag((fexcept_t *) &invalid, FE_INVALID));
        FPUTestUtil::CheckError(fegetexceptflag((fexcept_t *) &overflow, FE_OVERFLOW));
        FPUTestUtil::CheckError(fegetexceptflag((fexcept_t *) &underflow, FE_UNDERFLOW));
       
        if (FPUTestUtil::IsDenormal(z)) 
        {
            fres->unimplemented = 0;
            fres->invalid = 0; 
            fres->overflow = 0;
            fres->underflow = 1;
            fres->z = FPUTestUtil::ConvertIntToFloat(sign | 0);
        }
        else if (underflow != 0)
        {
            fres->unimplemented = 0;
            fres->invalid = 0; 
            fres->overflow = 0;
            fres->underflow = 1;
            fres->z = FPUTestUtil::ConvertIntToFloat(sign | 0);
        }
        else if (overflow != 0)
        {
            fres->unimplemented = 0;
            fres->invalid = 0; 
            fres->overflow = 1;
            fres->underflow = 0;
            fres->z = FPUTestUtil::ConvertIntToFloat(sign | 0x7f800000);
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

void assert(FloatResult *fres)
{
  outputROM << fres->ToString() << endl;
}


uint32_t calculate_sign(float a, float b, int sub_i)
{
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
