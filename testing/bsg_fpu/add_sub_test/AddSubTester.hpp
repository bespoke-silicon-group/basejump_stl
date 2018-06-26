#ifndef ADD_SUB_TESTER_HPP
#define ADD_SUB_TESTER_HPP

#include <iostream>
#include <fstream>
#include <type_traits>
#include "TestResult.hpp"
using namespace std;

template <typename T>
class AddSubTester
{
  private:
    ofstream _inputROM;
    ofstream _outputROM;
    bool CalculateSign(T a, T b, bool sub_i);
  
  public:
    AddSubTester();
    ~AddSubTester();
    void Test(T a, T b, bool sub_i);
    void Arrange(T a, T b, bool sub_i);
    void Act(T a, T b, bool sub_i, TestResult<T>* tres);
    void Assert(TestResult<T>* tres);

};

#endif
