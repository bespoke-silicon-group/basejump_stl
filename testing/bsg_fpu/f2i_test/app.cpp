#pragma STDC FENV_ACCESS_ON

#include <cstdlib>
#include <math.h>
#include <cfenv>
#include <iostream>
#include <fstream>
#include "FPUTestUtil.hpp"
using namespace std;

void test(int rm, float f);

ofstream inputROM;
ofstream outputROM;

int main()
{
  srand(time(0));

  inputROM.open("f2i_32_input.rom");
  outputROM.open("f2i_32_output.rom");

  for (int i = 0; i < 998; i++)
  {
    test(0, FPUTestUtil::randf());
  }

  int n = 0xbe000000;
  test(2, flt(n));
  n = 0x3e000000;
  test(3, flt(n));

  inputROM.close();
  outputROM.close();
  return 0;
}

void test(int rm, float f)
{
  inputROM << FPUTestUtil::ConvertToBinaryString(rm, 3)
    << "_"
    << FPUTestUtil::ConvertToBinaryString(f)
    << endl;

  int output;
  switch (rm) 
  {
    case 0:
      fesetround(FE_TONEAREST);
      output = (int) nearbyint(f);
      break;
    case 1:
      output = (int) truncf(f);
      break;
    case 2:
      output = (int) floorf(f);
      break;
    case 3:
      output = (int) ceilf(f);
      break;
    case 4:
      output = (int) roundf(f);
      break;
  }

  outputROM << FPUTestUtil::ConvertToBinaryString(output, 32) << endl;
}
