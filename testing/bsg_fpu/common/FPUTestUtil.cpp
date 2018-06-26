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

string FPUTestUtil::ConvertToBinaryString(double d)
{
  string ret = "";
  uint64_t h = hex64(d);
  
  for (int i = 0; i < 64; i++)
  {
    int shamt = 64 - 1 - i;
    uint64_t bit = (uint64_t) (h & ((uint64_t) 1 << shamt)) >> shamt;
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

double FPUTestUtil::randd()
{
  random_device rd;
  mt19937 gen(rd());
  uniform_int_distribution<uint64_t> dis(
    numeric_limits<uint64_t>::min(),
    numeric_limits<uint64_t>::max());
  uint64_t i = dis(gen);
  return dbl(i);
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


uint64_t FPUTestUtil::ConvertDoubleToInt(double d)
{
  double temp = d;
  return hex64(temp);
}

float FPUTestUtil::ConvertIntToFloat(uint32_t i)
{
  uint32_t temp = i;
  return flt(temp);
}

double FPUTestUtil::ConvertIntToDouble(uint64_t i)
{
  uint64_t temp = i;
  return dbl(temp);
}

bool FPUTestUtil::IsNaN(float f)
{
  return isnan(f); 
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

bool FPUTestUtil::IsNaN(double d)
{
  return d != d; 
}

bool FPUTestUtil::IsSigNaN(double d)
{
  uint64_t hex_d = hex64(d);
  return (d != d) && ((hex_d & 0x0008000000000000) == 0);
}

bool FPUTestUtil::IsInfty(double d)
{
  uint64_t hex_d = hex64(d);
  return ((hex_d & 0x7ff0000000000000) == 0x7ff0000000000000) && (hex_d & 0x000fffffffffffff == 0); 
}

bool FPUTestUtil::IsDenormal(double d)
{
  uint64_t hex_d = hex64(d);
  return ((hex_d & 0x7ff0000000000000) == 0) && ((hex_d & 0x000fffffffffffff) != 0);
}

