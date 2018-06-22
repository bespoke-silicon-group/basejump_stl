#pragma STDC FENV_ACCESS_ON

#include <math.h>
#include <iostream>
#include <fstream>
#include "FPUTestUtil.hpp"
using namespace std;

void test(int rm, float f);

ofstream inputROM;
ofstream outputROM;

int main()
{
  inputROM.open("f2i_32_input.rom");
  outputROM.open("f2i_32_output.rom");

  test(1, 0);
  test(1, 1.49);
  test(1, 1.5);
  test(1, 2.49);
  test(1, -1.49);
  test(1, -2.49);
  test(1, -12.49);
  test(1, 2423.49);
  test(1, -2.49);
  test(1, 9234.5003);
  test(1, 0.5);
  test(1, -0.5);
  test(1, 0.005);
  test(1, -0.005);

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
    case 0: output = (int) roundf(f / 2) * 2; break;
    case 1: output = (int) truncf(f); break;
    case 2: output = (int) floorf(f); break;
    case 3: output = (int) ceilf(f); break;
    case 4: output = (int) roundf(f); break;
  }

  outputROM << FPUTestUtil::ConvertToBinaryString(output, 32) << endl;
}
