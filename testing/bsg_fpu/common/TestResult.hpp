#ifndef TEST_RESULT_HPP
#define TEST_RESULT_HPP

#include <string>
using namespace std;

template <typename T>
class TestResult
{
  public:
    int unimplemented;
    int invalid;
    int overflow;
    int underflow;
    T z;
    string ToString();
};


#endif
