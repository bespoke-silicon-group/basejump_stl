#include "TestResult.hpp"
#include "FPUTestUtil.hpp"

template <typename T>
string TestResult<T>::ToString()
{
  string ret = "";

  ret += unimplemented == 0 ? "0" : "1";
  ret += invalid == 0 ? "0" : "1";
  ret += overflow == 0 ? "0" : "1";
  ret += underflow == 0 ? "0" : "1";
  ret +=  "_";
  ret += FPUTestUtil::ConvertToBinaryString(z);

  return ret;
}


template class TestResult<float>;
template class TestResult<double>;
