#include <cstdlib>
#include "FPUTestUtil.hpp"
using namespace std;

string FPUTestUtil::ConvertToBinaryString(int i, int width)
{
  string ret = "";

  for (int j = 0; j < width; j++)
  {
    int shamt = width - 1 - j;
    int bit = (i & (1 << shamt)) >> shamt;
    ret += (bit == 0) ? "0" : "1";
  }

  return ret;
}

string FPUTestUtil::ConvertToBinaryString(float f)
{
  string ret = "";
  int h = hex(f);

  for (int i = 0; i < 32; i++)
  {
    int shamt = 32 - 1 - i;
    int bit = (h & (1 << shamt)) >> shamt;
    ret += (bit == 0) ? "0" : "1";
  }
  
  return ret;
}


float FPUTestUtil::randf()
{
  int i = rand();
  return flt(i);
}
