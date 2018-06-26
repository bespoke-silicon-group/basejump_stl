/**
 *  FPUTestUtil.hpp
 *  
 *  @author Tommy Jung
 */ 


#ifndef FPU_TEST_UTIL_HPP
#define FPU_TEST_UTIL_HPP

#define flt(X) (*(float*)&X)
#define hex(X) (*(int*)&X)
#define hex64(X) (*(uint64_t*)&X)
#define dbl(X) (*(double*)&X)

#include <string>
using namespace std;

class FPUTestUtil
{
  public:
    static string ConvertToBinaryString(int i, int width);
    static string ConvertToBinaryString(float f); 
    static string ConvertToBinaryString(double d); 
    static float randf();
    static double randd();
    static void CheckError(int i);
    static uint32_t ConvertFloatToInt(float f);
    static uint64_t ConvertDoubleToInt(double d);
    static float ConvertIntToFloat(uint32_t i); 
    static double ConvertIntToDouble(uint64_t i); 
    static bool IsNaN(float f);
    static bool IsSigNaN(float f);
    static bool IsInfty(float f);
    static bool IsDenormal(float f);
    static bool IsNaN(double d);
    static bool IsSigNaN(double d);
    static bool IsInfty(double d);
    static bool IsDenormal(double d);
};

#endif
