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
};

#endif
