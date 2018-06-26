/**
 *  app.cpp
 *
 *  @author Tommy Jung
 */

#pragma STDC FENV_ACCESS ON

#include <string>
#include <iostream>
#include "AddSubTester.hpp"
#include "FPUTestUtil.hpp"
using namespace std;

#define NUM_TEST 10000

int main(int argc, char** argv)
{
  int bit_width;
  if (argc == 1)
  {
    cout << "running 32-bit test..." << endl;   
    bit_width = 32;
  }
  else if (argc == 2)
  {
    if (string(argv[1]) == "32" || string(argv[1]) == "64")
    {
      bit_width = stoi(argv[1]);
      cout << "running " << bit_width << "-bit test..." << endl;
    }
    else
    {
      cout << "unexpected command-line argument." << endl;
      return -1;
    }
  }
  else
  {
    cout << "unexpected number of command-line arguments." << endl;
    return -1;
  }

  srand(time(0)); // set random seed;

  if (bit_width == 32)
  {
    auto tester32 = new AddSubTester<float>();
    for (int i = 0; i < NUM_TEST; i++) 
    {
      float a = FPUTestUtil::randf();
      float b = FPUTestUtil::randf();
      bool sub_i = (bool) (rand() % 2);
      tester32->Test(a, b, sub_i);
    }

    delete tester32;
  }
  else if (bit_width == 64)
  {
    auto tester64 = new AddSubTester<double>();
    for (int i = 0; i < NUM_TEST; i++) 
    {
      double a = FPUTestUtil::randd();
      double b = FPUTestUtil::randd();
      bool sub_i = (bool) (rand() % 2);
      tester64->Test(a, b, sub_i);
    }
    delete tester64;
  } 

  return 0;
}
