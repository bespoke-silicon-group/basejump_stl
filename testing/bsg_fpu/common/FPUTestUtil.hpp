/**
 *  FPUTestUtil.hpp
 *  
 *  @author Tommy Jung
 */ 


#ifndef FPU_TEST_UTIL_HPP
#define FPU_TEST_UTIL_HPP

#define flt(X) (*(float*)&X)
#define hex(X) (*(int*)&X)

#include <string>
using namespace std;

class FPUTestUtil
{
  public:
    static string ConvertToBinaryString(int i, int width);
    static string ConvertToBinaryString(float f); 
    static float randf();
    static void CheckError(int i);
    static uint32_t ConvertFloatToInt(float f);
    static float ConvertIntToFloat(uint32_t i); 
    static bool IsSigNaN(float f);
    static bool IsInfty(float f);
    static bool IsDenormal(float f);
};

#endif
