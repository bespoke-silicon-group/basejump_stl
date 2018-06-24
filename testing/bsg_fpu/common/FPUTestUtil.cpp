/**
 *  FPUTestUtil.cpp
 *  
 *  @author Tommy Jung
 */ 

#include <limits>
#include <random>
#include <cstdlib>
#include <cmath>
#include <iostream>
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
  random_device rd;
  mt19937 gen(rd());
  uniform_int_distribution<> dis(numeric_limits<int>::min(), numeric_limits<int>::max());
  int i = dis(gen);
  return flt(i);
}


void FPUTestUtil::CheckError(int i)
{
  if (i != 0)
  {
    cout << "Error Code: " << i << endl;
    exit(i);
  }
}

uint32_t FPUTestUtil::ConvertFloatToInt(float f)
{
  float temp = f;
  return hex(temp);
}

float FPUTestUtil::ConvertIntToFloat(uint32_t i)
{
  uint32_t temp = i;
  return flt(temp);
}

bool FPUTestUtil::IsSigNaN(float f)
{
  int hex_f = hex(f);
  return isnan(f) && ((hex_f & 0x00400000) == 0x00000000);
}

bool FPUTestUtil::IsInfty(float f)
{
  int hex_f = hex(f);
  return ((hex_f & 0x7f800000) == 0x7f800000) && (hex_f & 0x007fffff == 0); 
}

bool FPUTestUtil::IsDenormal(float f)
{
  int hex_f = hex(f);
  return ((hex_f & 0x7f800000) == 0) && ((hex_f & 0x007fffff) != 0);
}
