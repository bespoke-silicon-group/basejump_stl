/**
 *  FloatResult.cpp
 *
 *  @author Tommy Jung
 */

#include "FloatResult.hpp"
#include "FPUTestUtil.hpp"

string FloatResult::ToString()
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
