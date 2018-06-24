/**
 *  FloatResult.hpp
 *
 *  @author Tommy Jung
 */

#ifndef FLOAT_RESULT_HPP
#define FLOAT_RESULT_HPP

#include <string>
using namespace std;


class FloatResult
{
  public:
    int unimplemented;
    int invalid;
    int overflow;
    int underflow;
    float z;
    string ToString();

  
};

typedef struct {
    int unimplemented,
        invalid,
        overflow,
        underflow;
    float z;
} float_result_t;

string assert(ofstream& ofs, float_result_t *fres);

#endif
